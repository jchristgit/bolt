import discord
import psutil

from discord.ext import commands


class Meta:
    """Meta Commands, providing information about the Bot, and more."""
    def __init__(self, bot):
        self.bot: discord.AutoShardedClient = bot
        self.process = psutil.Process()
        print('Loaded Cog Meta.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Meta.')

    @commands.command()
    async def stats(self, ctx):
        """Displays statistics about the Bot."""

        memory_usage = self.process.memory_full_info().uss / 1024**2 * 1.048576
        average_guild_users = sum(g.member_count for g in self.bot.guilds) / len(self.bot.guilds)

        response = discord.Embed()
        response.colour = discord.Colour.blue()
        response.set_thumbnail(url=self.bot.user.avatar_url)
        response.set_author(name='Made by Volcyy#2359', url='https://github.com/Volcyy/Bolt',
                            icon_url=(await self.bot.application_info()).owner.avatar_url)
        response.add_field(name='System Usage', value=f'**CPU**: {self.process.cpu_percent() / psutil.cpu_count()}%\n'
                                                      f'**Memory**: {str(memory_usage)[:5]} MB')
        response.add_field(name='Users', value=f'**Total**: {sum(1 for m in self.bot.get_all_members())}\n'
                                               f'**Unique**: {len(set(self.bot.get_all_members()))}')

        response.add_field(name='Guilds', value=f'**Total**: {sum(1 for g in self.bot.guilds)}\n'
                                                f'**Avg. Members**: {average_guild_users}\n'
                                                f'**Shards**: {self.bot.shard_count}')

        await ctx.send(embed=response)


def setup(bot):
    bot.add_cog(Meta(bot))