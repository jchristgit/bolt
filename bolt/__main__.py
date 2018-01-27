from bolt.bot import Bot
from .util import CONFIG, create_logger

# Set up Logging
logger = create_logger('discord')

# Base path where cogs house
COGS_BASE_PATH = 'bolt.'

# Cogs to load on login
COGS_ON_LOGIN = [
    'admin',
    'meta',
    'mod',
    'roles',
    'tags'
]


if __name__ == '__main__':
    client = Bot()
    print('Loading Cogs...')
    for cog in COGS_ON_LOGIN:
        try:
            client.load_extension(COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            print(f'Could not load Cog \'{cog}\': {err}.')

    print('Logging in...')
    client.run(CONFIG['discord']['token'])
    client.close()
    print('Logged off.')
