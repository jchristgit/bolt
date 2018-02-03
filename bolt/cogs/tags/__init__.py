from . import models  # noqa
from .cog import Tags


def setup(bot):
    bot.add_cog(Tags(bot))
