import logging

import discord
from discord.ext import commands

from bolt.constants import MAIN_COGS_BASE_PATH


log = logging.getLogger(__name__)


class Admin:
    """Contains Commands for the Administration of the Bot."""

    def __init__(self, bot):
        self.bot = bot
        log.debug('Loaded Cog Admin.')

    @staticmethod
    def __unload():
        log.debug('Unloaded Cog Admin.')

    @commands.group(invoke_without_command=True, aliases=['cog'])
    @commands.is_owner()
    async def cogs(self, ctx):
        """Cog management commands.

        When invoked without a subcommand, returns a list of loaded cogs.
        """

        await ctx.invoke(self.cogs_loaded)

    @cogs.command(name='load')
    @commands.is_owner()
    async def cogs_load(self, ctx, extension_name: str):
        """Load the specified cog."""

        if extension_name.title() in self.bot.cogs:
            error_embed = discord.Embed(
                title=f"Failed to load Cog `{extension_name}`:",
                description="Cog is already loaded",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)

        else:
            try:
                self.bot.load_extension(MAIN_COGS_BASE_PATH + extension_name)
            except ImportError as err:
                error_embed = discord.Embed(
                    title=f"Failed to load Cog `{extension_name}`:",
                    description=str(err),
                    colour=discord.Colour.red()
                )
                await ctx.send(embed=error_embed)
            else:
                loaded_cog_embed = discord.Embed(
                    title=f"Loaded Cog `{extension_name}`!",
                    colour=discord.Colour.green()
                )
                await ctx.send(embed=loaded_cog_embed)

    @cogs.command(name='unload')
    @commands.is_owner()
    async def cogs_unload(self, ctx, extension_name: str):
        """Unload the specified cog."""

        if extension_name.title() not in self.bot.cogs:
            error_embed = discord.Embed(
                title=f"Failed to unload Cog `{extension_name}`:",
                description="Cog is not loaded",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)

        else:
            self.bot.unload_extension(MAIN_COGS_BASE_PATH + extension_name)
            unloaded_cog_embed = discord.Embed(
                title=f"Unloaded Cog `{extension_name}`!",
                colour=discord.Colour.green()
            )
            await ctx.send(embed=unloaded_cog_embed)

    @cogs.command(name='loaded')
    @commands.is_owner()
    async def cogs_loaded(self, ctx):
        """List loaded Cogs."""

        loaded_cogs_embed = discord.Embed(
            title=f"Loaded Cogs (`{len(self.bot.cogs)}` total)",
            description='\n'.join(f"• {cog}" for cog in sorted(self.bot.cogs)),
            colour=discord.Colour.blurple()
        )
        await ctx.send(embed=loaded_cogs_embed)

    @commands.command()
    @commands.is_owner()
    async def shutdown(self, ctx):
        """Shutdown the bot."""

        await ctx.send(embed=discord.Embed(description='Shutting down...'))
        await self.bot.close()

    @commands.command(name='setplaying')
    @commands.is_owner()
    async def set_playing(self, _, *, new_status: str):
        """Set the playing status of the game."""

        await self.bot.change_presence(activity=discord.Game(new_status))

    @commands.command(name='setnick')
    @commands.is_owner()
    async def set_nick(self, ctx, *, nick):
        """Set the nickname for the bot on the current guild."""

        await ctx.guild.me.edit(nick=nick)

    @commands.command(name='setname')
    @commands.is_owner()
    async def set_user_name(self, _, *, username):
        """Set the bot's username."""

        await self.bot.user.edit(username=username)

    @commands.command()
    @commands.is_owner()
    async def guilds(self, ctx):
        """Returns a list of all Guilds that the Bot can see."""

        await ctx.send(embed=discord.Embed(
            title=f'Guilds ({sum(1 for _ in self.bot.guilds)} total)',
            description=', '.join(f"{g} (`{g.id}`)" for g in self.bot.guilds),
            colour=discord.Colour.blue()
        ))

    @commands.command(name='getguild')
    @commands.is_owner()
    async def get_guild(self, ctx, guild_id: int):
        """Return information about the given guild ID."""

        guild = self.bot.get_guild(guild_id)
        if guild is not None:
            info_embed = discord.Embed(
                title=f"{guild} (`{guild.id}`)",
                colour=discord.Colour.blurple(),
                timestamp=guild.me.joined_at
            ).add_field(
                name="Total Members",
                value=str(guild.member_count)
            ).add_field(
                name="Total roles",
                value=str(len(guild.roles))
            ).set_author(
                name=f"{guild.owner} ({guild.owner.id})",
                icon_url=guild.owner.avatar_url
            ).set_footer(
                text="Joined at"
            )

            if guild.icon_url:
                info_embed.set_thumbnail(url=guild.icon_url)

            await ctx.send(embed=info_embed)
        else:
            error_embed = discord.Embed(
                title="Cannot obtain guild information",
                description=f"Failed to find a guild with the ID `{guild_id}`.",
                colour=discord.Colour.red()
            )
            await ctx.send(embed=error_embed)
