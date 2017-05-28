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
        elif name == '@everyone':
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(), title='That is not a valid Role name.'))
            return False
        # Check if the Bot has proper permissions to modify the Role
        elif ctx.me.top_role <= role:
            err_msg = 'The Bot cannot modify his own Role or any Roles above him in the hierarchy.'
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(), title=err_msg))
            return False
        return True

    @role.command(name='asar', aliases=['msa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def make_self_assignable(self, ctx, *, name: str):
        """Makes the given role self-assignable for Members."""
        role = discord.utils.find(lambda r: r.name.lower() == name.lower(), ctx.guild.roles)
        if await self._role_checks(ctx, role, name):
            # Check if role is already self-assignable
            if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'Role `{role.name}` is already self-assignable.'))
            else:
                self._role_table.insert(dict(guild_id=ctx.guild.id, role_name=role.name, role_id=role.id))
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Role `{role.name}` is now self-assignable.'))

    @role.command(name='rsar', aliases=['usa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def unmake_self_assignable(self, ctx, *, name: str):
        """Removes the given Role from the self-assignable roles."""
        role = discord.utils.find(lambda r: r.name.lower() == name.lower(), ctx.guild.roles)
        if await self._role_checks(ctx, role, name):
            if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                self._role_table.delete(guild_id=ctx.guild.id, role_name=role.name)
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Role `{role.name}` is no longer self-assignable.'))
            else:
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'Role `{name}` is not self-assignable.'))

    async def _perform_self_assignable_roles_checks(self, ctx, role):
        # Checks if a role exist and whether it's not self-assignable
        if role is None:
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                               title=f'This Guild does not have any role called `{name}`.'))
            return False
        elif not self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
            await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                               title=f'Role `{role.name}` is not self-assignable.'))
            return False
        return True

    @commands.command(name='iam', aliases=['assign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def assign(self, ctx, *, name: str):
        """Assign a self-assignable Role to yourself."""
        role = discord.utils.find(lambda r: r.name.lower() == name.lower(), ctx.guild.roles)
        if self._perform_self_assignable_roles_checks(ctx, role):
            if role in ctx.author.roles:
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'You already have the `{role.name}` Role.'))
            else:
                await ctx.author.add_roles(role, reason='Self-assignable Role')
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Gave you the `{role.name}` Role!'))

    @commands.command(name='iamn', aliases=['unassign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def un_assign(self, ctx, *, name: str):
        """Remove a self-assignable Role from yourself."""
        role = discord.utils.find(lambda r: r.name.lower() == name.lower(), ctx.guild.roles)
        if self._perform_self_assignable_roles_checks(ctx, role):
            if role not in ctx.author.roles:
                await ctx.send(embed=discord.Embed(colour=discord.Colour.red(),
                                                   title=f'You do not have the `{role.name}` Role.'))
            else:
                await ctx.author.remove_roles(role, reason='Self-assignable Role')
                await ctx.send(embed=discord.Embed(colour=discord.Colour.green(),
                                                   title=f'Removed the `{role.name}` Role from you!'))

    @commands.command(name='lsar')
    @commands.guild_only()
    async def list_self_assignable(self, ctx):
        """Show all self-assignable Roles on this Guild."""
        title = 'Self-Assignable Roles'
        amount = self._role_table.count(guild_id=ctx.guild.id)
        if amount == 0:
            await ctx.send(embed=discord.Embed(colour=discord.Colour.dark_blue(), title=title,
                                               description='This Guild has no self-assignable Roles set.'))
        else:
            description = ', '.join([x.role_name for x in self._role_table.find(guild_id=ctx.guild.id)])
            await ctx.send(embed=discord.Embed(colour=discord.Colour.dark_blue(), title=title,
                                               description=description))





def setup(bot):
    bot.add_cog(Roles(bot))
