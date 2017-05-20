
import asyncio
import discord
import dataset
import datetime
import json

from os import environ
from src.apis import requester
from stuf import stuf
from time import mktime, strptime
from typing import Union, Optional, Any
from ..util import create_logger

logger = create_logger('api')
db = dataset.connect('sqlite:///data/api.db', row_type=stuf)
table = db['twitch_users']

# After which amount of time a Twitch User should be updated, in hours
USER_UPDATE_INTERVAL = 12

# After which amount of time a Twitch Stream should be updated in Cache, in minutes
STREAM_UPDATE_INTERVAL = 2

# The amount of time that the Twitch Stream updater should wait between requesting, in seconds
# Keep in mind that this also pulls data from Cache.
BACKGROUND_UPDATE_INTERVAL = 2


def parse_twitch_time(twitch_time: str, truncate=True):
    # Converts a Twitch API Time to a datetime.datetime object
    if truncate:
        return datetime.datetime.fromtimestamp(mktime(strptime(twitch_time[:-8], '%Y-%m-%dT%H:%M:%S')))
    return datetime.datetime.fromtimestamp(mktime(strptime(twitch_time, '%Y-%m-%dT%H:%M:%S')))


class FollowConfig:
    # Handles reading and writing the configuration file for stream follows and abstracts away initialization of entries
    def __init__(self):
        with open('config/streams.json') as f:
            self._config = json.load(f)

    def save(self):
        with open('config/streams.json', 'w') as f:
            json.dump(self._config, f, indent=4, sort_keys=True)

    def get_guild_follows(self, guild_id: int) -> [str]:
        guild_id = str(guild_id)
        if guild_id not in self._config['guild_follows']:
            return []
        return self._config['guild_follows'][guild_id]['follows']

    def get_global_follows(self) -> dict:
        return self._config['global_follows']

    def follow(self, guild_id: str, guild_name: str, stream_name: str):
        guild_id = str(guild_id)
        logger.info(f'Guild `{guild_name}` is now following `{stream_name}`.')
        if guild_id not in self._config['guild_follows']:
            # Store this channel in the guild's follows
            self._config['guild_follows'][guild_id] = {
                'channel': '',
                'follows': [
                    stream_name
                ],
                'name': guild_name
            }
            logger.debug(f'Created new entry for `{guild_name}`({guild_id}).')
        else:
            self._config['guild_follows'][guild_id]['follows'].append(stream_name)
        if stream_name not in self._config['global_follows']:
            # Store this guild for the followers for the Channel
            self._config['global_follows'][stream_name] = [
                int(guild_id)
            ]
        else:
            self._config['global_follows'][stream_name].append(int(guild_id))

    def un_follow(self, guild_id: int, stream_name: str):
        self._config['guild_follows'][str(guild_id)]['follows'].remove(stream_name)
        self._config['global_follows'][stream_name].remove(guild_id)
        if not self._config['global_follows'][stream_name]:  # no more guilds following
            del self._config['global_follows'][stream_name]

    def set_channel(self, guild_id: int, guild_name: str, channel_id: int):
        guild_id, channel_id = str(guild_id), str(channel_id)
        logger.info(f'[STREAMS] Guild `{guild_name}` set channel to `{channel_id}`.')
        if guild_id not in self._config['guild_follows']:
            self._config['guild_follows'][guild_id] = {
                'channel': channel_id,
                'follows': [],
                'name': guild_name
            }
        else:
            self._config['guild_follows'][guild_id]['channel'] = channel_id

    def unset_channel(self, guild_id: int, guild_name: str):
        logger.info(f'[STREAMS] Guild `{guild_name}` unset its channel.')
        self._config['guild_follows'][str(guild_id)]['channel'] = ''

    def get_channel_id(self, guild_id: int):
        guild_id = str(guild_id)
        if guild_id not in self._config['guild_follows']:
            return ''
        else:
            return self._config['guild_follows'][guild_id]['channel']


follow_config = FollowConfig()


