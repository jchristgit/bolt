from .cog import Slowmode


def setup(bot):
    bot.add_cog(Slowmode(bot))
