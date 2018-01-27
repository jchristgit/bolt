from sqlalchemy import and_

from ..models import opt_cog


class OptionalCog:
    """
    An optional Cog is a cog that can be
    enabled or disabled on a guild. This
    class defines a set of common attributes
    that all optional cogs should inherit.
    """

    # An optional cog with RESTRICTED = True
    # can only be enabled on a guild by the
    # bot owner. This is useful for cogs that
    # were made for a single guild and are not
    # intended to be used on other guilds.
    RESTRICTED: bool

    def __init__(self, bot):
        self.bot = bot

        # Patch in the check to deal with name mangling issues
        # Ok, I admit, this is some really hacky shit. If someone has a better solution, please tell me
        setattr(self, f'_{self.__class__.__name__}__local_check', self.__is_enabled)

    async def __is_enabled(self, ctx):
        return await enabled_for(self, ctx.guild.id)


async def enabled_for(cog: OptionalCog, guild_id: int):
    query = opt_cog.select().where(and_(opt_cog.c.guild_id == guild_id,
                                        opt_cog.c.name == cog.__class__.__name__))
    res = await cog.bot.db.execute(query)
    row = await res.first()

    return row is not None
