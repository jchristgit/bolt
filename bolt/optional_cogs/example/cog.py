from discord.ext import commands

from ..base import OptionalCog


class Example(OptionalCog):
    """
    An example file to demonstrate
    the function of optional cog usage.
    """

    RESTRICTED = False

    @commands.command()
    async def hello(self, ctx):
        await ctx.send("Hello from an optional cog!")


def setup(bot):
    bot.add_cog(Example(bot))
