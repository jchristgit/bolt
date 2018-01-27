import asyncio

import discord
from discord.ext import commands

from .base import OptionalCog, enabled_for


class Slowmode(OptionalCog):
    RESTRICTED = False

    def __init__(self, bot):
        super().__init__(bot)
        bot.add_listener(self.on_message)
        self.in_slowmode = set()
        self.slowmode_channels = set()

    async def on_message(self, msg):
        if msg.guild is not None and not await enabled_for(self, msg.guild.id):
            return

        if msg.channel in self.slowmode_channels or msg.author in self.in_slowmode:
            if msg.author.top_role < msg.guild.me.top_role:
                await msg.channel.set_permissions(msg.author, send_messages=False)
                await asyncio.sleep(10 + 5 * max(0, len(self.in_slowmode) - 5))
                await msg.channel.set_permissions(msg.author, send_messages=None)

    @commands.command()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_roles=True)
    @commands.guild_only()
    async def slowmode(self, ctx, user: discord.Member):
        """Toggles slowmode on the given User."""

        if user in self.in_slowmode:
            self.in_slowmode.remove(user)
            await ctx.send(embed=discord.Embed(
                description=f'User {user.mention} is no longer in slowmode.',
                colour=discord.Colour.green()
            ))
        elif user.top_role >= ctx.guild.me.top_role:
            await ctx.send(embed=discord.Embed(
                title=f'Failed to slowmode User:',
                description='User is higher or as high in the role hierarchy as I am.',
                colour=discord.Colour.red()
            ))
        else:
            self.in_slowmode.add(user)
            await ctx.send(embed=discord.Embed(
                description=f'User {user.mention} is now in slowmode.',
                colour=discord.Colour.green()
            ))

    @commands.command(name="cslowmode")
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_roles=True)
    @commands.guild_only()
    async def channel_slowmode(self, ctx):
        """Toggles slowmode in the channel in which this command is invoked."""

        if ctx.channel in self.slowmode_channels:
            self.slowmode_channels.remove(ctx.channel)
            await ctx.send(embed=discord.Embed(
                title='Channel is no longer in slowmode.',
                colour=discord.Colour.green()
            ))
        else:
            self.slowmode_channels.add(ctx.channel)
            await ctx.send(embed=discord.Embed(
                title='Channel is now in slowmode.',
                colour=discord.Colour.green()
            ))


def setup(bot):
    bot.add_cog(Slowmode(bot))
