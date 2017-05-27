import asyncio
import dataset
import discord

from discord.ext import commands
from stuf import stuf

guild_data_table = dataset.connect('sqlite:///data/guilds.db', row_type=stuf)


class Roles:
    """Commands for assigning, removing, and modifying Roles."""
    def __init__(self, bot):
        self.bot = bot
        self._role_table = guild_data_table['roles']

    @commands.group()
    @commands.guild_only()
    async def role(self, ctx):
        """Contains sub-commands for modifying Roles."""

    @staticmethod
    async def _role_checks(ctx, role, name):
        # Helper function to perform some checks before modifying a Role
        # Returns False is the Role does not exist or cannot be modified by the Bot, True otherwise.
        if role is None:
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(), title=f'No role named `{name}` found.'))
            return False
            # Check if the Bot has proper permissions to modify the Role
        elif ctx.me.highest_role <= role:
            err_msg = 'The Bot cannot modify his own Role or any Roles above him in the hierarchy.'
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(), title=err_msg))
            return False
        return True

    @role.command(name='asar', alias='msa')
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def make_self_assignable(self, ctx, *, name: str):
        """Makes the given role self-assignable for Members."""
        role = discord.utils.find(ctx.guild.roles, lambda r: r.name.lower() == name.lower())
        if self._role_checks(ctx, role, name):
            # Check if role is already self-assignable
            if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'Role `{role.name}` is already self-assignable.'))
            else:
                self._role_table.insert(dict(guild_id=ctx.guild.id, role_name=role.name, role_id=role.id))
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Role `{role.name}` is now self-assignable.'))

    @role.command(name='rsar', alias='usa')
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def unmake_self_assignable(self, ctx, *, name: str):
        """Removes the given Role from the self-assignable roles."""
        role = discord.utils.find(ctx.guild.roles, lambda r: r.name.lower() == name.lower())
        if self._role_checks(ctx, role, name):
            if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                self._role_table.delete(guild_id=ctx.guild.id, role_name=role.name)
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Role `{role.name}` is no longer self-assignable.'))
            else:
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'Role `{name}` is not self-assignable.'))




def setup(bot):
    bot.add_cog(Roles(bot))
