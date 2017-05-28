class Meta:
    """Meta Commands, providing information about the Bot, and more."""
    def __init__(self, bot):
        self.bot = bot


def setup(bot):
    bot.add_cog(Meta(bot))