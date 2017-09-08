import aiohttp


class NotFoundError(Exception):
    pass


async def get(url: str, headers: list) -> dict:
    async with aiohttp.ClientSession as cs:
        async with cs.get(url, headers=headers) as r:
            r.raise_for_status()
            if r.status == 200:
                return await r.json()
            elif r.status == 404:
                raise NotFoundError()

