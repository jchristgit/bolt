import logging
from contextlib import suppress

import discord
from discord.ext import commands
from peewee import DoesNotExist

from bolt.database import objects
from .models import OptionalCog, Prefix
from .util import get_prefix_for_guild


log = logging.getLogger(__name__)


class Config:
    """
    Commands to configure the bot on a per-guild basis,
    such as changing its prefix or enabling / disabling cogs.
    """

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog Config.')

    @staticmethod
    def __unload():
        log.debug('Unloaded Cog Config.')

    @commands.command(name='enablecog', aliases=['cogon'])
    @commands.guild_only()
    @commands.has_permissions(administrator=True)
    async def enable_cog(self, ctx, *, cog_name: str):
        """Enables the given optional Cog on the current guild.

        This command may only be used by Administrators.

        Some optional cogs may be restricted, meaning that they
        may only be enabled by the bot's owner.
        """

        cog_name = cog_name.title()
        cog = self.bot.get_cog(cog_name)

        if cog is None:
            return await ctx.send(embed=discord.Embed(
                title="Failed to enable Cog:",
                description=f"No cog named `{cog_name}` found.",
                colour=discord.Colour.red()
            ))

        try:
            await objects.get(
                OptionalCog,
                name=cog_name,
                guild_id=ctx.guild.id
            )
        except DoesNotExist:
            app_info = await self.bot.application_info()
            if cog.RESTRICTED and ctx.author != app_info.owner:
                return await ctx.send(embed=discord.Embed(
                    title='Failed to enable Cog:',
                    description='This Cog is restricted and may only be enabled by the bot\'s owner.',
                    colour=discord.Colour.red()
                ))

            await objects.create(
                OptionalCog,
                name=cog_name,
                guild_id=ctx.guild.id
            )
            await ctx.send(embed=discord.Embed(
                title='Successfully enabled Cog',
                description=f'`{cog_name}` is now enabled on this Guild.',
                colour=discord.Colour.green()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title='Failed to enable Cog:',
                description=f'`{cog_name}` is already enabled on this Guild.',
                colour=discord.Colour.red()
            ))

    @commands.command(name='disablecog', aliases=['cogoff'])
    @commands.guild_only()
    @commands.has_permissions(administrator=True)
    async def disable_cog(self, ctx, *, cog_name: str):
        """Disables the given optional Cog on the current Guild.

        This command may only be used by Administrators.
        """

        cog_name = cog_name.title()
        cog = self.bot.get_cog(cog_name)

        if cog is None:
            return await ctx.send(embed=discord.Embed(
                title="Failed to enable Cog:",
                description=f"No cog named `{cog_name}` found.",
                colour=discord.Colour.red()
            ))

        try:
            optional_cog = await objects.get(
                OptionalCog,
                name=cog_name,
                guild_id=ctx.guild.id
            )
            await objects.delete(optional_cog)
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title='Failed to disable Cog:',
                description=f'`{cog_name}` is not enabled on this Guild.',
                colour=discord.Colour.red()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title='Successfully disabled Cog',
                description=f'`{cog_name}` is now disabled on this Guild.',
                colour=discord.Colour.green()
            ))

    @commands.command(name='setprefix')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def set_prefix(self, ctx, *, new_prefix: str=None):
        """Change the prefix of this Guild for me to the given Prefix.

        All `_` will be replaced with a space, which allows you to do some nice things:
        To use a prefix that ends with a space, e.g. `botty lsar`, use `_` to set it,
        since spaces will get truncated by Discord automatically, for example:
        `setprefix botty_`
        `botty help`

        Another example: If you prefer being polite, you could use the following:
        `setprefix botty pls_`
        `botty pls help`


        Keep in mind that if you ever forget the prefix, I also react to mentions, so just mention me if you need help.
        Alternatively, to reset the prefix, just use this command
        without specifying a new prefix you wish to use, like `setprefix`.
        """

        print(get_prefix_for_guild.cache)
        with suppress(DoesNotExist):
            current_prefix = await objects.get(Prefix, guild_id=ctx.guild.id)
            await objects.delete(current_prefix)

        if new_prefix is None:
            await ctx.send(embed=discord.Embed(
                title='Reset this Guild\'s prefix',
                description='My prefix is now reset to the default. Alternatively, you can mention me.',
                colour=discord.Colour.green()
            ))
            if (ctx.guild.id,) in get_prefix_for_guild.cache:
                del get_prefix_for_guild.cache[(ctx.guild.id,)]

        else:
            new_prefix = new_prefix.replace('_', ' ')
            await objects.create(
                Prefix,
                guild_id=ctx.guild.id,
                prefix=new_prefix
            )
            await ctx.send(embed=discord.Embed(
                title=f'Set Prefix to `{new_prefix}`{", with a space" if new_prefix.endswith(" ") else ""}.',
                colour=discord.Colour.green()
            ))
            get_prefix_for_guild.cache[(ctx.guild.id,)] = new_prefix
            print(get_prefix_for_guild.cache)

    @commands.command(name='getprefix')
    @commands.guild_only()
    async def get_prefix(self, ctx):
        """Tells you which prefix is currently active on this guild."""

        prefix = await get_prefix_for_guild(ctx.guild.id)
        if prefix is None:
            await ctx.send(embed=discord.Embed(
                title='Custom Guild Prefix',
                description='This Guild has no custom prefix set.',
                colour=discord.Colour.blue()
            ))
        else:
            humanized_prefix = f"`{prefix}`{', with a space' if prefix.endswith(' ') else ''}"
            await ctx.send(embed=discord.Embed(
                title='Custom Guild Prefix',
                description=f'The custom prefix for this guild is {humanized_prefix}.',
                colour=discord.Colour.blue()
            ))
