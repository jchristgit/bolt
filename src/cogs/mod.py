import asyncio
import discord
from discord.ext import commands


class Mod:
    """Moderation Commands for Guilds. These require appropriate permission to execute."""
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.group()
    @commands.guild_only()
    @commands.has_permissions(manage_channels=True)
    @commands.bot_has_permissions(manage_channels=True)
    async def channel(self):
        pass

    @channel.command(name='rename', alias='setname')
    async def set_name(self, ctx, *, new_name: str):
        """Change the Name for a Channel.
        
        Also works using `setname` instead of `rename`.
        
        **Example:**
        !channel rename announcements - rename the current channel to "announcements"
        """
        old_name = ctx.message.channel.name
        await ctx.message.channel.edit(name=new_name)
        await ctx.send(embed=discord.Embed(description=f'Changed Channel Name from `#{old_name}` '
                                                       f'to <#{ctx.message.channel.id}>.',
                                           colour=discord.Colour.green()))

    @channel.command(name='desc', alias='setdesc')
    async def set_description(self, ctx, *, new_desc):
        """Set the description for the Channel.
        
        Also works using `setdesc` instead of `desc`.
        
        **Example:**
         !channel desc Bot Testing Channel - change the current channel's description to 'Bot Testing Channel'.
        """
        old_desc = ctx.message.channel.description
        await ctx.message.channel.edit(description=new_desc)
        await ctx.send(embed=discord.Embed(description=f'Changed Channel Description from'
                                                       f' *"{old_desc}"* to *"{new_desc}"*.'))

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge(self, ctx, limit: int=100):
        """Purge a given amount of messages. Defaults to 100.
        
        Requires the `manage_messages` permission on both the Bot and the User that invokes the Command.
        Only works on Guilds.
        
        **Example:**
        !purge - deletes 100 messages
        !purge 50 - deletes 50 messages
        """
        res = await ctx.message.channel.purge(limit=limit)
        info_response = f'Purged a total of **{len(res)} Messages**.'
        resp = await ctx.send(embed=discord.Embed(title='Purge completed', description=info_response))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgemsg')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_messages(self, ctx, *, message_contents: str):
        """Purges up to 100 Messages with the specified content in them.
        
        **Example:**
        !purgemsg bad - deletes up to 100 messages containing 'bad'
        """
        res = await ctx.message.channel.purge(check=lambda m: message_contents in m.content)
        info_response = f'Purged a total of **{len(res)} Messages** containing `{message_contents}`.'
        resp = await ctx.send(embed=discord.Embed(title='Message purge completed', description=info_response))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgeuser')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_user(self, ctx):
        """Purge a mentioned User, or a list of mentioned Users.
        
        **Example:**
        !purgeuser @Person#1337 @Robot#7331 - purges messages from Person and Robot in the past 100 Messages.
        """
        if len(ctx.message.mentions) == 0:
            await ctx.send(embed=discord.Embed(title='Failed to purge User(s)',
                                               description='You need to mention at least one User to purge.',
                                               color=discord.Colour.red()))
            return
        total_purged = 0
        for user in ctx.message.mentions:
            total_purged += len(await ctx.message.channel.purge(check=lambda m: m.author == user))
        info_response = f'Purged a total of **{total_purged} Messages** from ' \
                        f'{", ".join([str(x) for x in ctx.message.mentions])}.'
        resp = await ctx.send(embed=discord.Embed(title='User purge completed', description=info_response))
        await asyncio.sleep(5)
        await resp.delete()


def setup(bot):
    bot.add_cog(Mod(bot))


def teardown():
    print('Unloaded Cog Mod')