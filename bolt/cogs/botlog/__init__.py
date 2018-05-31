from .cog import BotLog


def setup(bot):
    bot.add_cog(BotLog(bot))
