import asyncio
import discord
import dataset
import datetime
import random

from os import environ
from src.apis import requester
from stuf import stuf
from time import mktime, strptime
from typing import Optional
from ..util import create_logger
from run import Bot

logger = create_logger('api')
db = dataset.connect('sqlite:///data/api.db', row_type=stuf)

# After which amount of time a Twitch User should be updated, in hours
USER_UPDATE_INTERVAL = 12
USER_UPDATE_DELTA = datetime.timedelta(hours=USER_UPDATE_INTERVAL)

# After which amount of time a Twitch Stream should be updated in Cache, in minutes
STREAM_UPDATE_INTERVAL = 2
STREAM_UPDATE_DELTA = datetime.timedelta(minutes=STREAM_UPDATE_INTERVAL)

# The amount of time that the Twitch Stream updater should wait between requesting, in seconds
# Keep in mind that this also pulls data from Cache.
BACKGROUND_UPDATE_INTERVAL = 2


def parse_twitch_time(twitch_time: str, truncate=True):
    # Converts a Twitch API Time to a datetime.datetime object
    time_format = '%Y-%m-%dT%H:%M:%S'
    if truncate:
        return datetime.datetime.fromtimestamp(mktime(strptime(twitch_time[:twitch_time.find('.')], time_format)))
    return datetime.datetime.fromtimestamp(mktime(strptime(twitch_time, time_format)))


def twitch_api_stats():
    # Returns a tuple of the user update interval, the stream update interval, and the sleep time between stream
    # requests for the background updater.
    return USER_UPDATE_INTERVAL, STREAM_UPDATE_INTERVAL, BACKGROUND_UPDATE_INTERVAL


class FollowConfig:
    # Handles reading and writing the configuration file for stream follows and abstracts away initialization of entries
    def __init__(self):
        self._follow_table = db['follows']  # Contains information about the channels that guilds are following
        self._channel_table = db['channels']  # Contains the Channel IDs that guilds use for the announcements

    def get_guild_follows(self, guild_id: int) -> [str]:
        return [r.stream_name for r in self._follow_table.find(guild_id=guild_id, order_by=['guild_id', 'stream_name'])]

    def get_global_follows(self):
        return self._follow_table.distinct('stream_name')

    def get_guild_ids_following(self, stream_name):
        # Get all Guild ID's following the given Stream name
        return [x.guild_id for x in self._follow_table.find(stream_name=stream_name)]

    def get_guild_names_following(self, stream_name):
        # Get all Guild Names following the given Stream name
        return [x.guild_name for x in self._follow_table.find(stream_name=stream_name)]

    def follow(self, guild_id: int, guild_name: str, stream_name: str):
        self._follow_table.insert(dict(guild_id=guild_id, guild_name=guild_name, stream_name=stream_name))

    def un_follow(self, guild_id: int, stream_name: str):
        self._follow_table.delete(guild_id=guild_id, stream_name=stream_name)

    def set_channel(self, guild_id: int, guild_name: str, channel_id: int):
        # Update or Insert, view https://dataset.readthedocs.io/en/latest/api.html#dataset.Table.upsert for reference
        logger.info(f'[STREAMS] Guild `{guild_name}` set its channel to {channel_id}.')
        self._channel_table.upsert(dict(guild_id=guild_id, guild_name=guild_name, channel_id=channel_id), ['guild_id'])

    def unset_channel(self, guild_id: int, guild_name: str):
        logger.info(f'[STREAMS] Guild `{guild_name}` unset its channel.')
        self._channel_table.delete(guild_id=guild_id)

    def get_channel_id(self, guild_id: int):
        return self._channel_table.find_one(guild_id=guild_id)


follow_config = FollowConfig()


