from . import models  # noqa
from .cog import Config


def setup(bot):
    bot.add_cog(Config(bot))
