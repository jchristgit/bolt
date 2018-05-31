import logging


log = logging.getLogger(__name__)


class Infractions:
    """Infraction management, create / read / update / delete."""

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog Infractions.')

    def __unload(self):
        log.debug('Unloaded Cog Infractions.')
