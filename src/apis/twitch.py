from typing import Union, Optional, Any

import aiohttp
import dataset
import datetime
import json

from os import environ
from src.apis import requester
from stuf import stuf
from time import mktime, strptime
from ..util import create_logger


logger = create_logger('api')
db = dataset.connect('sqlite:///data/api.db', row_type=stuf)
table = db['twitch_users']

# After which amount of time a Twitch User should be updated, in hours
USER_UPDATE_INTERVAL = 12


def parse_twitch_time(twitch_time: str):
    # Converts a Twitch API Time to a datetime.datetime object
    return datetime.datetime.fromtimestamp(mktime(strptime(twitch_time[:-8], '%Y-%m-%dT%H:%M:%S')))


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
            self._config['global_follows'][stream_name].append(guild_id)

    def un_follow(self, guild_id: int, stream_name: str):
        guild_id = str(guild_id)
        self._config['guild_follows'][guild_id]['follows'].remove(stream_name)
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
    def __init__(self):
        self._api_key = environ['TWITCH_TOKEN']
        self._BASE_URL = 'https://api.twitch.tv/kraken'

    @staticmethod
    async def _query(url) -> dict:
        # Queries the given URL and returns it's JSON response, also appends the TWITCH_TOKEN environment variable.
        logger.debug(f'Querying `{url}`...')
        if '?' not in url:
            return await requester.get(f'{url}?client_id={environ["TWITCH_TOKEN"]}')
        return await requester.get(f'{url}&client_id={environ["TWITCH_TOKEN"]}')

    async def _request_user_from_api(self, name: str):
        # Calls the get Users endpoint to convert a user name to an ID and add it to the Database for requests, later
        logger.debug(f'Calling `Get User` endpoint for {name}...')
        return (await self._query(f'{self._BASE_URL}/users?login={name}'))['users'][0]

    @staticmethod
    def _add_user_to_db(user: dict):
        # Takes a JSON response of a User from the API and inserts it into the Database,
        # returned from `GET https://api.twitch.tv/kraken/users/<user ID>`
        followers = user.get('followers', -1)
        views = user.get('views', -1)
        language = user.get('language', '')
        status = user.get('status', '')

        table.insert(dict(name=user['name'], logo=user['logo'], bio=user['bio'], uid=user['_id'],
                          display_name=user['display_name'], created_at=parse_twitch_time(user['created_at']),
                          updated_at=parse_twitch_time(user['updated_at']), user_type=user['type'], followers=followers,
                          views=views, language=language, status=status, last_db_update=datetime.datetime.utcnow()))
        logger.info(f'Added {user["name"]} to the User Database.')

    @staticmethod
    def _update_user_on_db(user: dict):
        # Takes a JSON response of a User and updates the Database accordingly
        # returned from `GET https://api.twitch.tv/kraken/users/<user ID>`
        followers = user.get('followers', -1)
        views = user.get('views', -1)
        language = user.get('language', '')
        status = user.get('status', '')

        table.update(dict(name=user['name'], logo=user['logo'], bio=user['bio'], uid=user['_id'],
                          display_name=user['display_name'], created_at=parse_twitch_time(user['created_at']),
                          updated_at=parse_twitch_time(user['updated_at']), user_type=user['type'], followers=followers,
                          views=views, language=language, status=status,
                          last_db_update=datetime.datetime.utcnow()), ['name'])
        logger.info(f'Updated {user["name"]} on the User Database.')

    async def get_user(self, name: str) -> Union[Optional[dict], Any]:
        # Requests a Twitch User by his name. If he's not present in the Database, he is added and returned.
        # If he is present, but the last user update surpassed the set interval, he is updated and returned.
        # Otherwise, if the checks above return `False`, the user is just returned.
        # If the User is not found at all, `None` is returned.
        def parse_times(raw_user):
            # Helper function to parse the created_at and updated_at attributes of a User
            raw_user['created_at'] = parse_twitch_time(raw_user['created_at'])
            raw_user['updated_at'] = parse_twitch_time(raw_user['updated_at'])
            return raw_user

        user = table.find_one(name=name)

        try:
            # Check if the user exists in the Database, if not request it and add it to the DB
            if user is None:
                user = await self._request_user_from_api(name)
                self._add_user_to_db(user)
                parse_times(user)

            # Check if User needs to be updated
            elif datetime.datetime.utcnow() - user.last_db_update > datetime.timedelta(hours=USER_UPDATE_INTERVAL):
                user = await self._request_user_from_api(name)
                self._update_user_on_db(user)
                parse_times(user)

        except requester.NotFoundError:
            return None
        else:
            return user
