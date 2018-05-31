import logging
from os import environ

from discord import Colour, Embed


log = logging.getLogger(__name__)


class BotLog:
    """Bot logging utilities."""

    def __init__(self, bot):
        self.bot = bot
        self.channel = None
        log.debug("Loaded Cog BotLog.")

    def __unload(self):
        log.debug("Unloaded Cog BotLog.")

    async def on_ready(self):
        if 'BOTLOG_CHANNEL_ID' not in environ:
            log.warning("No bot log channel is set, bot logging will NOT be enabled.")

        log_channel_id = environ['BOTLOG_CHANNEL_ID']
        try:
            self.channel = self.bot.get_channel(int(log_channel_id))
        except ValueError:
            log.error(f"{log_channel_id} is not a valid channel ID, must be an integer")
        else:
            if self.channel is None:
                log.error(f"Failed to find bot log channel under ID {log_channel_id}")
            else:
                info_embed = Embed(
                    title="Logged in and ready",
                    colour=Colour.green()
                ).add_field(
                    name="Total members",
                    value=f"`{len(self.bot.users)}`"
                ).add_field(
                    name="Total guilds",
                    value=f"`{len(self.bot.guilds)}`"
                ).add_field(
                    name="Total commands",
                    value=f"`{len(self.bot.commands)}`"
                )
                await self.channel.send(embed=info_embed)
