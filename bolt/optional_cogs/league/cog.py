import io
from operator import itemgetter
from typing import Optional

import discord
from discord.ext import commands
from sqlalchemy import and_

from ...bot.config import CONFIG
from ..base import OptionalCog
from .api import LeagueAPIClient
from .converters import Region
from .models import (
    champion as champion_model,
    permitted_role as perm_role_model,
    summoner as summoner_model
)
from .util import has_permission_role


TABLE_HEADER = ("\# | **Summoner Name** | **Server** | **Points**\n"
                "--:|--|--|--\n")


class League(OptionalCog):
    """Contains League of Legends-related commands."""

    RESTRICTED = False

    def __init__(self, bot):
        self.bot = bot
        self.league_client = LeagueAPIClient(CONFIG['league']['key'])

    async def get_champ_id(self, guild_id: int) -> Optional[int]:
        query = champion_model.select().where(champion_model.c.guild_id == guild_id)
        result = await self.bot.db.execute(query)
        result = await result.first()
        if result is not None:
            return result['champion_id']
        return None

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

        query = perm_role_model.select().where(perm_role_model.c.guild_id == ctx.guild.id)
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if exists:
            await ctx.send(embed=discord.Embed(
                title="Failed to set permitted role:",
                description="A role is already set. Remove it using `rmpermrole`.",
                colour=discord.Colour.red()
            ))
        else:
            query = perm_role_model.insert().values(id=role.id, guild_id=ctx.guild.id)
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                description=f"Successfully set permitted role to {role.mention}.",
                colour=discord.Colour.green()
            ))

    @league.command(name="rmpermrole")
    @commands.has_permissions(manage_roles=True)
    async def remove_permitted_role(self, ctx):
        """
        Remove any role set set previously with setpermrole.
        """

        query = perm_role_model.select().where(perm_role_model.c.guild_id == ctx.guild.id)
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if not exists:
            await ctx.send(embed=discord.Embed(
                title="Cannot remove permitted role:",
                description="No permitted role is set.",
                colour=discord.Colour.red()
            ))
        else:
            query = perm_role_model.delete(perm_role_model.c.guild_id == ctx.guild.id)
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                description="Successfully removed permitted role",
                colour=discord.Colour.green()
            ))

    @league.command(name="setchamp")
    @commands.check(has_permission_role)
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
                query = champion_model.insert().values(guild_id=ctx.guild.id, champion_id=champion_data['id'])
                await self.bot.db.execute(query)
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
    @commands.check(has_permission_role)
    async def remove_champion(self, ctx):
        """
        Removes the champion associated with a guild, if set.
        """

        if await self.get_champ_id(ctx.guild.id) is None:
            await ctx.send(embed=discord.Embed(
                title="Failed to disassociate champion:",
                description="This guild has no associated champion set.",
                colour=discord.Colour.red()
            ))
        else:
            query = champion_model.delete(champion_model.c.guild_id == ctx.guild.id)
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                description="Successfully disassociated champion from this Guild.",
                colour=discord.Colour.green()
            ))

    @league.command(name="adduser")
    @commands.check(has_permission_role)
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

        query = summoner_model.select().where(and_(
            summoner_model.c.id == summoner_data['id'],
            summoner_model.c.guild_id == ctx.guild.id
        ))
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if exists:
            await ctx.send(embed=discord.Embed(
                title="Failed to add User:",
                description=f"`{name}` in `{region}` is already added.",
                colour=discord.Colour.red()
            ))

        else:
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
                query = summoner_model.insert().values(
                    id=summoner_data['id'],
                    guild_id=ctx.guild.id,
                    region=region
                )
                await self.bot.db.execute(query)
                await ctx.send(embed=discord.Embed(
                    description=f"Successfully added `{name}` to the database.",
                    colour=discord.Colour.green()
                ))

    @league.command(name="rmuser")
    @commands.check(has_permission_role)
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

        query = summoner_model.select().where(and_(
            summoner_model.c.id == summoner_data['id'],
            summoner_model.c.guild_id == ctx.guild.id
        ))
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if not exists:
            await ctx.send(embed=discord.Embed(
                title="Failed to remove user:",
                description=f"`{name}` in `{region}` is not in the database.",
                colour=discord.Colour.red()
            ))
        else:
            query = summoner_model.delete(and_(
                summoner_model.c.id == summoner_data['id'],
                summoner_model.c.guild_id == ctx.guild.id
            ))
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                description=f"Successfully removed `{name}` from the database.",
                colour=discord.Colour.green()
            ))

    @league.command(name="buildtable")
    @commands.check(has_permission_role)
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
            query = summoner_model.select().where(summoner_model.c.guild_id == ctx.guild.id)
            result = await self.bot.db.execute(query)
            summoners = await result.fetchall()

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
