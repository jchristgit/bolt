import asyncio
import collections
import functools
from typing import Optional, Union

import aiohttp


BASE_API_URL = ".api.riotgames.com"
ENDPOINTS = {
    "BR": "br1",
    "EUNE": "eun1",
    "EUW": "euw1",
    "JP": "jp1",
    "LAN": "la1",
    "LAS": "la2",
    "NA": "na1",
    "OCE": "oc1",
    "TR": "tr1",
    "RU": "ru"
}
for endpoint in ENDPOINTS:
    ENDPOINTS[endpoint] = "https://" + ENDPOINTS[endpoint]


def async_cache(size: int=32):
    cache = collections.OrderedDict()

    def decorator(f):
        @functools.wraps(f)
        async def decorated_function(client, *args):
            key = ':'.join(args)
            if key not in cache:
                if len(cache) >= size:
                    cache.popitem()
                cache[key] = await f(client, *args)
            return cache[key]
        return decorated_function
    return decorator


class LeagueAPIClient:
    """An asynchronous interface to the League of Legends API."""

    def __init__(self, key: str):
        self._cs = aiohttp.ClientSession(
            loop=asyncio.get_event_loop(),
            headers={'X-Riot-Token': key}
        )

    def __del__(self):
        self._cs.close()

    async def _get(self, url, **kwargs):
        async with self._cs.get(url, **kwargs) as res:
            if res.status == 429:
                await asyncio.sleep(res.headers['Retry-After'])
                return await self._get(url, **kwargs)
            return await res.json()

    @async_cache()
    async def get_summoner(self, region: str, name: str) -> Optional[dict]:
        if region not in ENDPOINTS:
            raise ValueError(f"{region} is not a valid region")
        url = ENDPOINTS[region] + BASE_API_URL + "/lol/summoner/v3/summoners/by-name/" + name
        return await self._get(url)

    @async_cache()
    async def get_champion(self, name: str) -> Optional[dict]:
        url = ENDPOINTS['NA'] + BASE_API_URL + "/lol/static-data/v3/champions"
        res = await self._get(url, headers={'locale': 'en_US'})
        return next((c for c in res['data'].values() if c['name'] == name), None)

    async def get_mastery(self, region: str, summoner: Union[str, int], champion: Union[str, int]) -> int:
        if region not in ENDPOINTS:
            raise ValueError(f"{region} is not a valid region")

        if isinstance(summoner, str):
            summoner_id = await self.get_summoner(region, summoner)
        else:
            summoner_id = summoner

        if isinstance(champion, str):
            champion_data = await self.get_champion(champion)
            champion_id = champion_data['id']
        else:
            champion_id = champion

        endpoint_url = ENDPOINTS[region] + BASE_API_URL + "/lol/champion-mastery/v3/champion-masteries"
        parametrized_url = f"{endpoint_url}/by-summoner/{summoner_id}/by-champion/{champion_id}"
        res = await self._get(parametrized_url)
        return res['championPoints']
