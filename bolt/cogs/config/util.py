from typing import Optional

from peewee import DoesNotExist

from bolt.database import objects
from bolt.decorators import async_cache
from .models import Prefix


@async_cache()
async def get_prefix_for_guild(guild_id: int) -> Optional[str]:
    """
    Get the prefix for the given guild.

    Args:
        guild_id (int):
            The guild ID to fetch the prefix for.

    Returns:
        Optional[str]:
            The prefix if the guild has one set,
            or `None` if that's not the case.
    """

    try:
        return (await objects.get(Prefix, guild_id=guild_id)).prefix
    except DoesNotExist:
        return None
