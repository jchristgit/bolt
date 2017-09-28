import discord
from discord.ext import commands


class Meta:
    """Meta Commands, providing information about various things."""
    def __init__(self, bot):
        self.bot = bot
        print('Loaded Cog Meta.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Meta.')

    @commands.command()
    async def stats(self, ctx):
        """Displays information and statistics about the Bot."""
        response = discord.Embed()
        response.colour = discord.Colour.blue()
        response.set_thumbnail(
            url=self.bot.user.avatar_url
        ).set_author(
            name='Made by Volcyy#2359',
            url='https://github.com/Volcyy/Bolt',
            icon_url=(await self.bot.application_info()).owner.avatar_url
        ).add_field(
            name='Guilds',
            value=(f'**Total**: {sum(1 for _ in self.bot.guilds)}\n'
                   f'**Avg. Members**: {sum(g.member_count for g in self.bot.guilds) // len(self.bot.guilds)}\n'
                   f'**Shards**: {self.bot.shard_count}')
        ).add_field(
            name='Users',
            value=(f'**Total**: {sum(1 for _ in self.bot.get_all_members())}\n'
                   f'**Unique**: {len(set(self.bot.get_all_members()))}')
        )

        await ctx.send(embed=response)

    @commands.command()
    async def guilds(self, ctx):
        """Returns a list of all Guilds that the Bot can see."""
        await ctx.send(embed=discord.Embed(
            title=f'Guilds ({sum(1 for _ in self.bot.guilds)} total)',
            description=', '.join(g.name for g in self.bot.guilds),
            colour=discord.Colour.blue()
        ))

    @commands.command(aliases=['member'])
    @commands.guild_only()
    async def minfo(self, ctx, *, member: discord.Member=None):
        """Displays Information about yourself or a tagged Member."""
        if member is None:
            member = ctx.message.author
        await ctx.send(embed=discord.Embed(
            title=f'User Information for {member}',
            colour=member.top_role.colour
        ).add_field(
            name='Roles',
            value=', '.join(m.mention for m in member.roles[1:]) or 'No Roles'
        ).add_field(
            name='Joined this Guild',
            value=str(member.joined_at)[:-7]
        ).add_field(
            name='Joined Discord',
            value=str(member.created_at)[:-7]
        ).add_field(
            name='User ID',
            value=member.id
        ).add_field(
            name='Avatar URL',
            value=member.avatar_url
        ).set_thumbnail(
            url=member.avatar_url
        ))


def setup(bot):
    bot.add_cog(Meta(bot))
