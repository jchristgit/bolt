import logging

from .bot import Bot
from .bot.config import CONFIG


logging.basicConfig(
    format="%(asctime)s | %(name)25s | %(levelname)8s | %(message)s",
    datefmt="%d.%m.%y %H:%M:%S",
    level=logging.INFO
)

log = logging.getLogger(__name__)
logging.getLogger('discord').setLevel(logging.ERROR)


MAIN_COGS_BASE_PATH = 'bolt.cogs.'
MAIN_COGS = [
    'admin',
    'config',
    'meta',
    'mod',
    'purging',
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
    log.debug('Loading Cogs...')
    for cog in MAIN_COGS:
        try:
            client.load_extension(MAIN_COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            log.error(f'Could not load Cog \'{cog}\': {err}.')
    for cog in OPTIONAL_COGS:
        try:
            client.load_extension(OPTIONAL_COGS_BASE_PATH + cog)
        except ModuleNotFoundError as err:
            log.error(f'Could not load Cog \'{cog}\': {err}.')

    log.info('Logging in...')
    client.run(CONFIG['discord']['token'])
    client.close()
    log.info('Logged off.')
