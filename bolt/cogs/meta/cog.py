import logging
from datetime import datetime

import discord
import humanize
from discord.ext import commands


log = logging.getLogger(__name__)


class Meta:
    """Meta Commands, providing information about various things."""

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog Meta.')

    @staticmethod
    def __unload():
        log.debug('Unloaded Cog Meta.')

    @commands.command()
    async def stats(self, ctx):
        """Displays information and statistics about the Bot."""

        average_members = sum(g.member_count for g in self.bot.guilds) // len(self.bot.guilds)
        response = discord.Embed()
        response.colour = discord.Colour.blue()
        response.set_thumbnail(
            url=self.bot.user.avatar_url
        ).set_author(
            name='Made by Volcyy#2359',
            icon_url=(await self.bot.application_info()).owner.avatar_url
        ).add_field(
            name='Guilds',
            value=(f'**Total**: {sum(1 for _ in self.bot.guilds)}\n'
                   f'**Avg. Members**: {average_members}\n'
                   f'**Shards**: {self.bot.shard_count}')
        ).add_field(
            name='Users',
            value=(f'**Total**: {sum(1 for _ in self.bot.get_all_members())}\n'
                   f'**Unique**: {len(set(self.bot.get_all_members()))}')
        )

        await ctx.send(embed=response)

    @commands.command()
    async def guilds(self, ctx):
        """Returns a list of all Guilds that the Bot can see."""

        await ctx.send(embed=discord.Embed(
            title=f'Guilds ({sum(1 for _ in self.bot.guilds)} total)',
            description=', '.join(g.name for g in self.bot.guilds),
            colour=discord.Colour.blue()
        ))

    @commands.command(aliases=['member'])
    @commands.guild_only()
    async def minfo(self, ctx, *, member: discord.Member=None):
        """Displays information about yourself or a Member."""

        if member is None:
            member = ctx.message.author

        await ctx.send(embed=discord.Embed(
            title=f"{member} (`{member.id}`)",
            colour=member.colour
        ).add_field(
            name="Roles",
            value=', '.join(m.mention for m in member.roles[1:]) or "No Roles"
        ).add_field(
            name="Joined this Guild",
            value=f"{member.joined_at.strftime('%d.%m.%y %H:%M')} "
                  f"({humanize.naturaldelta(datetime.utcnow() - member.joined_at)})"
        ).add_field(
            name="Joined Discord",
            value=f"{member.created_at.strftime('%d.%m.%y %H:%M')} "
                  f"({humanize.naturaldelta(datetime.utcnow() - member.created_at)})"
        ).set_thumbnail(
            url=member.avatar_url
        ))

    @commands.command(aliases=['guild'])
    @commands.guild_only()
    async def ginfo(self, ctx):
        """Displays information about the guild the command is invoked on."""

        info_embed = discord.Embed(
            title=f"{ctx.guild.name} (`{ctx.guild.id}`)",
            colour=discord.Colour.blurple()
        ).add_field(
            name="Statistics",
            value=f"Total Emojis: {len(ctx.guild.emojis)}\n"
                  f"Total Members: {ctx.guild.member_count}\n"
                  f"Total Roles: {len(ctx.guild.roles)}"
        ).add_field(
            name="Owner",
            value=ctx.guild.owner.mention
        )
        info_embed.set_footer(text="Creation date")
        info_embed.timestamp = ctx.guild.created_at

        if ctx.guild.icon_url:
            info_embed.set_thumbnail(url=ctx.guild.icon_url)

        if ctx.guild.features:
            info_embed.add_field(
                name='Features',
                value=', '.join(f'`{feature}`' for feature in ctx.guild.features)
            )

        await ctx.send(embed=info_embed)
