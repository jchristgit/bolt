import asyncio
import datetime
import discord
import random
import uvloop
import sys
import traceback

from builtins import ModuleNotFoundError
from discord import Colour, ConnectionClosed, Embed, Game
from discord.ext import commands
from os import environ

from src.util import create_logger

asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

# Set up Logging
logger = create_logger('discord')

DESCRIPTION = 'Hello! I am a Bot made by Volcyy#2359. ' \
              'You can prefix my Commands by either mentioning me, using `?` or `!`.'


class Bot(commands.AutoShardedBot):
    def __init__(self):
        game_name = random.choice(['with Volcyy', 'Support', 'League of Legends', 'Thresh', 'good bot',
                                   'with itself', 'with a garbo ADC'])
        super().__init__(command_prefix=commands.when_mentioned_or('!', '?'), description=DESCRIPTION, pm_help=None,
                         game=Game(name=game_name))
        self.start_time = datetime.datetime.now()

    # Helper function to create and return an Embed with red colour.
    @staticmethod
    def make_error_embed(description):
        return Embed(colour=Colour.red(), description=description)

    async def on_command_error(self, ctx, error):
        if isinstance(error, commands.BadArgument):
            await ctx.send(embed=self.make_error_embed(f'**You invoked the Command with the wrong type of arguments.'
                                                       f' Use `!help command` to get information about its usage.**\n'
                                                       f'({error})'))
        elif isinstance(error, commands.CommandNotFound):
            pass
        elif isinstance(error, commands.CommandInvokeError):
            await ctx.send(embed=self.make_error_embed(f'**An Error occurred through the invocation of the command**.\n'
                                                       f'Please contact Volcyy#2359 with a detailed '
                                                       f'description of the problem and how it was created. Thanks!'))
            print('In {0.command.qualified_name}:'.format(ctx), file=sys.stderr)
            traceback.print_tb(error.original.__traceback__)
            print('{0.__class__.__name__}: {0}'.format(error.original), file=sys.stderr)
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

    @staticmethod
    async def _guild_event_note(destination: discord.abc.Messageable, guild: discord.Guild, title: str):
        note = discord.Embed()
        note.set_thumbnail(url=guild.icon_url)
        note.title = title
        online_members = sum(1 for m in guild.members if m.status != discord.Status.online)
        note.add_field(name='Members', value=f'Total: {guild.member_count}\nOnline: {online_members}')
        note.add_field(name='Channels', value=str(sum(1 for _ in guild.channels)))
        note.add_field(name='Owner', value=f'{guild.owner.name}#{guild.owner.discrim}\nID: `{guild.owner_id}`')
        await destination.send(embed=note)

    async def on_guild_join(self, guild: discord.Guild):
        await self._guild_event_note(self.get_user(self.owner_id), guild, f'Joined Guild {guild.name} ({guild.id})')

    async def on_guild_remove(self, guild: discord.Guild):
        await self._guild_event_note(self.get_user(self.owner_id), guild, f'Left Guild {guild.name} ({guild.id})')

client = Bot()


# Base path where cogs house
COGS_BASE_PATH = 'src.cogs.'

# Cogs to load on login
COGS_ON_LOGIN = [
    'admin',
    'meta',
    'mod',
    'streams',
    'roles'
]


if __name__ == '__main__':
    print('Loading Cogs...')
    for cog in COGS_ON_LOGIN:
        try:
            client.load_extension(COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')

    print('Logging in...')
    try:
        client.run(environ['DISCORD_TOKEN'])
    except ConnectionClosed:
        pass
    print('Logged off.')