class TwitchAPI:
    # Handles requests to the Twitch API
    def __init__(self, bot: Bot):
        self._API_KEY = environ['TWITCH_TOKEN']
        self._BASE_URL = 'https://api.twitch.tv/kraken'
        self._stream_cache = {}
        self._bot = bot
        self._headers = [('Accept', 'application/vnd.twitchtv.v5+json')]
        self._table = db['twitch_users']  # contains Twitch User Data
        self.total_follows = sum(1 for _ in follow_config.get_global_follows())

    async def _query(self, url) -> dict:
        # Queries the given URL and returns it's JSON response, also appends the TWITCH_TOKEN environment variable.
        logger.debug(f'Querying `{url}`...')
        if '?' not in url:
            return await requester.get(f'{url}?client_id={self._API_KEY}', self._headers)
        return await requester.get(f'{url}&client_id={self._API_KEY}', self._headers)

    async def _request_user_from_api(self, name: str):
        # Calls the get Users endpoint to convert a user name to an ID and add it to the Database for requests, later
        logger.debug(f'Calling `Get User` endpoint for {name}...')
        resp = await self._query(f'{self._BASE_URL}/users?login={name}')
        if resp is None or resp['_total'] == 0:
            raise requester.NotFoundError()
        return resp['users'][0]

    async def _request_stream_from_api(self, stream_name: str):
        # Get a Stream from the API
        user = await self.get_user(stream_name)
        if user is None:
            self._stream_cache[stream_name] = {
                'name': stream_name,
                'status': None
            }
            return self._stream_cache[stream_name]

        user_id = user['uid']
        query_result = await self._query(f'{self._BASE_URL}/streams/{user_id}')

        if query_result is None:
            logger.error(f'Unknown Error occurred trying to query Stream for ID {user_id}, retrying...')
            return await self.get_stream(stream_name)

        self._stream_cache[stream_name] = query_result['stream']

        if self._stream_cache[stream_name] is None:
            self._stream_cache[stream_name] = {
                'name': stream_name,
                'status': False
            }
        else:
            # Result is already a dictionary
            self._stream_cache[stream_name]['name'] = stream_name
            self._stream_cache[stream_name]['status'] = True

        return self._stream_cache[stream_name]

    def _update_user_on_db(self, user: dict):
        # Takes a JSON response of a User and updates the Database accordingly
        # returned from `GET https://api.twitch.tv/kraken/users/<user ID>`
        self._table.upsert(dict(
            name=user['name'],
            logo=user['logo'],
            bio=user['bio'],
            uid=user['_id'],
            display_name=user['display_name'],
            created_at=parse_twitch_time(user['created_at']),
            updated_at=parse_twitch_time(user['updated_at']),
            user_type=user['type'],
            last_db_update=datetime.datetime.utcnow()), ['name']
        )
        logger.info(f'Updated {user["name"]} on the User Database.')

    async def get_user(self, name: str) -> Optional[dict]:
        # Requests a Twitch User by his name. If he's not present in the Database, he is added and returned.
        # If he is present, but the last user update surpassed the set interval, he is updated and returned.
        # Otherwise, if the checks above return `False`, the user is just returned.
        # If the User is not found at all, `None` is returned.

        user = self._table.find_one(name=name)

        try:
            if user is None or datetime.datetime.utcnow() - user.last_db_update > USER_UPDATE_DELTA:
                self._update_user_on_db(await self._request_user_from_api(name))
                return self._table.find_one(name=name)
            return user
        except requester.NotFoundError:
            return None

    async def get_stream(self, stream_name: str) -> Optional[dict]:
        # Requests a Stream from the API. First, it tries to obtain a User object to translate from a Stream Name
        # an ID. It then performs the request to the Twitch API. The User Object in the database is also updated
        # during this process to contain information about followers, language, views, and the status of the User.
        logger.debug(f'Getting Stream for {stream_name}...')
        # Updates the given Stream name in Cache.
        # If the Stream was not present before, it will be added.
        needs_update = stream_name not in self._stream_cache or \
                       datetime.datetime.utcnow() - self._stream_cache[stream_name]['last_update'] > STREAM_UPDATE_DELTA

        if needs_update:
            await self._request_stream_from_api(stream_name)
            self._stream_cache[stream_name]['last_update'] = datetime.datetime.utcnow()
            logger.debug(f'Updated or added Stream `{stream_name}` in the Cache.')

        return self._stream_cache[stream_name]

    async def get_status(self, stream_name: str) -> str:
        # Get a string indicating the Status of the Stream.
        # The Stream must exist for this function to work.
        # For example, this could return "offline" or "Playing <game>"
        stream = await self.get_stream(stream_name)
        if stream['status'] is False:
            return 'Offline'
        return f'Playing {stream["game"]}'

    async def user_exists(self, name: str) -> bool:
        # Returns a boolean indicating whether the given User exists or not.
        return await self.get_user(name) is not None

    async def _send_stream_update_announcement(self, stream: dict, guilds_following: list):
        # Sends an announcement about a Stream updating its state to all following Guilds.
        for guild_id in guilds_following:
            channel_row = follow_config.get_channel_id(guild_id)
            if channel_row is None:
                logger.warn(f'Guild with ID {guild_id} is following {stream["name"]}, but has no channel set!')
                break

            stream_channel = self._bot.get_channel(int(channel_row.channel_id))
            announcement = discord.Embed(
                colour=0x6441A5
            )

            if stream["status"]:
                title = f'{stream["name"]} is now online!'
                link = f'{stream["channel"]["url"]}'

                if stream['channel']['logo'] is not None:
                    announcement.set_author(
                        name=title,
                        url=link,
                        icon_url=stream['channel']['logo']
                    )
                else:
                    announcement.set_author(
                        name=title,
                        url=link
                    )

                game = stream["game"] if stream["game"] is not '' else '?'

                announcement.set_thumbnail(
                    url=stream['preview']['medium']
                ).set_footer(
                    text=f'Followers: {stream["channel"]["followers"]:,}',
                ).description = f'[Now playing **{game}**!]({link})\n*{stream["channel"]["status"].strip()}*'

            else:
                announcement.title = f'{stream["name"]} is now offline.'
            try:
                await stream_channel.send(embed=announcement)
            except discord.errors.Forbidden as e:
                admins = [m for m in stream_channel.guild.members if m.top_role.permissions.manage_channels]
                random_admin = random.choice(admins)
                while True:
                    try:
                        await random_admin.send(embed=discord.Embed(
                            title='Error with sending Stream update',
                            description=(f'I tried to update about the Stream `{stream["name"]}` in '
                                         f'{stream_channel.mention}, but I do not have the permissions necessary '
                                         f'to send a Message there. Please make sure that I have the proper '
                                         f'permissions to send my announcements there, otherwise I might remove the '
                                         f'Streams set on your Guild from my polling list.'),
                            colour=discord.Colour.blue()
                        ).add_field(
                            name='Original Error:',
                            value=str(e)
                        ).set_image(url=self._bot.user.avatar_url))

                        await self._bot.stream_warn_channel.send(embed=discord.Embed(
                            title='Stream Delivery Warning',
                            colour=discord.Colour.gold(),
                            timestamp=datetime.datetime.now()
                        ).add_field(
                            name='Guild',
                            value=f'**Name**: `{stream_channel.guild.name}`\n**ID**: `{stream_channel.guild.id}`'
                        ).add_field(
                            name='Owner',
                            value=f'**User**: `{stream_channel.guild.owner}`\n**ID**: `{stream_channel.guild.owner_id}`'
                        ).add_field(
                            name='Notice sent to:',
                            value=f'**User**: `{random_admin}`\n**ID**: `{random_admin.id}`'
                        ).add_field(
                            name='Members with Manage Channels permission:',
                            value=', '.join(str(a) for a in admins)
                        ).set_footer(
                            icon_url=stream_channel.guild.icon_url
                        ))

                    except discord.errors.Forbidden:
                        if sum(1 for _ in admins) == 1:
                            break
                        random_admin = random.choice(admins)
                    else:
                        break

    async def update_streams(self):
        # Starts the process of updating Guilds about Streams they follow.
        old_streams = []
        await self._bot.wait_until_ready()
        print('Started Twitch Stream Background Updater:')
        logger.info('Started Twitch Stream Background Updater.')
        print(f'Following a total of {self.total_follows} Streams.')
        while not self._bot.is_closed():
            # Reset stream list
            new_streams = []
            self.total_follows = sum(1 for _ in follow_config.get_global_follows())

            # Check stream states
            # - Why the list conversion? (no longer needed, leaving it here for future reference)
            #   Without the conversion, when a User follows a new Stream during the loop, a RuntimeError is raised,
            #   since the dictionary size changed during the iteration. To prevent this, the dictionary
            #   is casted to a list to prevent iterating over a reference to the global follows.
            for stream in follow_config.get_global_follows():
                new_streams.append(await self.get_stream(stream.stream_name))
                await asyncio.sleep(BACKGROUND_UPDATE_INTERVAL)

            # Check if we ran through at least one iteration # and both lists have the same amount of Streams
            if old_streams:
                # Compare streams with each other
                for double_streams in zip(old_streams, new_streams):
                    # Check if the lists did not get mixed up. This happens if new_streams contains
                    # new data which the first one does not, for example after a new global stream has been followed
                    # However, a part of the list will be processable. After the first difference between Stream names
                    # occurs, we break out of the loop to ensure that we're not updating about the wrong Stream.
                    if double_streams[0]['name'] != double_streams[1]['name']:
                        break
                    elif double_streams[0]['status'] != double_streams[1]['status']:
                        following_guilds = follow_config.get_guild_ids_following(double_streams[0]['name'])
                        await self._send_stream_update_announcement(double_streams[1], following_guilds)

            elif self.total_follows != 0:
                print('Done loading initial Stream states.')
            else:
                print('Not following any Streams. Sleeping for 15 minutes...')
                await asyncio.sleep(900)

            old_streams = new_streams
        print('Stopped Twitch Stream Background Updater.')
        logger.info('Stopped Twitch Stream Background Updater.')

