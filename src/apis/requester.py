import aiohttp
import asyncio

from ..util import create_logger

log = create_logger('api')
_cs = None


class NotFoundError(Exception):
    pass


async def get(url: str, headers: list) -> dict:
    global _cs
    if _cs is None:
        _cs = aiohttp.ClientSession()
    async with _cs.get(url, headers=headers) as r:
        if r.status == 200:
            return await r.json()
        elif r.status == 404:
            raise NotFoundError()
        elif r.status == 429:
            log.warn('Sending too many requests to the Twitch API!')
            await asyncio.sleep(1)
            return await get(url)


def close():
    if _cs is not None:
        _cs.close()
