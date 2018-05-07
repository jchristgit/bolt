from .cog import League


def setup(bot):
    bot.add_cog(League(bot))
