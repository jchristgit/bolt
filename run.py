import asyncio
import datetime
import logging
import uvloop

from builtins import ModuleNotFoundError
from discord.ext import commands
from os import environ, makedirs

makedirs('logs', exist_ok=True)
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

# Set up Logging
discord_logger = logging.getLogger('discord')
discord_logger.setLevel(logging.INFO)
discord_handler = logging.FileHandler(filename='discord.log', encoding='utf-8', mode='w')
discord_handler.setFormatter(logging.Formatter('[%(levelname)s] %(asctime)s:%(name)s: %(message)s'))
discord_logger.addHandler(discord_handler)


class Bot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix=commands.when_mentioned_or(['!']), description='beep bop', pm_help=None)
        self.start_time = datetime.datetime.now()

    async def on_ready(self):
        print('= LOGGED IN =')
        print(f'User: {self.user}')
        print(f'ID: {self.user.id}')
        print(f'Connected to {len(self.guilds)} Guilds.')
        print(f'Connected to {len(self.users)} Users.')
        print(f'Invite Link:\nhttps://discordapp.com/oauth2/authorize?&client_id={self.user.id}&scope=discordbot')
        print('=============')

    async def on_message(self, msg):
        if msg.author.bot:
            return

        # TODO: make Discord Bot only shutdown on shutdown command, since ^C not good
        if msg.content == '!shutdown':
            await self.close()

        await self.process_commands(msg)


client = Bot()


# Base path where cogs house
COGS_BASE_PATH = 'src.cogs.'

# Cogs to load on login
COGS_ON_LOGIN = [
    'roles'
]


if __name__ == '__main__':
    print('Loading Cogs...')
    for cog in COGS_ON_LOGIN:
        try:
            client.load_extension(COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')
        else:
            print(f'Loaded Cog {cog}.')


    print('Logging in...')
    client.run(environ['DISCORD_TOKEN'])
    print('Logged off.')


