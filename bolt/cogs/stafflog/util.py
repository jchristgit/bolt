from typing import Optional

from discord import Guild
from discord.ext.commands import Bot
from peewee import DoesNotExist

from bolt.database import objects
from .models import StaffLogChannel


async def get_log_channel(bot: Bot, guild: Guild) -> Optional[StaffLogChannel]:
    """
    Get the staff log channel for the given Guild ID.

    Args:
        bot (Bot):
            The bot from which to fetch the text channel.
        guild (Guild):
            The guild whose log channel should be returned.

    Returns:
        Optional[StaffLogChannel]:
            The channel object if it could be found, otherwise,
            if nothing was found, `None` is returned.
    """

    try:
        return await objects.get(
            StaffLogChannel,
            guild_id=guild.id
        )
    except DoesNotExist:
        return None
