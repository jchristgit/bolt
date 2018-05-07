from peewee import DoesNotExist

from bolt.cogs.config.models import OptionalCog as OptionalCogModel
from bolt.database import objects


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
    RESTRICTED: bool = False

    def __init__(self, bot):
        self.bot = bot

        # Patch in the check to deal with name mangling issues
        # Ok, I admit, this is some really hacky shit. If someone has a better solution, please tell me
        setattr(self, f'_{self.__class__.__name__}__local_check', self.__is_enabled)

    async def __is_enabled(self, ctx):
        return await enabled_for(self, ctx.guild.id)


async def enabled_for(cog: OptionalCog, guild_id: int):
    try:
        await objects.get(
            OptionalCogModel,
            OptionalCogModel.guild_id == guild_id,
            OptionalCogModel.name == cog.__class__.__name__
        )
    except DoesNotExist:
        return False
    return True
