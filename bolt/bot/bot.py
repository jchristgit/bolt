import random

import discord
from discord import Game, Embed, Colour
from discord.ext import commands

from .. import database
from .config import CONFIG, get_prefix
from .logging import create_logger


class Bot(commands.AutoShardedBot):
    def __init__(self):
        super().__init__(
            command_prefix=get_prefix,
            description=CONFIG['discord']['description'],
            pm_help=None,
            game=Game(name=random.choice(CONFIG['discord']['playing_states']))
        )
        self.db = None
        self.logger = create_logger('discord')

    # Helper function to create and return an Embed with red colour.
    @staticmethod
    def make_error_embed(description):
        return Embed(colour=Colour.red(), description=description)

    async def on_connect(self):
        await self.init()

    async def init(self):
        if self.db is None:
            self.db = await database.engine.connect()

    async def cleanup(self):
        if self.db is not None:
            await self.db.close()

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
        print('= LOGGED IN =')
        print(f'User: {self.user}')
        print(f'ID: {self.user.id}')
        print(f'Connected to {len(self.guilds)} Guilds.')
        print(f'Connected to {len(self.users)} Users.')
        print(f'Total of {len(self.commands)} Commands in {len(self.cogs)} Cogs.')
        print(f'Invite Link:\nhttps://discordapp.com/oauth2/authorize?&client_id={self.user.id}&scope=bot')
        print('=============')

    async def on_message(self, msg):
        if msg.author.bot:
            return

        await self.process_commands(msg)
