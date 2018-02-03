from . import models
from .cog import Config


def setup(bot):
    bot.add_cog(Config(bot))
