from .cog import StaffLog


def setup(bot):
    bot.add_cog(StaffLog(bot))
