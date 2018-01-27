import discord
from discord.ext import commands
from sqlalchemy import and_

from ..models import sar as sar_model


class Roles:
    """Commands for assigning, removing, and modifying Roles."""
    def __init__(self, bot):
        self.bot = bot
        print('Loaded Cog Roles.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Roles.')

    @commands.group()
    @commands.guild_only()
    async def role(self, ctx):
        """Contains sub-commands for modifying Roles."""

    @staticmethod
    def create_role_update_response(embed, success_desc, success, error_desc, error):
        if success:
            embed.add_field(
                name=success_desc,
                value=', '.join(success),
                inline=False
            )
        if error:
            embed.add_field(
                name=error_desc,
                value='\n'.join(error),
                inline=False
            )
        return embed

    async def is_self_assignable(self, role: discord.Role):
        query = sar_model.select().where(and_(sar_model.c.id == role.id, sar_model.c.guild_id == role.guild.id))
        result = await self.bot.db.execute(query)
        row = await result.first()
        return row is not None

    @role.command(name='asar', aliases=['msa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def make_self_assignable(self, ctx, *roles: discord.Role):
        """Makes the given role self-assignable for Members.

        This also works with a list of Roles, for example:
        `role asar "Member" "Guest" "Light Blue"`

        Alternatively, if you have changed the role name
        or done some other wizardry resulting in the bot
        not accepting the given roles, pass their IDs instead.
        """

        success, failed = [], []
        for role in roles:
            if await self.is_self_assignable(role):
                failed.append(f'• Role {role.mention} is already self-assignable.')
            elif role >= ctx.guild.me.top_role:
                failed.append(f'• Role {role.mention} is higher or as high in the role hierarchy than my top role.')
            else:
                query = sar_model.insert().values(id=role.id, name=role.name, guild_id=ctx.guild.id)
                await self.bot.db.execute(query)
                success.append(role.mention)

        await ctx.send(embed=self.create_role_update_response(discord.Embed(
            title=f'Updated Self-Assignable Roles',
            colour=discord.Colour.blue()
        ), 'Now Self-Assignable:', success, 'Errors:', failed))

    @role.command(name='rsar', aliases=['usa'])
    @commands.has_permissions(manage_roles=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def unmake_self_assignable(self, ctx, *roles: discord.Role):
        """Removes the given Role from the self-assignable roles."""

        success, failed = [], []
        for role in roles:
            if not await self.is_self_assignable(role):
                failed.append(f'• Role {role.mention} is not self-assignable.')
            else:
                query = sar_model.delete().where(and_(sar_model.c.id == role.id, sar_model.c.guild_id == ctx.guild.id))
                await self.bot.db.execute(query)
                success.append(role.mention)

        await ctx.send(embed=self.create_role_update_response(discord.Embed(
            title=f'Updated Self-Assignable Roles',
            colour=discord.Colour.blue()
        ), 'No longer self-assignable:', success, 'Errors:', failed))

    @commands.command(name='iam', aliases=['assign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def assign(self, ctx, *roles: discord.Role):
        """Assign self-assignable Roles to yourself.

        This supports passing a list of roles, for example
        `iam "Light Blue" "Member"`.
        """

        success, failed = [], []
        roles_to_add = []
        for role in roles:
            if not await self.is_self_assignable(role):
                failed.append(f'• {role.mention} is not self-assignable.')
            elif role in ctx.author.roles:
                failed.append(f'• You already have the {role.mention} Role.')
            else:
                roles_to_add.append(role)
                success.append(role.mention)

        await ctx.author.add_roles(*roles_to_add, reason='Self-assignable Roles')
        await ctx.send(embed=self.create_role_update_response(discord.Embed(
            title=f'Updated Roles for {ctx.author}',
            colour=discord.Colour.blue()
        ).set_thumbnail(
            url=ctx.author.avatar_url
        ), 'Gave you the following Roles:', success, 'Errors:', failed))

    @commands.command(name='iamn', aliases=['unassign'])
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    async def un_assign(self, ctx, *roles: discord.Role):
        """Remove self-assignable Roles from yourself."""

        success, failed = [], []
        roles_to_remove = []
        for role in roles:
            if not await self.is_self_assignable(role):
                failed.append(f'• {role.mention} is not self-assignable.')
            elif role not in ctx.author.roles:
                failed.append(f'• You do not have the {role.mention} Role.')
            else:
                roles_to_remove.append(role)
                success.append(role.mention)

        await ctx.author.remove_roles(*roles_to_remove, reason='Self-assignable Roles')
        await ctx.send(embed=self.create_role_update_response(discord.Embed(
            title=f'Updated Roles for {ctx.author}',
            colour=discord.Colour.blue()
        ).set_thumbnail(
            url=ctx.author.avatar_url
        ), 'Removed the following Roles from you:', success, 'Errors:', failed))

    @commands.command(name='lsar')
    @commands.guild_only()
    async def list_self_assignable_roles(self, ctx):
        """Show all self-assignable Roles on this Guild."""

        query = sar_model.select().where(sar_model.c.guild_id == ctx.guild.id).order_by(sar_model.c.name)
        result = await self.bot.db.execute(query)
        roles = await result.fetchall()

        if not roles:
            await ctx.send(embed=discord.Embed(
                description='This Guild has no self-assignable Roles set.',
                colour=discord.Colour.red(),
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title='Self-assignable Roles',
                description=', '.join(r.name for r in roles),
                colour=discord.Colour.blue()
            ))

    @commands.command(name='rinfo')
    @commands.guild_only()
    async def role_info(self, ctx, role: discord.Role):
        """Gives information about a Role."""

        members = ', '.join(r.name for r in role.members)
        response = discord.Embed(
            title=f'__Role Information for {role.mention}__',
            colour=role.colour
        ).add_field(
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
            value=role.created_at.strftime('%d %B %Y')
        ).add_field(
            name='Permission Bitfield',
            value=role.permissions.value
        ).add_field(
            name='Member Count',
            value=len(role.members)
        ).add_field(
            name='Members',
            value=(members if len(members) < 1024 else 'Too many Members to display.') or 'None'
        )
        await ctx.send(embed=response)

    @commands.command(name='roles', aliases=['aroles'])
    @commands.guild_only()
    async def all_roles(self, ctx):
        """Lists all Roles on this Server in the order of hierarchy."""

        await ctx.send(embed=discord.Embed(
            title=f'All Roles on {ctx.guild.name}',
            description=', '.join(
                f'{r.mention} ({sum(1 for _ in r.members)})' for r in sorted(
                    ctx.guild.roles, key=lambda r: r.position, reverse=True
                ) if r.name != '@everyone'
            ),
            colour=discord.Colour.blue()
        ).set_thumbnail(
            url=ctx.guild.icon_url
        ).set_footer(
            text='Run `rinfo <name>` to get detailed information about a Role'
        ))


def setup(bot):
    bot.add_cog(Roles(bot))
