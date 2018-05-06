from .bot import Bot
from .bot.config import CONFIG
from bolt.bot.logging import create_logger

# Set up Logging
logger = create_logger('discord')

MAIN_COGS_BASE_PATH = 'bolt.cogs.'
MAIN_COGS = [
    'admin',
    'config',
    'meta',
    'mod',
    'roles',
    'tags'
]


OPTIONAL_COGS_BASE_PATH = 'bolt.optional_cogs.'
OPTIONAL_COGS = [
    'example',
    'league',
    'slowmode'
]


if __name__ == '__main__':
    client = Bot()
    print('Loading Cogs...')
    for cog in MAIN_COGS:
        try:
            client.load_extension(MAIN_COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')
    for cog in OPTIONAL_COGS:
        try:
            client.load_extension(OPTIONAL_COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')

    print('Logging in...')
    client.run(CONFIG['discord']['token'])
    client.close()
    print('Logged off.')
