from .cog import Infractions


def setup(bot):
    bot.add_cog(Infractions(bot))
