import aiohttp
import asyncio

from ..util import create_logger

log = create_logger('api')

_cs = aiohttp.ClientSession()


class NotFoundError(Exception):
    pass


async def get(url):
    async with _cs.get(url) as r:
        if r.status == 200:
            return await r.json()
        elif r.status == 404:
            raise NotFoundError()
        elif r.status == 429:
            log.warn('Sending too many requests to the Twitch API!')
            log.warn(f'URL: {url}')
            await asyncio.sleep(1)
            return await get(url)
