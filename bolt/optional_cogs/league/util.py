from discord.ext.commands import CheckFailure

from .models import permitted_role as perm_role_model


async def has_permission_role(ctx):
    query = perm_role_model.select().where(perm_role_model.c.guild_id == ctx.guild.id)
    result = await ctx.bot.db.execute(query)
    perm_role = await result.first()
    if perm_role is None:
        raise CheckFailure("There is no permission role set for this Guild.")
    elif perm_role.id in (r.id for r in ctx.author.roles):
        return True
    raise CheckFailure(f"You require the role <@&{perm_role.id}> to do this.")
