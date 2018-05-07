from shlex import split
from typing import Iterable

from discord import Role
from discord.ext.commands import BadArgument, RoleConverter


class RoleListConverter(RoleConverter):
    async def convert(self, ctx, roles: str) -> Iterable[Role]:
        single_role_name = roles.lower()
        role = next((r for r in ctx.guild.roles if r.name.lower() == single_role_name.lower()), None)

        if role is None:
            try:
                result = []
                for role_name in split(roles):
                    result.append(await super().convert(ctx, role_name))

            except BadArgument:
                raise BadArgument(
                    f"Role `{role_name}` not found. "
                    "Did you forget to enclose it in quotes, or didn't capitalize it properly?"
                )

            else:
                return result

        return [role]
