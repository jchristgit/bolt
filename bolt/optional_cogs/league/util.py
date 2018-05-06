from discord.ext.commands import CheckFailure
from peewee import DoesNotExist

from .models import PermittedRole
from ...database import objects


async def has_permitted_role(ctx):
    try:
        permitted_role = await objects.get(
            PermittedRole,
            PermittedRole.guild_id == ctx.guild.id
        )
    except DoesNotExist:
        raise CheckFailure("There is no permission role set for this Guild, which is required to use this command.")
    else:
        if permitted_role.id in (role.id for role in ctx.author.roles):
            return True
        raise CheckFailure(f"You require the role <@&{permitted_role.id}> to do this.")
