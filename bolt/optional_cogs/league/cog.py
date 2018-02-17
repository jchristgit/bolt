import discord
from discord.ext import commands

from ...bot.config import CONFIG
from ..base import OptionalCog
from .api import LeagueAPIClient
from .models import champion as champion_model


class League(OptionalCog):
    """Contains League of Legends-related commands."""

    RESTRICTED = False

    def __init__(self, bot):
        self.bot = bot
        self.league_client = LeagueAPIClient(CONFIG['league']['key'])

    @commands.group()
    @commands.guild_only()
    async def league(self, *_):
        pass

    @league.command(name="setchamp")
    @commands.has_permissions(manage_roles=True)
    async def set_champion(self, ctx, name: str):
        """
        Sets the champion to be associated with
        this Guild for tracking user mastery.
        """

        query = champion_model.select().where(champion_model.c.guild_id == ctx.guild.id)
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if exists:
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
                    title=f"Successfully associated Champion `{name}` with this Guild.",
                    colour=discord.Colour.green()
                ))
            else:
                await ctx.send(embed=discord.Embed(
                    title="Failed to set associated Champion:",
                    description=f"No champion named `{name}` was found.",
                    colour=discord.Colour.red()
                ))

    @league.command(name="rmchamp")
    @commands.has_permissions(manage_roles=True)
    async def remove_champion(self, ctx):
        """
        Removes the champion associated with a guild, if set.
        """

        query = champion_model.select().where(champion_model.c.guild_id == ctx.guild.id)
        result = await self.bot.db.execute(query)
        exists = await result.first() is not None

        if not exists:
            await ctx.send(embed=discord.Embed(
                title="Failed to disassociate champion:",
                description="This guild has no associated champion set.",
                colour=discord.Colour.red()
            ))
        else:
            query = champion_model.delete(champion_model.c.guild_id == ctx.guild.id)
            await self.bot.db.execute(query)
            await ctx.send(embed=discord.Embed(
                title="Successfully disassociated champion from this Guild.",
                colour=discord.Colour.green()
            ))
