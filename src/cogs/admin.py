import asyncio
import discord

from discord.ext import commands
from run import COGS_BASE_PATH


class Admin:
    """
    Contains Commands for the Administration of the Bot.
    Unloading this Cog may not be a good idea. 
    """
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        print('Loaded Cog Admin.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Admin.')

    @commands.command(hidden=True)
    @commands.is_owner()
    async def shutdown(self, ctx):
        """Shutdown the Bot. Owner only."""
        print('Shutting down by owner request...')
        await ctx.send(embed=discord.Embed(description='Shutting down...'))
        await self.bot.close()

    @commands.command(name='setplaying', hidden=True)
    @commands.is_owner()
    async def set_playing(self, _, *, new_status):
        await self.bot.change_presence(game=discord.Game(name=new_status))

    @commands.command(name='getc', hidden=True)
    async def get_channel(self, ctx, channel_id: int):
        chan = self.bot.get_channel(channel_id)
        topic = (chan.topic if hasattr(chan, 'topic') else '') or 'None'
        if chan is None:
            await ctx.send(embed=discord.Embed(
                title='Channel was not found.',
                colour=discord.Colour.red()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                title='Channel found:',
                colour=discord.Colour.blue()
            ).add_field(
                name='Channel',
                value=f'**Name**: {chan.mention}\n**ID**: `{chan.id}`\n**Description**: {topic}',
                inline=False,
            ).add_field(
                name='Guild',
                value=f'**Name**: {chan.guild.name}\n**ID**: `{chan.guild.id}`\n**Owner**: {chan.guild.owner}',
                inline=False
            ).set_thumbnail(
                url=chan.guild.icon_url or self.bot.user.avatar_url
            ))

    @staticmethod
    async def _remove_reply_if_not_dm(ctx, reply: discord.Message, delay=3):
        # Remove a Message after 3 seconds if it wasn't sent in a Private Message.
        if not isinstance(ctx.channel, discord.abc.PrivateChannel):
            await asyncio.sleep(delay)
            await reply.delete()
            await ctx.message.delete()

    @commands.command(hidden=True)
    @commands.is_owner()
    async def reload(self, ctx):
        """Reloads all Cogs."""
        # Cast to list to prevent a RuntimeError, since we just want the iteration for the names of the Cogs
        for extension_name in list(self.bot.extensions):
            self.bot.unload_extension(extension_name)
            self.bot.load_extension(extension_name)
        response = await ctx.send(embed=discord.Embed(title='Reload Complete',
                                                      description=f'Reloaded {len(self.bot.cogs)} Cogs.',
                                                      colour=discord.Colour.green()))

        await self._remove_reply_if_not_dm(ctx, response)

    @commands.command(hidden=True)
    @commands.is_owner()
    async def load(self, ctx, *, cog_name: str):
        """Load a Cog."""
        cog_name = cog_name.title()
        if cog_name in self.bot.cogs:
            response = await ctx.send(embed=discord.Embed(title=f'Cog `{cog_name}` is already loaded.',
                                                          colour=discord.Colour.red()))
        else:
            self.bot.load_extension(COGS_BASE_PATH + cog_name.lower())
            response = await ctx.send(embed=discord.Embed(title=f'Loaded the {cog_name} Cog.',
                                                          colour=discord.Colour.green()))

        # Delete reply and command invocation Message if it wasn't invoked in a DM
        await self._remove_reply_if_not_dm(ctx, response)

    @commands.command(hidden=True)
    @commands.is_owner()
    async def unload(self, ctx, *, cog_name: str):
        """Unload a Cog."""
        cog_name = cog_name.title()
        if cog_name not in self.bot.cogs:
            response = await ctx.send(embed=discord.Embed(title=f'No Cog named `{cog_name}` currently loaded or found.',
                                                          colour=discord.Colour.red()))
        else:
            self.bot.remove_cog(cog_name)
            response = await ctx.send(embed=discord.Embed(title=f'Unloaded the {cog_name} Cog.',
                                                          colour=discord.Colour.green()))

        await self._remove_reply_if_not_dm(ctx, response)

    @commands.command(hidden=True)
    @commands.is_owner()
    async def cogs(self, ctx):
        """List all available Cogs."""
        response = await ctx.send(embed=discord.Embed(title=f'Currently loaded Cogs ({len(self.bot.cogs)} total)',
                                                      description=', '.join(self.bot.cogs)))
        await self._remove_reply_if_not_dm(ctx, response, delay=5)


def setup(bot):
    bot.add_cog(Admin(bot))
