import discord
from discord.ext import commands


class Admin:
    """Contains Commands for the Administration of the Bot."""

    def __init__(self, bot):
        self.bot = bot
        print('Loaded Cog Admin.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Admin.')

    @commands.command(hidden=True)
    @commands.is_owner()
    async def shutdown(self, ctx):
        print('Shutting down by owner request...')
        await ctx.send(embed=discord.Embed(description='Shutting down...'))
        await self.bot.cleanup()
        await self.bot.close()

    @commands.command(name='setplaying', hidden=True)
    @commands.is_owner()
    async def set_playing(self, _, *, new_status: str):
        await self.bot.change_presence(game=discord.Game(name=new_status))

    @commands.command(name='setnick', hidden=True)
    @commands.is_owner()
    async def set_nick(self, ctx, *, nick):
        await ctx.guild.me.edit(nick=nick)

    @commands.command(name='setname', hidden=True)
    @commands.is_owner()
    async def set_user_name(self, _, *, username):
        await self.bot.user.edit(username=username)

    @commands.command(hidden=True)
    @commands.is_owner()
    async def cogs(self, ctx):
        await ctx.send(embed=discord.Embed(
            title=f'Currently loaded Cogs ({len(self.bot.cogs)} total)',
            description=', '.join(self.bot.cogs)
        ))
