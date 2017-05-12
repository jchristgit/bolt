import asyncio
import datetime
import discord

from discord.ext import commands
from src.twitch_api import TwitchAPI
from time import strptime, mktime


def datetime_from_struct_time(struct_time):
    return datetime.datetime.fromtimestamp(mktime(strptime(struct_time, '%Y-%m-%dT%H:%M:%SZ')))


class StreamBackend:
    # Handles processing Stream data in a human-readable form
    def __init__(self):
        self.api = TwitchAPI()


class Streams:
    """Commands for getting notified about Streams, receiving information about them, and more."""
    def __init__(self, bot):
        self.bot = bot
        self.stream_backend = StreamBackend()

    @commands.group()
    async def stream(self, ctx):
        """Contains Sub-Commands for interacting with Twitch Streams."""

    @stream.command()
    @commands.cooldown(rate=3, per=5.0 * 50, type=commands.BucketType.user)
    async def get(self, ctx, stream_name):
        """Get information about a Twitch stream by its name.
        
        Yields information about whether the Stream is online, which Game is being played, the viewers,
        the uptime, and the language spoken.
        
        **Example**:
        !stream get imaqtpie - get Stream information about imaqtpie"""
        response = discord.Embed()
        stream = await self.stream_backend.api.get_stream(stream_name)
        if stream.online:
            response.set_author(name=f'Stream Information for {stream.display_name}',
                                url=stream.url, icon_url=stream.channel_logo)
            uptime = datetime.datetime.now() - datetime_from_struct_time(stream.creation_date)
            response.description = f'📺 **`Status`**: online\n' \
                                   f'🕹 **`Game`**: {stream.game}\n' \
                                   f'👀 **`Viewers`**: {stream.viewers}\n' \
                                   f'⏲ **`Uptime`**: {str(uptime)[:-7]} h\n' \
                                   f'🗺 **`Language`**: {stream.language}\n'
            response.set_thumbnail(url=stream.preview)
        else:
            response.description = f'The Stream is currently offline or does not exist.'
        response.colour = 0x6441A5
        await ctx.send(embed=response)


def setup(bot):
    bot.add_cog(Streams(bot))
