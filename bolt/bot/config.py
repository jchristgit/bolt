import json

import discord
from discord.ext import commands

from bolt.cogs.config.util import get_prefix_for_guild


with open("config.json") as f:
    CONFIG = json.load(f)


async def get_prefix(bot, msg):
    # Works without prefix in DMs
    if isinstance(msg.channel, discord.abc.PrivateChannel):
        return commands.when_mentioned_or(*CONFIG['discord']['prefixes'], '')(bot, msg)

    # Check for custom per-guild prefix
    prefix = await get_prefix_for_guild(msg.guild.id)
    if prefix is None:
        return commands.when_mentioned_or(*CONFIG['discord']['prefixes'])(bot, msg)
    else:
        return commands.when_mentioned_or(prefix)(bot, msg)
