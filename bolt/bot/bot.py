import logging
import random

import discord
from discord import Colour, Embed, Game
from discord.ext import commands

from .config import CONFIG, get_prefix


log = logging.getLogger(__name__)


class Bot(commands.AutoShardedBot):
    def __init__(self):
        super().__init__(
            command_prefix=get_prefix,
            description=CONFIG['discord']['description'],
            pm_help=None,
            game=Game(name=random.choice(CONFIG['discord']['playing_states']))
        )

    # Helper function to create and return an Embed with red colour.
    @staticmethod
    def make_error_embed(description):
        return Embed(colour=Colour.red(), description=description)

    async def on_command_error(self, ctx: commands.Context, error: commands.CommandError):
        if isinstance(error, commands.BadArgument):
            await ctx.send(embed=self.make_error_embed(f'Something went wrong with converting the command arguments:\n'
                                                       f'*{error}*'))
        elif isinstance(error, commands.CommandInvokeError):
            if isinstance(error.original, discord.errors.Forbidden):
                return await ctx.send(embed=discord.Embed(
                    title='You have Direct Messages disabled.',
                    description=('The Command you invoked requires me to send you a Direct Message, but '
                                 'I\'m not allowed to send you one. To fix this, right click on this guild '
                                 'and choose **Privacy Settings**, and tick **Allow direct messages from '
                                 'members**, then try the command again. Thanks!'),
                    colour=discord.Colour.blue()
                ))

            await ctx.send(embed=self.make_error_embed(
                ('**An Error occurred through the invocation of the command**.\n'
                 'Please contact Volcyy#2359 with a detailed '
                 'description of the problem and how it was created. Thanks!')
            ))

            await super(Bot, self).on_command_error(ctx, error)

        elif isinstance(error, commands.CheckFailure):
            await ctx.send(embed=self.make_error_embed(f'A check required for this command did not pass:\n*{error}*'))

        elif isinstance(error, commands.CommandOnCooldown):
            await ctx.send(embed=self.make_error_embed('This Command is currently on cooldown.'))

        elif isinstance(error, commands.DisabledCommand):
            await ctx.send(embed=self.make_error_embed('Sorry, this Command is currently disabled for maintenance.'))

        elif isinstance(error, commands.NoPrivateMessage):
            await ctx.send(embed=self.make_error_embed('This Command cannot be used in private Messages.'))

    async def on_ready(self):
        log.info("Logged in.")

    async def on_message(self, msg):
        if msg.author.bot:
            return

        await self.process_commands(msg)
