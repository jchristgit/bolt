import discord
from discord.ext import commands
from peewee import DoesNotExist

from bolt.database import objects
from .models import StaffLogChannel


class StaffLog:
    """
    Commands that help configuring a staff log.
    Kind of like the audit log, but lasts as long
    as the bot's messages stay there and logs more events.
    """

    def __init__(self, bot):
        self.bot = bot

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
                if not channel_object.enabled:
                    channel_object.enabled = True
                    await objects.update(channel_object, only=['enabled'])

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
