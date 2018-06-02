import logging
from datetime import datetime, timedelta
from typing import Optional, Tuple, Union

import discord
import humanize
from discord.ext import commands
from peewee import DoesNotExist

from bolt.cogs.infractions.models import Infraction
from bolt.cogs.infractions.types import InfractionType
from bolt.database import objects
from .models import StaffLogChannel
from .util import get_log_channel as fetch_log_channel


log = logging.getLogger(__name__)


def thirty_seconds_ago() -> datetime:
    """
    Gives the time 30 seconds ago.

    Returns:
        datetime:
            A datetime object representing the
            date and time as they were 30 seconds ago.
    """

    return datetime.utcnow() - timedelta(seconds=30)


class StaffLog:
    """
    Commands that help configuring a staff log.
    Kind of like the audit log, but lasts as long
    as the bot's messages stay there and logs more events.
    """

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog StaffLog.')

    def __unload(self):
        log.debug('Unloaded Cog StaffLog.')

    async def get_log_channel(self, guild: discord.Guild) -> Optional[
        Tuple[
            StaffLogChannel,
            discord.TextChannel
            ]]:
        """
        Get the staff log channel for the given Guild ID.

        Args:
            guild_id (discord.Guild):
                The guild whose log channel should be returned.

        Returns:
            Optional[Tuple[StaffLogChannel, discord.TextChannel]]:
                The channel row and discord Channel if found,
                otherwise, if nothing was found, `None`.
        """

        channel_obj = await fetch_log_channel(self.bot, guild)
        if channel_obj is not None:
            channel = guild.get_channel(channel_obj.channel_id)
            if channel is None:
                log.debug(
                    "Previously set stafflog channel for guild {guild} ({guild.id}) "
                    "could not be found anymore, deleting from the database."
                )
                await objects.delete(channel_obj)
            return channel_obj, channel

    async def log_for(self, guild: discord.Guild, embed: discord.Embed):
        """
        Log the given embed in the given guild's staff log channel, if set.

        Args:
            guild (discord.Guild):
                The guild to log the event on.
            embed (discord.Embed):
                The embed to send in the staff log channel.
        """

        result_tuple = await self.get_log_channel(guild)
        if result_tuple is not None:
            channel_row, channel = result_tuple
            if channel_row.enabled and channel is not None:
                await channel.send(embed=embed)

    async def on_message_delete(self, message: discord.Message):
        if message.guild is None or message.author == self.bot.user:
            return

        info_embed = discord.Embed(
            title=f"🗑 Message deleted (`{message.id}`)",
            colour=discord.Colour.red(),
            timestamp=datetime.utcnow()
        ).set_author(
            name=f"{message.author} ({message.author.id})",
            icon_url=message.author.avatar_url
        ).add_field(
            name="Channel",
            value=message.channel.mention
        ).add_field(
            name="Creation date",
            value=message.created_at.strftime('%d.%m.%y %H:%M')
        ).add_field(
            name="System content",
            value=message.system_content
        )

        if message.attachments:
            info_embed.add_field(
                name=f"{len(message.attachments)} Attachments",
                value=', '.join(
                    f"[{attachment.filename}]({attachment.url})"
                    for attachment in message.attachments
                )
            )

        await self.log_for(message.guild, info_embed)

    async def on_member_join(self, member: discord.Member):
        info_embed = discord.Embed(
            title=f"📥 Member joined",
            colour=discord.Colour.green(),
            timestamp=datetime.utcnow()
        ).set_thumbnail(
            url=member.avatar_url
        ).add_field(
            name="User",
            value=f"`{member}` (`{member.id}`)"
        ).add_field(
            name="Account creation",
            value=f"{member.created_at.strftime('%d.%m.%y %H:%M')} UTC "
                  f"({humanize.naturaldelta(datetime.utcnow() - member.created_at)} ago)"
        )

        await self.log_for(member.guild, info_embed)

    async def on_member_remove(self, member: discord.Member):
        info_embed = discord.Embed(
            title=f"📤 Member left",
            colour=discord.Colour.red(),
            timestamp=datetime.utcnow()
        ).set_thumbnail(
            url=member.avatar_url
        ).add_field(
            name="User",
            value=f"`{member}` (`{member.id}`)"
        ).add_field(
            name="Joined at",
            value=f"{member.joined_at.strftime('%d.%m.%y %H:%M')} UTC "
                  f"({humanize.naturaldelta(datetime.utcnow() - member.joined_at)} ago)"
        )

        # We can only retrieve more specific information relevant
        # for the infraction database by checking the audit log.
        if member.guild.me.guild_permissions.view_audit_log:
            audit_entry = await member.guild.audit_logs(
                action=discord.AuditLogAction.kick,
                after=thirty_seconds_ago()
            ).find(
                lambda entry: entry.target == member
            )
            if audit_entry is not None:
                await self.handle_member_kick(member, audit_entry)
        else:
            info_embed.set_footer(
                text="By giving me the `view audit log` permission, "
                     "I can check the audit log for a kick."
            )

        await self.log_for(member.guild, info_embed)

    # This is not emitted by discord.py, but emitted through `on_member_remove` if applicable.
    async def handle_member_kick(self, member: discord.Member, audit_entry: discord.AuditLogEntry):
        info_embed = discord.Embed(
            title="👢 Member kicked",
            colour=discord.Colour.red(),
            timestamp=datetime.utcnow()
        ).set_thumbnail(
            url=member.avatar_url
        ).add_field(
            name="Reason",
            value=audit_entry.reason or "*no reason specified*"
        ).set_footer(
            text=f"Authored by {audit_entry.user} ({audit_entry.user.id})",
            icon_url=audit_entry.user.avatar_url
        )
        info_embed.timestamp = audit_entry.created_at

        created_infraction = await objects.create(
            Infraction,
            type=InfractionType.kick,
            guild_id=member.guild.id,
            user_id=member.id,
            moderator_id=audit_entry.user.id,
            reason=audit_entry.reason
        )

        info_embed.add_field(
            name="Infraction",
            value=f"created with ID `{created_infraction.id}`\n"
                  f"use `infr detail {created_infraction.id}` for details"
        )

        await self.log_for(member.guild, info_embed)

    async def on_member_ban(self, guild: discord.Guild, user: Union[discord.Member, discord.User]):
        info_embed = discord.Embed(
            title=f"🔨 Member banned",
            colour=discord.Colour.red(),
            timestamp=datetime.utcnow()
        ).set_thumbnail(
            url=user.avatar_url
        ).add_field(
            name="User",
            value=f"`{user}` (`{user.id}`)"
        )

        if guild.me.guild_permissions.view_audit_log:
            audit_entry = await guild.audit_logs(
                action=discord.AuditLogAction.ban,
                after=thirty_seconds_ago()
            ).find(
                lambda entry: entry.target == user
            )
            if audit_entry is not None:
                info_embed.add_field(
                    name="Reason",
                    value=audit_entry.reason or "*no reason specified*"
                ).set_footer(
                    text=f"Authored by {audit_entry.user} ({audit_entry.user.id})",
                    icon_url=audit_entry.user.avatar_url
                )
                info_embed.timestamp = audit_entry.created_at

                created_infraction = await objects.create(
                    Infraction,
                    type=InfractionType.ban,
                    guild_id=guild.id,
                    user_id=user.id,
                    moderator_id=audit_entry.user.id,
                    reason=audit_entry.reason
                )
                info_embed.add_field(
                    name="Infraction",
                    value=f"created with ID `{created_infraction.id}`\n"
                          f"use `infr detail {created_infraction.id}` for details"
                )

            else:
                info_embed.set_footer(
                    text="Tried fetching ban information from the "
                         "audit log, but couldn't find any relevant entry."
                )
        else:
            info_embed.set_footer(
                text="By giving me the `view audit log` permission, I can give more information."
            )

        await self.log_for(guild, info_embed)

    async def on_member_unban(self, guild: discord.Guild, user: discord.User):
        info_embed = discord.Embed(
            title=f"🤝 Member unbanned",
            colour=discord.Colour.blurple(),
            timestamp=datetime.utcnow()
        ).set_thumbnail(
            url=user.avatar_url
        ).add_field(
            name="User",
            value=f"`{user}` (`{user.id}`)"
        )

        if guild.me.guild_permissions.view_audit_log:
            audit_entry = await guild.audit_logs(
                action=discord.AuditLogAction.unban,
                after=thirty_seconds_ago()
            ).find(
                lambda entry: entry.target == user
            )

            if audit_entry is not None:
                info_embed.set_footer(
                    text=f"Authored by {audit_entry.user} ({audit_entry.user.id})",
                    icon_url=audit_entry.user.avatar_url
                )
                info_embed.timestamp = audit_entry.created_at
            else:
                info_embed.set_footer(
                    text="Tried fetching unban information from the "
                         "audit log, but couldn't find any relevant entry."
                )
        else:
            info_embed.set_footer(
                text="By giving me the `view audit log` permission, I can give more information."
            )

        await self.log_for(guild, info_embed)

    @commands.group(name='log', aliases=['stafflog'])
    @commands.has_permissions(manage_messages=True)
    @commands.guild_only()
    async def log_(self, ctx):
        """Contains subcommands for managing the staff log."""

    @log_.command(aliases=['on'])
    async def enable(self, ctx, channel: discord.TextChannel = None):
        """
        Enable the stafflog in the given channel.

        If a staff log channel was set previously,
        the channel argument may be ommitted.
        """

        if channel is None:
            try:
                channel_object = await objects.get(
                    StaffLogChannel,
                    guild_id=ctx.guild.id
                )
            except DoesNotExist:
                error_embed = discord.Embed(
                    title="Failed to enable log channel",
                    description=("There is no staff log channel currently set. "
                                 "Pass one as an argument to this command."),
                    colour=discord.Colour.red()
                )
                await ctx.send(embed=error_embed)
            else:
                if channel_object.enabled:
                    response_embed_title = "Staff log was already enabled"
                    response_embed_description = (
                        "The log channel is already enabled and the channel "
                        f"is set to <#{channel_object.channel_id}>."
                    )
                else:
                    channel_object.enabled = True
                    await objects.update(channel_object, only=['enabled'])

                    response_embed_title = "Staff log is now enabled"
                    response_embed_description = (
                        "Staff logging was successfully enabled "
                        f"in <#{channel_object.channel_id}>."
                    )

                response_embed = discord.Embed(
                    title=response_embed_title,
                    description=response_embed_description,
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=response_embed)

        else:
            channel_object, created = await objects.get_or_create(
                StaffLogChannel,
                guild_id=ctx.guild.id,
                defaults={
                    'channel_id': channel.id,
                    'enabled': True
                }
            )
            if created:
                response_embed = discord.Embed(
                    title="Staff log is now enabled",
                    description=f"The logging channel was set to {channel.mention}.",
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=response_embed)
            else:
                channel_object.channel_id = channel.id
                channel_object.enabled = True
                await objects.update(channel_object, only=('channel_id', 'enabled'))

                response_embed = discord.Embed(
                    title="Staff log is now enabled",
                    description=f"Staff logging was successfully enabled in {channel.mention}",
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=response_embed)

    @log_.command(aliases=['off'])
    async def disable(self, ctx):
        """
        Disable the staff log on the given guild.
        You can re-enable it at any time by using
        the `enable` command.
        """

        try:
            channel_object = await objects.get(
                StaffLogChannel,
                guild_id=ctx.guild.id
            )
        except DoesNotExist:
            error_embed = discord.Embed(
                title="Failed to disable staff log",
                description="There is no staff log channel set on this guild.",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)
        else:
            if channel_object.enabled:
                channel_object.enabled = False
                await objects.update(channel_object, only=['enabled'])

                response_embed = discord.Embed(
                    title="Successfully disabled staff log",
                    description="If you wish to re-enable it, use the `enable` command.",
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=response_embed)
            else:
                error_embed = discord.Embed(
                    title="Failed to disable staff log",
                    description="Staff log is already disabled. Use `enable` to enable it.",
                    colour=discord.Colour.red()
                )
                await ctx.send(embed=error_embed)
