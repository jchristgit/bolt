import aiohttp
from os import environ


class TwitchUser:
    # Parses responses from get_user calls
    def __init__(self, data):
        self.id = data['_id']
        self.bio = data['bio']
        self.creation_date = data['created_at']
        self.display_name = data['display_name']
        self.logo_url = data['logo']
        self.updated_at = data['updated_at']


class Stream:
    # Parses responses from get_stream calls
    def __init__(self, data):
        if data['stream'] is None:
            self.online = False
        else:
            self.online = True
            data = data['stream']
            self.id = data['_id']
            self.game = data['game']
            self.viewers = data['viewers']
            self.creation_date = data['created_at']
            self.preview = data['preview']['medium']
            self.display_name = data['channel']['display_name']
            self.language = data['channel']['broadcaster_language']
            self.partnered = data['channel']['partner']
            self.channel_status = data['channel']['status']
            self.channel_is_mature = data['channel']['mature']
            self.channel_logo = data['channel']['logo']
            self.url = data['channel']['url']
            self.views = data['channel']['views']
            self.followers = data['channel']['followers']


class TwitchAPI:
    # Handles requests to the Twitch API
    def __init__(self):
        self._api_key = environ['TWITCH_TOKEN']
        self._BASE_URL_STREAMS = 'https://api.twitch.tv/kraken/streams/'

    async def get_stream(self, stream_name):
        async with aiohttp.ClientSession() as cs:
            async with cs.get(f'{self._BASE_URL_STREAMS}{stream_name}?client_id={self._api_key}') as r:
                return Stream(await r.json())
