import logging
from datetime import datetime
from os import environ

import humanize
from discord import Colour, Embed, Guild


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

    async def on_guild_join(self, guild: Guild):
        if self.channel is not None:
            info_embed = Embed(
                title="Joined a Guild",
                colour=Colour.blurple()
            ).add_field(
                name="Total guild members",
                value=f"`{guild.member_count}`"
            ).add_field(
                name="Total channels",
                value=f"`{len(guild.channels)}`"
            ).add_field(
                name="Owner",
                value=f"{guild.owner} (`{guild.owner.id}`)"
            ).add_field(
                name="Creation",
                value=f"{guild.created_at.strftime('%d.%m.%y %H:%M')} "
                      f"({humanize.naturaldelta(datetime.utcnow() - guild.created_at)})"
            ).set_author(
                name=f"{guild} ({guild.id})"
            )

            if guild.icon_url:
                info_embed.set_thumbnail(url=guild.icon_url)

            await self.channel.send(embed=info_embed)
