import dataset

from discord.ext import commands
from stuf import stuf


# Bot Database contains information about tickets and blacklisted users, and possibly other stuff later
db = dataset.connect('sqlite:///data/bot.db', row_type=stuf)


class Tickets:
    """Commands for filing bug reports or asking questions."""
    def __init__(self, bot):
        self.bot = bot
        self.table = db['tickets']
        print('Loaded Cog Tickets.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Tickets.')

    @commands.command()
    async def question(self, ctx, *, question: str):
        """Asks a question for the bot developer."""
        pass


def setup(bot):
    bot.add_cog(Tickets(bot))
