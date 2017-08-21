import aiohttp

from ..util import create_logger

log = create_logger('api')


class NotFoundError(Exception):
    pass


class Requester:
    def __init__(self):
        self._cs = None

    def __del__(self):
        if self._cs is not None:
            self._cs.close()

    async def get(self, url: str, headers: list) -> dict:
        if self._cs is None:
            self._cs = aiohttp.ClientSession()
        async with self._cs.get(url, headers=headers) as r:
            r.raise_for_status()
            if r.status == 200:
                return await r.json()
            elif r.status == 404:
                raise NotFoundError()

