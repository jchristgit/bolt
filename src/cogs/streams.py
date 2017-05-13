import datetime
import discord
import humanize
import json

from discord.ext import commands
from src.twitch_api import TwitchAPI
from time import strptime, mktime


def datetime_from_struct_time(struct_time):
    return datetime.datetime.fromtimestamp(mktime(strptime(struct_time, '%Y-%m-%dT%H:%M:%SZ')))


class FollowConfig:
    # Handles reading and writing the configuration file for stream follows
    def __init__(self):
        with open('config/streams.json') as f:
            self._config = json.load(f)

    def save(self):
        with open('config/streams.json', 'w') as f:
            json.dump(self._config, f, indent=4, sort_keys=True)

    def get_guild_subscriptions(self, guild_id):
        # fix
        guild_id = str(guild_id)
        if guild_id not in self._config['guild_follows']:
            return []
        return self._config['guild_follows'][guild_id]['follows']

    def follow(self, guild_id, guild_name, stream_name):
        guild_id = str(guild_id)
        if guild_id not in self._config['guild_follows']:
            print(f'[STREAMS] Guild {guild_id} is now following {stream_name}.')
            # Store this channel in the guild's follows
            self._config['guild_follows'][guild_id] = {
                'channel': '',
                'follows': [
                    stream_name
                ],
                'name': guild_name
            }
            print(self._config)
        else:
            self._config['guild_follows'][guild_id]['follows'].append(stream_name)
        if stream_name not in self._config['global_follows']:
            # Store this guild for the followers for the Channel
            self._config['global_follows'][stream_name] = [
                guild_id
            ]
        else:
            self._config['global_follows'][stream_name].append(guild_id)

follow_config = FollowConfig()


class StreamBackend:
    # Handles processing Stream data in a human-readable form
    def __init__(self):
        self.api = TwitchAPI()

    # Get a Stream by its name.
    async def get_stream(self, name):
        return await self.api.get_stream(name)

    # Get a User by his name.
    async def get_user(self, name):
        return await self.api.get_user(name)

    # Get information about whether a User is streaming, and if so, what game is being played
    async def get_status(self, name):
        user = await self.api.get_stream(name)
        if user.online:
            return f'Playing {user.game}'
        return 'Offline'

    # Check if a User exists
    async def exists(self, name):
        return (await self.api.get_user(name)).exists


class Streams:
    """Commands for getting notified about Streams, receiving information about them, and more."""
    def __init__(self, bot):
        self.bot = bot
        self.stream_backend = StreamBackend()

    @commands.group()
    async def stream(self, ctx):
        """Contains Sub-Commands for interacting with Twitch Streams."""

    @stream.command()
    @commands.cooldown(rate=3, per=5.0 * 60, type=commands.BucketType.user)
    async def get(self, ctx, stream_name):
        """Get information about a Twitch stream by its name.
        
        Yields information about whether the Stream is online, which Game is being played, the viewers,
        the uptime, and the language spoken.
        
        **Example**:
        !stream get imaqtpie - get Stream information about imaqtpie
        """
        response = discord.Embed()
        stream = await self.stream_backend.get_stream(stream_name)
        if stream.online:
            response.set_author(name=f'Stream Information for {stream.display_name}',
                                url=stream.url, icon_url=stream.channel_logo)
            uptime = datetime.datetime.now() - datetime_from_struct_time(stream.creation_date)
            response.description = f'📺 **`Status`**: online\n' \
                                   f'🕹 **`Game`**: {stream.game}\n' \
                                   f'🗒 **`Description`**: *{stream.channel_status}*\n' \
                                   f'👁 **`Viewers`**: {stream.viewers}\n' \
                                   f'👀 **`Followers`**: {stream.followers}\n' \
                                   f'⌛ **`Uptime`**: {str(uptime)[:-7]} h\n' \
                                   f'🗺 **`Language`**: {stream.language}\n'
            response.set_thumbnail(url=stream.preview)
        else:
            response.description = f'The Stream is currently offline or does not exist.'
        response.colour = 0x6441A5
        await ctx.send(embed=response)

    @stream.command()
    @commands.cooldown(rate=3, per=5.0 * 60, type=commands.BucketType.user)
    async def user(self, ctx, user_name):
        """Get information about a Twitch User by his name.
        
        This is different from `!stream get <name>` because it returns information about the *user* instead of
        a Stream. If a User is not streaming, `!stream get <name>` will not return any data, regardless of 
        whether the User exists or not.
        """
        response = discord.Embed()
        user = await self.stream_backend.api.get_user(user_name)
        if user.exists:
            if user.logo_url is not None:
                response.set_author(name=f'User Information for {user.display_name}', url=user.link,
                                    icon_url=user.logo_url)
                response.set_thumbnail(url=user.logo_url)
            else:
                response.set_author(name=f'User Information for {user.display_name}', url=user.link)
            creation_date = humanize.naturaldate(datetime_from_struct_time(user.creation_date))
            updated_at = humanize.naturaldate(datetime_from_struct_time(user.updated_at))
            footer = f'Use `!stream get {user_name}` to see detailed information if the User is streaming!'
            status = await self.stream_backend.get_status(user_name)
            response.description = f'🗞 **`Name`**: {user.name}\n' \
                                   f'📺 **`Status`**: {status}\n' \
                                   f'💻 **`Display Name`**: {user.display_name}\n' \
                                   f'🗒 **`Bio`**: *{user.bio.strip()}*\n' \
                                   f'🗓 **`Creation Date`**: {creation_date}\n' \
                                   f'📅 **`Last Update`**: {updated_at}\n' \
                                   f'🔗 **`Link`**: <{user.link}>\n'
            response.set_footer(text=footer)
            response.colour = 0x6441A5
        else:
            response.title = 'Error trying to get User'
            response.description = f'**{user.status}**: {user.error_message}'
            response.colour = discord.Colour.red()
        await ctx.send(embed=response)

    @stream.command()
    @commands.cooldown(rate=15, per=30.0 * 60, type=commands.BucketType.guild)
    async def follow(self, ctx, stream_name):
        """Follows the given Stream, posting announcements about it when set.
        
        To set a channel, use `!stream set`.
        """
        if await self.stream_backend.exists(stream_name):
            if stream_name in follow_config.get_guild_subscriptions(ctx.message.guild.id):
                await ctx.send(embed=discord.Embed(description=f'This Guild is already following the Channel '
                                                               f'`{stream_name}`.', colour=discord.Colour.red()))
            else:
                follow_config.follow(ctx.message.guild.id, ctx.message.guild.name, stream_name)
                await ctx.send(embed=discord.Embed(description=f'This Guild is now **following the Channel '
                                                               f'`{stream_name}`**, getting notified about it going'
                                                               f' online and offline.', colour=discord.Colour.green()))
        else:
            await ctx.send(embed=discord.Embed(description=f'No Stream named `{stream_name}` found.',
                                               colour=discord.Colour.red()))


def setup(bot):
    bot.add_cog(Streams(bot))
