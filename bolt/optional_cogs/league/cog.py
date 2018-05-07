import io
from operator import itemgetter
from typing import Optional

import discord
import peewee_async
from discord.ext import commands
from peewee import DoesNotExist

from bolt.bot.config import CONFIG
from bolt.database import objects
from bolt.optional_cogs.base import OptionalCog
from .api import LeagueAPIClient
from .converters import Region
from .models import Champion, PermittedRole, Summoner
from .util import has_permitted_role


TABLE_HEADER = ("\# | **Summoner Name** | **Server** | **Points**\n"
                "--:|--|--|--\n")


class League(OptionalCog):
    """Contains League of Legends-related commands."""

    RESTRICTED = False

    def __init__(self, bot):
        self.bot = bot
        self.league_client = LeagueAPIClient(CONFIG['league']['key'])

    async def get_champ_id(self, guild_id: int) -> Optional[int]:
        try:
            champion = await objects.get(
                Champion,
                Champion.guild_id == guild_id
            )
        except DoesNotExist:
            return None
        return champion.id

    @commands.group(aliases=['l'])
    @commands.guild_only()
    async def league(self, *_):
        pass

    @league.command(name="setpermrole")
    @commands.has_permissions(manage_roles=True)
    async def set_permitted_role(self, ctx, role: discord.Role):
        """
        Sets the role which members must have
        to modify any settings for this Guild.
        """

        _, created = await objects.get_or_create(
            PermittedRole,
            guild_id=ctx.guild.id,
            defaults={
                'id': role.id
            }
        )

        if created:
            await ctx.send(embed=discord.Embed(
                description=f"Successfully set permitted role to {role.mention}.",
                colour=discord.Colour.green()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title="Failed to set permitted role:",
                description="A role is already set. Remove it using `rmpermrole`.",
                colour=discord.Colour.red()
            ))

    @league.command(name="rmpermrole")
    @commands.has_permissions(manage_roles=True)
    async def remove_permitted_role(self, ctx):
        """
        Remove any role set set previously with setpermrole.
        """

        try:
            role = await objects.get(
                PermittedRole,
                PermittedRole.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title="Cannot remove permitted role:",
                description="No permitted role is set.",
                colour=discord.Colour.red()
            ))
        else:
            await objects.delete(role)
            await ctx.send(embed=discord.Embed(
                description="Successfully removed permitted role",
                colour=discord.Colour.green()
            ))

    @league.command(name="setchamp")
    @commands.check(has_permitted_role)
    async def set_champion(self, ctx, name: str):
        """
        Sets the champion to be associated with
        this Guild for tracking user mastery.
        """

        if await self.get_champ_id(ctx.guild.id) is not None:
            await ctx.send(embed=discord.Embed(
                title="Failed to set associated Champion:",
                description="A champion is already set. Remove it using `rmchamp`.",
                colour=discord.Colour.red()
            ))
        else:
            champion_data = await self.league_client.get_champion(name)
            if champion_data is not None:
                await objects.create(
                    Champion,
                    id=champion_data['id'],
                    guild_id=ctx.guild.id
                )
                await ctx.send(embed=discord.Embed(
                    description=f"Successfully associated Champion `{name}` with this Guild.",
                    colour=discord.Colour.green()
                ))
            else:
                await ctx.send(embed=discord.Embed(
                    title="Failed to set associated Champion:",
                    description=f"No champion named `{name}` was found.",
                    colour=discord.Colour.red()
                ))

    @league.command(name="rmchamp")
    @commands.check(has_permitted_role)
    async def remove_champion(self, ctx):
        """
        Removes the champion associated with a guild, if set.
        """

        try:
            guild_champion = await objects.get(
                Champion,
                Champion.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title="Failed to disassociate champion:",
                description="This guild has no associated champion set.",
                colour=discord.Colour.red()
            ))
        else:
            await objects.delete(guild_champion)
            await ctx.send(embed=discord.Embed(
                description="Successfully disassociated champion from this Guild.",
                colour=discord.Colour.green()
            ))

    @league.command(name="adduser")
    @commands.check(has_permitted_role)
    async def add_user(self, ctx, region: Region, *, name: str):
        """
        Add a user to the mastery leaderboard for this guild.
        """

        summoner_data = await self.league_client.get_summoner(region, name)
        if summoner_data is None:
            return await ctx.send(embed=discord.Embed(
                title="Failed to add User:",
                description=f"No user named `{name}` in `{region}` found.",
                colour=discord.Colour.red()
            ))

        try:
            await objects.get(
                Summoner,
                Summoner.id == summoner_data['id'],
                Summoner.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            champ_id = await self.get_champ_id(ctx.guild.id)
            if champ_id is None:
                await ctx.send(embed=discord.Embed(
                    title="Failed to add User:",
                    description="This guild needs to have a champion associated with it first.",
                    colour=discord.Colour.red()
                ))
            elif await self.league_client.get_mastery(region, summoner_data['id'], champ_id) is None:
                await ctx.send(embed=discord.Embed(
                    title="Failed to add User:",
                    description="The user was found, but I cannot get any mastery data.",
                    colour=discord.Colour.red()
                ))
            else:
                await objects.create(
                    Summoner,
                    id=summoner_data['id'],
                    guild_id=ctx.guild.id,
                    region=region
                )
                await ctx.send(embed=discord.Embed(
                    description=f"Successfully added `{name}` to the database.",
                    colour=discord.Colour.green()
                ))
        else:
            await ctx.send(embed=discord.Embed(
                title="Failed to add User:",
                description=f"`{name}` in `{region}` is already added.",
                colour=discord.Colour.red()
            ))

    @league.command(name="rmuser")
    @commands.check(has_permitted_role)
    async def remove_user(self, ctx, region: Region, *, name: str):
        """
        Removes a user from the mastery leaderboard for this guild.
        """

        summoner_data = await self.league_client.get_summoner(region, name)
        if summoner_data is None:
            return await ctx.send(embed=discord.Embed(
                title="Failed to remove user:",
                description=f"`{name}` in `{region}` was not found.",
                colour=discord.Colour.red()
            ))

        try:
            summoner = await objects.get(
                Summoner,
                Summoner.id == summoner_data['id'],
                Summoner.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title="Failed to remove user:",
                description=f"`{name}` in `{region}` is not in the database.",
                colour=discord.Colour.red()
            ))
        else:
            await objects.delete(summoner)
            await ctx.send(embed=discord.Embed(
                description=f"Successfully removed `{name}` from the database.",
                colour=discord.Colour.green()
            ))

    @league.command(name="buildtable")
    @commands.check(has_permitted_role)
    async def build_table(self, ctx):
        """
        Builds a table with the added users on this
        Guild along with their mastery scores and regions
        and outputs it in valid Markdown.
        """

        champion_id = await self.get_champ_id(ctx.guild.id)

        if champion_id is None:
            await ctx.send(embed=discord.Embed(
                title="Cannot build table:",
                description="This command requires the champion to be set with `setchamp`.",
                colour=discord.Color.red()
            ))
        else:
            summoners = await peewee_async.execute(
                Summoner.select()
                        .where(Summoner.guild_id == ctx.guild.id)
            )

            last_update_percent = 0.00
            masteries = []
            progress_msg = await ctx.send(":bar_chart: **Working...** 0% done.")

            for idx, summ in enumerate(summoners):
                mastery_score = await self.league_client.get_mastery(summ.region, summ.id, champion_id)
                summoner_data = await self.league_client.get_summoner(summ.region, summ.id)

                progress = idx / len(summoners)
                if progress >= last_update_percent + 0.05:
                    await progress_msg.edit(content=f":bar_chart: **Working...** {progress * 100:3.2f}% done.")
                    last_update_percent = progress

                masteries.append((summoner_data['name'], summ.region, mastery_score))

            with io.StringIO(TABLE_HEADER) as result:
                result.seek(len(TABLE_HEADER))
                for idx, (name, region, score) in enumerate(sorted(masteries, key=itemgetter(2), reverse=True)):
                    result.write(f"{idx + 1} | {name} | {region} | {score:,}\n")

                with io.BytesIO(bytes(result.getvalue(), encoding='utf-8')) as raw_result:
                    await progress_msg.delete()
                    await ctx.send(f"Done. Total entries: {len(masteries)}.",
                                   file=discord.File(raw_result, filename="table.md"))
