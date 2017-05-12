import asyncio
import datetime
import logging
import uvloop

from builtins import ModuleNotFoundError
from discord import Embed, Colour
from discord.ext import commands
from os import environ, makedirs

asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

# Set up Logging
makedirs('logs', exist_ok=True)
standard_formatter = logging.Formatter('[%(levelname)s] %(asctime)s (%(name)s): %(message)s')
discord_logger = logging.getLogger('discord')
discord_logger.setLevel(logging.INFO)
discord_handler = logging.FileHandler(filename='logs/discord.log', encoding='utf-8', mode='w')
discord_handler.setFormatter(standard_formatter)
discord_logger.addHandler(discord_handler)
bot_logger = logging.getLogger('bot')
bot_logger.setLevel(logging.INFO)
bot_handler = logging.FileHandler(filename='logs/bot.log', encoding='utf-8', mode='w')
bot_handler.setFormatter(standard_formatter)
bot_logger.addHandler(bot_handler)


class Bot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix=commands.when_mentioned_or('!', '?'), description='beep bop', pm_help=None)
        self.start_time = datetime.datetime.now()

    # Helper function to create and return an Embed with red colour.
    @staticmethod
    def make_error_embed(description):
        return Embed(colour=Colour.red(), description=description)

    async def on_command_error(self, error, ctx):
        if isinstance(error, commands.BadArgument):
            await ctx.send(embed=self.make_error_embed('You invoked the Command with the wrong type of arguments.'
                                                       ' Use `!help command` to get information about its usage.'))
        elif isinstance(error, commands.CommandNotFound):
            pass
        elif isinstance(error, commands.CommandInvokeError):
            await ctx.send(embed=self.make_error_embed(f'An Error occurred through the invocation of the command: '
                                                       f'{error}'))
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
        print(f'Invite Link:\nhttps://discordapp.com/oauth2/authorize?&client_id={self.user.id}&scope=bot')
        print('=============')

    async def on_message(self, msg):
        if msg.author.bot:
            return

        await self.process_commands(msg)


client = Bot()


# Base path where cogs house
COGS_BASE_PATH = 'src.cogs.'

# Cogs to load on login
COGS_ON_LOGIN = [
    'admin',
    'mod'
]


if __name__ == '__main__':
    print('Loading Cogs...')
    for cog in COGS_ON_LOGIN:
        try:
            client.load_extension(COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')
        else:
            print(f'Loaded Cog {cog.title()}.')

    print('Logging in...')
    client.run(environ['DISCORD_TOKEN'])
    print('Logged off.')

    # Close Logging
    discord_handler.close()
    bot_handler.close()
    discord_logger.removeHandler(discord_handler)
    bot_logger.removeHandler(discord_handler)


