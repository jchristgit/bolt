from discord import Embed, Game
from discord.ext import commands


class Admin:
    """
    Contains Commands for the Administration of the Bot.
    Unloading this Cog may not be a good idea. 
    """
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.command(hidden=True)
    @commands.is_owner()
    async def shutdown(self, ctx):
        """Shutdown the Bot. Owner only."""
        print('Shutting down by owner request...')
        await ctx.send(embed=Embed(description='Shutting down...'))
        await self.bot.close()

    @commands.command(name='setplaying', hidden=True)
    @commands.is_owner()
    async def set_playing(self, ctx, *, new_status):
        await self.bot.change_presence(game=Game(name=new_status))


def setup(bot):
    bot.add_cog(Admin(bot))
