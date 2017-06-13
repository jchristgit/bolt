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
        print('Loaded Cog Roles.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Roles.')

    @commands.group()
    @commands.guild_only()
    async def role(self, ctx):
        """Contains sub-commands for modifying Roles."""

    @staticmethod
    async def _role_checks(ctx, role, name):
        # Helper function to perform some checks before modifying a Role
        # Returns False is the Role does not exist or cannot be modified by the Bot, True otherwise.
        if role is None:
            return False, f'• No Role named `{name}` found.'
        elif name == '@everyone' or name == '@here':
            return False, '• `{name}` is not a valid Role name.'
        # Check if the Bot has proper permissions to modify the Role
        elif ctx.me.top_role <= role:
            return False, '• Cannot modify `{name}` since it his his own Role or above him in the hierarchy.'
        return True,

    @role.command(name='asar', aliases=['msa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def make_self_assignable(self, ctx, *, role_names: str):
        """Makes the given role self-assignable for Members.

        This also works with a comma-separated list of Roles, for example
        `role asar Member, Guest, Blue
        """
        success, failed = [], []
        for role_name in role_names.split(', '):
            role = discord.utils.find(lambda r: r.name.lower() == role_name.strip().lower(), ctx.guild.roles)
            check_result = await self._role_checks(ctx, role, role_name)
            if check_result[0]:
                # Check if role is already self-assignable
                if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                    failed.append(f'• Role `{role.name}` is already self-assignable.')
                else:
                    self._role_table.insert(dict(guild_id=ctx.guild.id, role_name=role.name, role_id=role.id))
                    success.append(role.name)
            else:
                failed.append(check_result[1])

        await ctx.send(embed=discord.Embed(
            title=f'Updated Self-Assignable Roles',
            colour=discord.Colour.blue()
        ).add_field(
            name='Errors:',
            value='\n'.join(failed) or 'No Errors <:chimp:314710560279232512>'
        ).add_field(
            name='Now self-assignable:',
            value=', '.join(success) or 'No Roles updated here <:sadpanda:319417001485533188>'
        ))

    @role.command(name='rsar', aliases=['usa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def unmake_self_assignable(self, ctx, *, role_names: str):
        """Removes the given Role from the self-assignable roles."""
        success, failed = [], []
        for role_name in role_names.split(', '):
            role = discord.utils.find(lambda r: r.name.lower() == role_name.strip().lower(), ctx.guild.roles)
            check_result = await self._role_checks(ctx, role, role_name)
            if check_result[0]:
                if self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
                    self._role_table.delete(
                        guild_id=ctx.guild.id,
                        role_name=role.name
                    )
                    success.append(role.name)
                else:
                    failed.append(f'• Role `{role.name}` is not self-assignable.')
            else:
                failed.append(check_result[1])

        await ctx.send(embed=discord.Embed(
            title=f'Updated Self-Assignable Roles',
            colour=discord.Colour.blue()
        ).add_field(
            name='Errors:',
            value='\n'.join(failed) or 'No Errors <:chimp:314710560279232512>'
        ).add_field(
            name='No longer self-assignable:',
            value=', '.join(success) or 'No Roles updated here <:sadpanda:319417001485533188>'
        ))

    @commands.command()
    async def colours(self, ctx):
        """Links to colour pickers for getting role colours."""
        await ctx.send(embed=discord.Embed(
            title='Colour Pickers',
            description='Make sure to get the **hex value** of the Colour you want, '
                        'which is usually prefixed with `#`!\n'
                        '• <https://duckduckgo.com/?q=color%20picker&ia=answer>\n'
                        '• <https://www.webpagefx.com/web-design/color-picker/>',
            colour=discord.Colour.blue()
        ))

    async def _perform_self_assignable_roles_checks(self, ctx, role, name):
        # Checks if a role exist and whether it's not self-assignable
        if role is None:
            return False, f'• This Guild does not have any role called `{name}`.'
        elif not self._role_table.find_one(guild_id=ctx.guild.id, role_name=role.name):
            return False, f'• Role `{role.name}` is not self-assignable.'
        return True,

    @commands.command(name='iam', aliases=['assign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def assign(self, ctx, *, role_names: str):
        """Assign self-assignable Roles to yourself.

        This supports passing a comma-separated List of Roles, for example
        `iam Blue, Member, Guest`.
        """
        success, failed, to_remove = [], [], []
        for role_name in role_names.split(', '):
            role = discord.utils.find(lambda r: r.name.lower() == role_name.strip().lower(), ctx.guild.roles)
            checks = await self._perform_self_assignable_roles_checks(ctx, role, role_name)
            if checks[0]:
                if role in ctx.author.roles:
                    failed.append(f'• You already have the `{role.name}` Role.')
                else:
                    to_remove.append(role)
                    success.append(role.name)
            else:
                failed.append(checks[1])

        await ctx.author.add_roles(to_remove, reason='Self-assignable Roles')
        await ctx.send(embed=discord.Embed(
            title=f'Updated Roles for {ctx.author}',
            colour=discord.Colour.blue()
        ).set_thumbnail(
            url=ctx.author.avatar_url
        ).add_field(
            name='Errors:',
            value='\n'.join(failed) or 'No Errors <:chimp:314710560279232512>'
        ).add_field(
            name='Gave you the following Roles:',
            value=', '.join(success) or 'None <:sadpanda:319417001485533188>'
        ))

    @commands.command(name='iamn', aliases=['unassign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def un_assign(self, ctx, *, role_names: str):
        """Remove self-assignable Roles from yourself."""
        success, failed, to_remove = [], [], []
        for role_name in role_names.split(', '):
            role = discord.utils.find(lambda r: r.name.lower() == role_name.strip().lower(), ctx.guild.roles)
            checks = await self._perform_self_assignable_roles_checks(ctx, role, role_name)
            if checks[0]:
                if role not in ctx.author.roles:
                    failed.append(f'• You do not have the `{role.name}` Role.')
                else:
                    to_remove.append(role)
                    success.append(role.name)
            else:
                failed.append(checks[1])

        await ctx.author.remove_roles(to_remove, reason='Self-assignable Roles')
        await ctx.send(embed=discord.Embed(
            title=f'Updated Roles for {ctx.author}',
            colour=discord.Colour.blue()
        ).set_thumbnail(
            url=ctx.author.avatar_url
        ).add_field(
            name='Errors:',
            value='\n'.join(failed) or 'No Errors <:chimp:314710560279232512>'
        ).add_field(
            name='Removed the following Roles from you:',
            value=', '.join(success) or 'None <:sadpanda:319417001485533188>'
        ))

    @commands.command(name='lsar')
    @commands.guild_only()
    async def list_self_assignable(self, ctx):
        """Show all self-assignable Roles on this Guild."""
        title = 'Self-Assignable Roles'
        amount = self._role_table.count(guild_id=ctx.guild.id)
        if amount == 0:
            await ctx.send(embed=discord.Embed(
                title=title,
                description='This Guild has no self-assignable Roles set.',
                colour=discord.Colour.blue(),
            ))
        else:
            description = ', '.join(x.role_name for x in self._role_table.find(guild_id=ctx.guild.id))
            await ctx.send(embed=discord.Embed(
                title=title,
                description=description,
                colour=discord.Colour.blue()
            ))

    @commands.command(name='rinfo')
    @commands.guild_only()
    async def role_info(self, ctx, *, role_name: str):
        """Gives information about a Role."""
        role = discord.utils.find(lambda r: r.name.lower() == role_name.lower(), ctx.guild.roles)
        if role is None:
            await ctx.send(embed=discord.Embed(
                title=f'No Role named `{role_name}` found',
                colour=discord.Colour.red()
            ))
        else:
            response = discord.Embed()
            response.title = f'__Role Information for `{role.name}`__'
            response.add_field(
                name='ID',
                value=role.id
            ).add_field(
                name='Colour Hex',
                value=role.colour
            ).add_field(
                name='Position',
                value=role.position
            ).add_field(
                name='Creation Date',
                value=role.created_at
            ).add_field(
                name='Permission Bitfield',
                value=role.permissions.value
            ).colour = role.colour

            members_in_role = len(role.members)
            if members_in_role == 0:
                response.add_field(
                    name='Member Count',
                    value='0'
                )
            else:
                response.add_field(
                    name='Member Count',
                    value=str(members_in_role)
                ).add_field(
                    name='Members',
                    value=', '.join(r.name for r in role.members)
                )
            await ctx.send(embed=response)


def setup(bot):
    bot.add_cog(Roles(bot))
