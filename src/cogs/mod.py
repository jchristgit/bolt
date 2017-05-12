import asyncio
import discord
import logging
from discord.ext import commands

log = logging.getLogger('bot')


class Moderation:
    """Moderation Commands for Guilds. These require appropriate permission to execute."""
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.group('channel')
    @commands.guild_only()
    @commands.has_permissions(manage_channels=True)
    async def channel(self):
        pass

    @channel.command(name='lock')
    @channel.bot_has_permissions(manage_roles=True)
    async def lock_channel(self, ctx):
        """
        Locks a channel for Members without a Role that explicitly allows them to write in it, for example the Owner,
        thus denying them the ability to send any Message in the Channel or react to messages.
        """
        overwrite = discord.PermissionOverwrite()
        overwrite.update(send_messages=False, add_reactions=False)
        await ctx.message.channel.set_permissions(ctx.message.guild.default_role, overwrite=overwrite)

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
        """Purge a mentioned User, or a list of Users if multiple mentions are given.
        
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
    bot.add_cog(Moderation(bot))


def teardown():
    print('Unloaded Cog Moderation')