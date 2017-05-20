import datetime
import discord
import humanize

from discord.ext import commands
from src.apis.twitch import parse_twitch_time, TwitchAPI, follow_config


class Streams:
    """Commands for getting notified about Streams, receiving information about them, and more."""
    def __init__(self, bot):
        self.bot = bot
        self.twitch_api = TwitchAPI()
        # Create Updater Task which should wait until ready

    @commands.group()
    @commands.guild_only()
    async def stream(self, ctx):
        """Contains Sub-Commands for interacting with Twitch Streams."""

    @stream.command(hidden=True)
    @commands.is_owner()
    async def activate(self, ctx):
        """Activates the Stream Updater."""
        #self.bot.loop.create_task(self.stream_backend.update_streams())

    @stream.command()
    @commands.cooldown(rate=10, per=5.0 * 60, type=commands.BucketType.user)
    async def get(self, ctx, stream_name):
        """Get information about a Twitch stream by its name.
        
        Yields information about whether the Stream is online, which Game is being played, the viewers,
        the uptime, and the language spoken.
        
        **Example**:
        !stream get imaqtpie - get Stream information about imaqtpie
        """
        response = discord.Embed()
        stream = await self.twitch_api.get_stream(stream_name)
        if stream is not None:
            link = f'https://twitch.tv/{stream["channel"]["name"]}'
            if stream['channel']['logo'] is not None:
                response.set_author(name=f'Stream Information for {stream["channel"]["display_name"]}',
                                    url=link, icon_url=stream["channel"]['logo'])
            else:
                response.set_author(name=f'Stream Information for {stream["channel"]["display_name"]}', url=link)
            uptime = datetime.datetime.utcnow() - parse_twitch_time(stream["created_at"][:-1], truncate=False)
            response.description = f'🕹 **`Game`**: {stream["game"]}\n' \
                                   f'🗒 **`Description`**: *{stream["channel"]["status"].strip()}*\n' \
                                   f'👁 **`Viewers`**: {stream["viewers"]}\n' \
                                   f'👀 **`Followers`**: {stream["channel"]["followers"]}\n' \
                                   f'⌛ **`Uptime`**: {str(uptime)[:-7]} h\n' \
                                   f'🗺 **`Language`**: {stream["channel"]["language"]}\n'
            response.set_thumbnail(url=stream["preview"]["medium"])
        else:
            response.description = 'The Stream is currently offline or does not exist.'
        response.colour = 0x6441A5
        await ctx.send(embed=response)

    @stream.command()
    @commands.cooldown(rate=15, per=5.0 * 60, type=commands.BucketType.user)
    async def user(self, ctx, *, user_name: str):
        """Get information about a Twitch User by his name.
        
        This is different from `!stream get <name>` because it returns information about the *user* instead of
        a Stream. If a User is not streaming, `!stream get <name>` will not return any data, regardless of 
        whether the User exists or not.
        """
        response = discord.Embed()
        user = await self.twitch_api.get_user(user_name.replace(' ', ''))
        if user is not None:
            link = f'https://twitch.tv/{user["name"]}'
            if user['logo'] is not None:
                response.set_author(name=f'User Information for {user["name"]}', url=link, icon_url=user['logo'])
                response.set_thumbnail(url=user['logo'])
            else:
                response.set_author(name=f'User Information for {user["name"]}', url=link)

            # Format dates, create footer and format Bio
            created_at = humanize.naturaldate(user['created_at'])
            updated_at = humanize.naturaldate(user['updated_at'])
            footer = f'Use `!stream get {user_name}` to see detailed information if the User is streaming!'
            bio = user['bio'].strip() if user['bio'] is not None else 'No Bio'
            response.description = f'🗞 **`Name`**: {user["name"]}\n' \
                                   f'💻 **`Display Name`**: {user["display_name"]}\n' \
                                   f'🗒 **`Bio`**: *{bio}*\n' \
                                   f'🗓 **`Creation Date`**: {created_at}\n' \
                                   f'📅 **`Last Update`**: {updated_at}\n' \
                                   f'🔗 **`Link`**: <{link}>'

            response.set_footer(text=footer)
            response.colour = 0x6441A5
        else:
            response.title = 'Error trying to get User'
            response.description = '**User not found!**'
            response.colour = discord.Colour.red()
        await ctx.send(embed=response)

    @stream.command()
    @commands.cooldown(rate=15, per=30.0 * 60, type=commands.BucketType.guild)
    async def follow(self, ctx, *, stream_name):
        """Follows the given Stream, posting announcements about it when set.
        
        To set a channel, use `!stream setchannel`.
        """
        if stream_name in follow_config.get_guild_follows(ctx.message.guild.id):
            await ctx.send(embed=discord.Embed(description=f'This Guild is already following the Channel '
                                                           f'`{stream_name}`.', colour=discord.Colour.red()))

        elif await self.twitch_api.user_exists(stream_name):
            follow_config.follow(ctx.message.guild.id, ctx.message.guild.name, stream_name)
            await ctx.send(embed=discord.Embed(description=f'This Guild is now **following the Channel '
                                                           f'`{stream_name}`**, getting notified about streaming'
                                                           f' status changes.', colour=discord.Colour.green()))
        else:
            await ctx.send(embed=discord.Embed(description=f'No Stream named `{stream_name}` found.',
                                               colour=discord.Colour.red()))

    @stream.command()
    async def unfollow(self, ctx, *, stream_name):
        """Unfollows the given Stream."""
        if stream_name not in follow_config.get_guild_follows(ctx.message.guild.id):
            await ctx.send(embed=discord.Embed(description=f'This Guild is not following the Channel `{stream_name}`.',
                                               colour=discord.Colour.red()))
        else:
            follow_config.un_follow(ctx.message.guild.id, stream_name)
            await ctx.send(embed=discord.Embed(description=f'Successfully unfollowed `{stream_name}`.',
                                               colour=discord.Colour.green()))

    @stream.command(name='setchannel')
    async def set_channel(self, ctx):
        """Sets the current channel as the channel to be used for posting Stream announcements."""
        follow_config.set_channel(ctx.message.guild.id, ctx.message.guild.name, ctx.message.channel.id)
        await ctx.send(embed=discord.Embed(description=f'Set the Stream announcement channel to this channel.',
                                           colour=discord.Colour.green()))

    @stream.command(name='unsetchannel')
    async def unset_channel(self, ctx):
        """Unset the Guild's stream channel."""
        if follow_config.get_channel_id(ctx.message.guild.id) == '':
            await ctx.send(embed=discord.Embed(description='This Guild has no stream announcement channel set.',
                                               colour=discord.Colour.red()))
        else:
            follow_config.unset_channel(ctx.message.guild.id, ctx.message.guild.name)
            await ctx.send(embed=discord.Embed(description='Unset this Guild\'s stream announcement channel.',
                                               colour=discord.Colour.green()))

    @stream.command()
    async def follows(self, ctx):
        """Lists all channels that this Guild is following."""
        pass


def setup(bot):
    bot.add_cog(Streams(bot))
