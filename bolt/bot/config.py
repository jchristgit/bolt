import json

import discord
from discord.ext import commands
from peewee import DoesNotExist

from ..cogs.config.models import Prefix
from ..database import objects

with open("config.json") as f:
    CONFIG = json.load(f)


async def get_prefix(bot, msg):
    # Works without prefix in DMs
    if isinstance(msg.channel, discord.abc.PrivateChannel):
        return commands.when_mentioned_or(*CONFIG['discord']['prefixes'], '')(bot, msg)

    # Check for custom per-guild prefix
    try:
        prefix = await objects.get(Prefix, guild_id=msg.guild.id)
    except DoesNotExist:
        return commands.when_mentioned_or(*CONFIG['discord']['prefixes'])(bot, msg)
    else:
        return commands.when_mentioned_or(prefix.prefix)(bot, msg)
