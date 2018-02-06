import asyncio
import collections
import time

import discord
from discord.ext import commands

from ..base import OptionalCog, enabled_for


class Slowmode(OptionalCog):
    RESTRICTED = False

    def __init__(self, bot):
        super().__init__(bot)
        bot.add_listener(self.on_message)
        self.users = collections.defaultdict(lambda: (time.monotonic(), 1))
        self.slowmode_users = set()
        self.slowmode_channels = set()

    async def on_message(self, msg):
        if msg.guild is not None and not await enabled_for(self, msg.guild.id):
            return

        if msg.channel in self.slowmode_channels:
            if msg.author.top_role < msg.guild.me.top_role:
                last_time, count = self.users[msg.author.id]

                # if the author did not send anything in the past 10 seconds, remove his entry
                if time.monotonic() - last_time > 10:
                    del self.users[msg.author.id]
                    return

                if count >= 5:
                    await msg.channel.set_permissions(msg.author, send_messages=False)
                    await asyncio.sleep(1)
                    await msg.channel.set_permissions(msg.author, overwrite=None)
                    del self.users[msg.author.id]
                else:
                    self.users[msg.author.id] = (last_time, count + 1)

        elif msg.author in self.slowmode_users:
            await msg.channel.set_permissions(msg.author, send_messages=False)
            await asyncio.sleep(1)
            await msg.channel.set_permissions(msg.author, overwrite=None)

    @commands.command()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_roles=True)
    @commands.guild_only()
    async def slowmode(self, ctx, user: discord.Member):
        """Toggles slowmode on the given User."""

        if user in self.slowmode_users:
            self.slowmode_users.remove(user)
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
            self.slowmode_users.add(user)
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