class TwitchAPI:
    # Handles requests to the Twitch API
    def __init__(self, bot: discord.AutoShardedClient):
        self._API_KEY = environ['TWITCH_TOKEN']
        self._BASE_URL = 'https://api.twitch.tv/kraken'
        self._stream_cache = {}
        self._bot = bot

    async def _query(self, url) -> dict:
        # Queries the given URL and returns it's JSON response, also appends the TWITCH_TOKEN environment variable.
        logger.debug(f'Querying `{url}`...')
        if '?' not in url:
            return await requester.get(f'{url}?client_id={self._API_KEY}')
        return await requester.get(f'{url}&client_id={self._API_KEY}')

    async def _request_user_from_api(self, name: str):
        # Calls the get Users endpoint to convert a user name to an ID and add it to the Database for requests, later
        logger.debug(f'Calling `Get User` endpoint for {name}...')
        resp = await self._query(f'{self._BASE_URL}/users?login={name}')
        if resp['_total'] == 0:
            raise requester.NotFoundError()
        return resp['users'][0]

    @staticmethod
    def _add_user_to_db(user: dict):
        # Takes a JSON response of a User from the API and inserts it into the Database,
        # returned from `GET https://api.twitch.tv/kraken/users/<user ID>` None)
        table.insert(dict(name=user['name'], logo=user['logo'], bio=user['bio'], uid=user['_id'],
                          display_name=user['display_name'], created_at=parse_twitch_time(user['created_at']),
                          updated_at=parse_twitch_time(user['updated_at']), user_type=user['type'],
                          last_db_update=datetime.datetime.utcnow()))
        logger.info(f'Added {user["name"]} to the User Database.')

    @staticmethod
    def _update_user_on_db(user: dict):
        # Takes a JSON response of a User and updates the Database accordingly
        # returned from `GET https://api.twitch.tv/kraken/users/<user ID>`
        table.update(dict(name=user['name'], logo=user['logo'], bio=user['bio'], uid=user['_id'],
                          display_name=user['display_name'], created_at=parse_twitch_time(user['created_at']),
                          updated_at=parse_twitch_time(user['updated_at']), user_type=user['type'],
                          last_db_update=datetime.datetime.utcnow()), ['name'])
        logger.info(f'Updated {user["name"]} on the User Database.')

    async def get_user(self, name: str) -> Optional[dict]:
        # Requests a Twitch User by his name. If he's not present in the Database, he is added and returned.
        # If he is present, but the last user update surpassed the set interval, he is updated and returned.
        # Otherwise, if the checks above return `False`, the user is just returned.
        # If the User is not found at all, `None` is returned.

        user = table.find_one(name=name)

        try:
            # Check if the user exists in the Database, if not request it and add it to the DB
            if user is None:
                self._add_user_to_db(await self._request_user_from_api(name))
                user = table.find_one(name=name)

            # Check if User needs to be updated
            elif datetime.datetime.utcnow() - user.last_db_update > datetime.timedelta(hours=USER_UPDATE_INTERVAL):
                self._update_user_on_db(await self._request_user_from_api(name))
                user = table.find_one(name=name)

        except requester.NotFoundError:
            return None
        else:
            return user

    async def get_stream(self, stream_name: str) -> Optional[dict]:
        # Requests a Stream from the API. First, it tries to obtain a User object to translate from a Stream Name
        # an ID. It then performs the request to the Twitch API. The User Object in the database is also updated
        # during this process to contain information about followers, language, views, and the status of the User.
        logger.debug(f'Getting Stream for {stream_name}...')
        # Updates the given Stream name in Cache.
        # If the Stream was not present before, it will be added.

        if stream_name not in self._stream_cache or \
                datetime.datetime.utcnow() - self._stream_cache[stream_name]['last_update'] \
                > datetime.timedelta(minutes=STREAM_UPDATE_INTERVAL):
            user_id = (await self.get_user(stream_name))['uid']
            self._stream_cache[stream_name] = (await self._query(f'{self._BASE_URL}/streams/{user_id}'))['stream']
            if self._stream_cache[stream_name] is None:
                self._stream_cache[stream_name] = {
                    'name': stream_name,
                    'status': None
                }
            else:
                self._stream_cache[stream_name]['name'] = stream_name
                self._stream_cache[stream_name]['status'] = True

            self._stream_cache[stream_name]['last_update'] = datetime.datetime.utcnow()
            logger.info(f'Updated or added Stream `{stream_name}` in the Cache.')

        return self._stream_cache[stream_name]

    async def user_exists(self, name: str) -> bool:
        # Returns a boolean indicating whether the given User exists or not.
        return await self.get_user(name) is not None

    async def _send_stream_update_announcement(self, stream: dict, guilds_following: list):
        # Sends an announcement about a Stream updating its state to all following Guilds.
        for guild_id in guilds_following:
            channel_id = follow_config.get_channel_id(guild_id)
            if channel_id == '':
                return
            stream_channel = self._bot.get_channel(int(channel_id))
            announcement = discord.Embed()
            announcement.colour = 0x6441A5
            if stream["status"]:
                title = f'{stream["name"]} is now online!'
                link = f'https://twitch.tv/{stream["channel"]["url"]}'
                if stream['channel']['logo'] is not None:
                    announcement.set_author(name=title, url=link, icon_url=stream['channel']['logo'])
                else:
                    announcement.set_author(name=title, url=link)
                announcement.description = f'Playing **{stream["game"]}** for currently **{stream["viewers"]}** ' \
                                           f'viewers!\n *{stream["channel"]["status"]}*'
                announcement.set_thumbnail(url=stream['preview']['medium'])
                announcement.set_footer(text=f'Run `!stream get {stream["name"]}` for detailed information!')
            else:
                announcement.title = f'{stream["name"]} is now offline.'
            await stream_channel.send(embed=announcement)

    async def update_streams(self):
        # Starts the process of updating Guilds about Streams they follow.
        old_streams = []
        await self._bot.wait_until_ready()

        while not self._bot.is_closed():
            # Reset stream list
            new_streams = []

            # Check stream states
            # Why the list conversion?
            #   Without the conversion, when a User follows a new Stream, a RuntimeError is raised,
            #   since the dictionary size changed during the iteration. To prevent this, the dictionary
            #   is casted to a list to prevent iterating over a reference to the global follows.
            for stream in list(follow_config.get_global_follows()):
                print(f'Getting Stream {stream}...')
                new_streams.append(await self.get_stream(stream))
                await asyncio.sleep(BACKGROUND_UPDATE_INTERVAL)

            # Check if we ran through at least one iteration and both lists have the same amount of Streams
            if old_streams and len(old_streams) == len(new_streams):
                # Compare streams with each other
                for double_streams in zip(old_streams, new_streams):
                    print(double_streams[0]['name'], double_streams[0]['status'],
                          double_streams[1]['name'], double_streams[1]['status'])
                    if double_streams[0]['status'] != double_streams[1]['status']:
                        following_guilds = follow_config.get_global_follows()[double_streams[1]['name']]
                        await self._send_stream_update_announcement(double_streams[1], following_guilds)

            old_streams = new_streams
