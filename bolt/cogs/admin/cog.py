import logging
import importlib

import discord
from discord.ext import commands

from bolt.constants import MAIN_COGS_BASE_PATH


log = logging.getLogger(__name__)


class Admin:
    """Contains Commands for the Administration of the Bot."""

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog Admin.')

    @staticmethod
    def __unload():
        log.debug('Unloaded Cog Admin.')

    @commands.group(invoke_without_command=True, aliases=['cog'])
    @commands.is_owner()
    async def cogs(self, ctx):
        await ctx.invoke(self.cogs_loaded)

    @cogs.command(name='load')
    @commands.is_owner()
    async def cogs_load(self, ctx, extension_name: str):
        if extension_name.title() in self.bot.cogs:
            error_embed = discord.Embed(
                title=f"Failed to load Cog `{extension_name}`:",
                description="Cog is already loaded",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)

        else:
            try:
                self.bot.load_extension(MAIN_COGS_BASE_PATH + extension_name)
            except ImportError as err:
                error_embed = discord.Embed(
                    title=f"Failed to load Cog `{extension_name}`:",
                    description=str(err),
                    colour=discord.Colour.red()
                )
                await ctx.send(embed=error_embed)
            else:
                loaded_cog_embed = discord.Embed(
                    title=f"Loaded Cog `{extension_name}`!",
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=loaded_cog_embed)

    @cogs.command(name='unload')
    @commands.is_owner()
    async def cogs_unload(self, ctx, extension_name: str):
        if extension_name.title() not in self.bot.cogs:
            error_embed = discord.Embed(
                title=f"Failed to unload Cog `{extension_name}`:",
                description="Cog is not loaded",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)

        else:
            self.bot.unload_extension(MAIN_COGS_BASE_PATH + extension_name)
            unloaded_cog_embed = discord.Embed(
                title=f"Unloaded Cog `{extension_name}`!",
                colour=discord.Colour.green()
            )
            await ctx.send(embed=unloaded_cog_embed)

    @cogs.command(name='loaded')
    @commands.is_owner()
    async def cogs_loaded(self, ctx):
        loaded_cogs_embed = discord.Embed(
            title=f"Loaded Cogs (`{len(self.bot.cogs)}` total)",
            description='\n'.join(f"• {cog}" for cog in sorted(self.bot.cogs)),
            colour=discord.Colour.blurple()
        )
        await ctx.send(embed=loaded_cogs_embed)

    @commands.command(hidden=True)
    @commands.is_owner()
    async def shutdown(self, ctx):
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
