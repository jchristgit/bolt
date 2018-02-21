from discord.ext import commands

from .api import ENDPOINTS


class Region(commands.Converter):
    async def convert(self, ctx, argument):
        region = argument.upper()
        if region not in ENDPOINTS:
            raise commands.BadArgument(f"Unknown region: {region}")
        return region
