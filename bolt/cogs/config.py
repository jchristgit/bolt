import discord

from discord.ext import commands
from sqlalchemy import and_

from ..models import (
    opt_cog as opt_cog_model,
    prefix as prefix_model
)


class Config:
    """
    Commands to configure the bot on a per-guild basis,
    such as changing its prefix or enabling / disabling cogs.
    """

    def __init__(self, bot):
        self.bot = bot

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

        query = opt_cog_model.select().where(and_(opt_cog_model.c.name == cog_name,
                                                  opt_cog_model.c.guild_id == ctx.guild.id))
        res = await self.bot.db.execute(query)
        cog_row = await res.first()

        if cog_row is None:
            app_info = await self.bot.application_info()
            if cog.RESTRICTED and ctx.author != app_info.owner:
                return await ctx.send(embed=discord.Embed(
                    title='Failed to enable Cog:',
                    description='This Cog is restricted and may only be enabled by the bot\'s owner.',
                    colour=discord.Colour.red()
                ))

            query = opt_cog_model.insert().values(name=cog_name, guild_id=ctx.guild.id)
            await self.bot.db.execute(query)
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

        query = opt_cog_model.select().where(and_(opt_cog_model.c.name == cog_name,
                                                  opt_cog_model.c.guild_id == ctx.guild.id))
        res = await self.bot.db.execute(query)
        cog_row = await res.first()

        if cog_row is not None:
            query = opt_cog_model.delete().where(and_(opt_cog_model.c.name == cog_name,
                                                      opt_cog_model.c.guild_id == ctx.guild.id))
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                title='Successfully disabled Cog',
                description=f'`{cog_name}` is now disabled on this Guild.',
                colour=discord.Colour.green()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title='Failed to disable Cog:',
                description=f'`{cog_name}` is not enabled on this Guild.',
                colour=discord.Colour.red()
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

        # This command always has to delete an existing prefix if it is present.
        query = prefix_model.delete().where(prefix_model.c.guild_id == ctx.guild.id)
        await self.bot.db.execute(query)

        if new_prefix is None:
            await ctx.send(embed=discord.Embed(
                title='Reset this Guild\'s prefix',
                description='My prefix is now reset to the default. Alternatively, you can mention me.',
                colour=discord.Colour.green()
            ))
        else:
            new_prefix = new_prefix.replace('_', ' ')
            query = prefix_model.insert().values(guild_id=ctx.guild.id, prefix=new_prefix)
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                title=f'Set Prefix to `{new_prefix}`{", with a space" if new_prefix[-1] == " " else ""}.',
                colour=discord.Colour.green()
            ))

    @commands.command(name='getprefix', aliases=['prefix'])
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def get_prefix(self, ctx):
        """Tells you which prefix is currently active on this guild."""

        query = prefix_model.select().where(prefix_model.c.guild_id == ctx.guild.id)
        res = await self.bot.db.execute(query)
        prefix_row = await res.first()

        if prefix_row is None:
            await ctx.send(embed=discord.Embed(
                title='Custom Guild Prefix',
                description='This Guild has no custom prefix set.',
                colour=discord.Colour.blue()
            ))
        else:
            humanized_prefix = f'`{prefix_row.prefix}`{", with a space" if prefix_row.prefix[-1] == " " else ""}'
            await ctx.send(embed=discord.Embed(
                title='Custom Guild Prefix',
                description=f'The custom prefix for this guild is {humanized_prefix}.',
                colour=discord.Colour.blue()
            ))


def setup(bot):
    bot.add_cog(Config(bot))
