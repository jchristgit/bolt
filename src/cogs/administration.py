import logging

from discord import Embed
from discord.ext import commands

log = logging.getLogger('bot')


class Administration:
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.is_owner()
    @commands.command(hidden=True)
    async def shutdown(self, ctx):
        """Shutdown the Bot. Owner only."""
        await ctx.send(embed=Embed(description='Shutting down...'))
        await self.bot.close()


def setup(bot):
    bot.add_cog(Administration(bot))


def teardown():
    print('Unloaded Cog Administration')
