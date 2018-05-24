from typing import Optional

from peewee import DoesNotExist

from bolt.database import objects
from .models import StaffLogChannel


async def get_log_channel(guild_id: int) -> Optional[StaffLogChannel]:
    """
    Get the staff log channel for the given Guild ID.

    Args:
        guild_id (int):
            The guild ID whose log channel should be returned.

    Returns:
        Optional[StaffLogChannel]:
            The channel object if it could be found, otherwise,
            if nothing was found, `None` is returned.
    """

    try:
        return await objects.get(
            StaffLogChannel,
            guild_id=guild_id
        )
    except DoesNotExist:
        return None
