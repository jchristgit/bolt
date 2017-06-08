import dataset
import datetime
import discord
import humanize
import random
import string

from discord.ext import commands
from enum import Enum
from stuf import stuf
from ..util import create_logger

logger = create_logger('wormhole')
db = dataset.connect('sqlite:///data/guilds.db', row_type=stuf)


class Mode(Enum):
    # Send all Messages inside the Wormhole channel to its link
    IMPLICIT = 1

    # Only send explicit invocations using `wormhole send`
    EXPLICIT = 2


class Wormhole:
    """
    Commands for communicating between two Guilds.
    """
    def __init__(self, bot: discord.AutoShardedClient):
        self.bot = bot
        self.table = db['wormhole']
        print('Loaded Cog Wormhole.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Wormhole.')

    def get_channel_token(self) -> str:
        token = ''.join(random.SystemRandom().choice(string.ascii_letters + string.digits) for _ in range(10))

        if token in (guild_row.token for guild_row in self.table.all()):
            return self.get_channel_token()

        return token

    @commands.group(aliases=['wh'])
    @commands.guild_only()
    async def wormhole(self, ctx):
        """
        Subcommands for interacting with Wormholes. Aliased to `wh`.


        Wormholes redirect Messages between two Guilds, allowing Guilds with
        similiar interests to easily communicate. To manage wormholes, the
        `Manage Channels` permission is required. If you have this permission,
        use `wormhole open`.
        """

    @wormhole.command(name='open')
    @commands.has_permissions(manage_channels=True)
    async def open_(self, ctx):
        """Opens a Wormhole in the Channel this Message was sent."""
        if self.table.find_one(guild_id=ctx.guild.id) is not None:
            await ctx.send(embed=discord.Embed(
                title='Open Wormhole',
                description=('A Wormhole is already opened on this Guild. If you wish to open a new one, please '
                             'close this first using `wormhole close` and open it in another channel.'),
                colour=discord.Colour.red()
            ))
        else:
            token = self.get_channel_token()
            self.table.insert(dict(
                guild_id=ctx.guild.id,
                guild_name=ctx.guild.name,
                locked=False,
                token=token,
                mode=Mode.EXPLICIT.value,
                channel_id=ctx.message.channel.id,
                linked_to=None,
                open_since=datetime.datetime.utcnow()
            ))
            await ctx.send(embed=discord.Embed(
                title='Wormhole Opened',
                description='A Wormhole has successfully been opened for this Guild.',
                colour=discord.Colour.green()
            ).add_field(
                name='Connecting the Wormhole',
                value=(f'Another Guild can connect to this Wormhole by using `wormhole link {token}`. After a '
                        'Guild has connected, no other Guild can connect to it. To unlink the other Guild from the '
                        'Wormhole, use `wormhole unlink`.')
            ).add_field(
                name='Token',
                value=f'`{token}`'
            ))
            logger.info(f'Guild {ctx.guild.name} has opened a Wormhole in channel {ctx.message.channel.id}.')

    @wormhole.command()
    @commands.has_permissions(manage_channels=True)
    async def close(self, ctx):
        """
        Closes the Wormhole in this Channel if it is present.

        If the Wormhole is linked to another Guild, it must first be unlinked.
        """
        guild_row = self.table.find_one(channel_id=ctx.message.channel.id)
        if guild_row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to close Wormhole',
                description='No Wormhole has been set up in this channel yet.',
                colour=discord.Colour.red()
            ))
        elif guild_row.linked_to is not None:
            await ctx.send(embed=discord.Embed(
                title='Failed to close Wormhole',
                description='A Link through this Wormhole is still active. Use `wormhole unlink` to unlink it.',
                colour=discord.Colour.red()
            ))
        else:
            await self.table.delete(channel_id=ctx.message.channel.id)
            await ctx.send(embed=discord.Embed(
                title='Closing wormhole successful',
                description='The Wormhole of this Guild has successfully been closed.',
                colour=discord.Colour.green()
            ))
            logger.info(f'Guild {ctx.guild.name} has closed its Wormhole in channel {ctx.message.channel.id}.')

    @wormhole.command()
    @commands.has_permissions(manage_channels=True)
    async def link(self, ctx, *, token: str):
        """
        Links this channel to the specified wormhole token.

        This enables the inter-server communication through the wormhole.
        Note that this *does not* create a token for later use.
        If you wish to act as a host for a wormhole, use `wormhole open` instead of connecting to one.
        """
        row = self.table.find_one(token=token)
        if row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to link',
                description='Unknown or incorrect token.',
                colour=discord.Colour.red()
            ))
        elif row.locked:
            await ctx.send(embed=discord.Embed(
                title='Failed to link',
                description='The entered token is currently locked.',
                colour=discord.Colour.red()
            ))
        else:
            self.table.insert(dict(
                guild_id=ctx.guild.id,
                guild_name=ctx.guild.name,
                locked=True,
                token=None,
                mode=Mode.EXPLICIT.value,
                channel_id=ctx.message.channel.id,
                linked_to=row.channel_id,
                open_since=datetime.datetime.utcnow()
            ))
            self.table.update(dict(
                guild_id=row.guild_id,
                locked=True,
                linked_to=ctx.message.channel.id
            ), ['guild_id'])
            await ctx.send(embed=discord.Embed(
                title='Link established',
                description=f'A link between this Guild and `{row.guild_name}` has been established!',
                colour=discord.Colour.blue()
            ))
            logger.info(f'Guild {ctx.guild.name} and {row.guild_name} have established a wormhole link.')

    @wormhole.command()
    @commands.has_permissions(manage_channels=True)
    async def unlink(self, ctx):
        """Unlinks this channel if it is linked to another Guild."""
        linked_guild_row = self.table.find_one(linked_to=ctx.message.channel.id)
        if linked_guild_row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to unlink',
                description='No Guild has its wormhole channel linked to this channel.',
                colour=discord.Colour.red()
            ))
        else:
            current_guild_row = self.table.find_one(guild_id=ctx.guild.id)
            self.table.update(dict(
                guild_id=linked_guild_row.guild_id,
                linked_to=None,
                locked=False
            ), ['guild_id'])
            self.table.update(dict(
                guild_id=current_guild_row.guild_id,
                linked_to=None,
                locked=False
            ), ['guild_id'])
            await ctx.send(embed=discord.Embed(
                title='Unlink successful',
                description=(f'The wormhole between this Guild and `{linked_guild_row.guild_name}` has been unlinked. '
                             f'The tokens of both guilds are now **unlocked**. If you wish to prevent the token from '
                             f'being used, use `wormhole lock`.'),
                colour=discord.Colour.blue()
            ))
            logger.info(f'Guild {ctx.guild.name} unlinked its Wormhole to {linked_guild_row.guild_name}.')

    @wormhole.command()
    @commands.cooldown(rate=5, per=60., type=commands.BucketType.user)
    async def send(self, ctx, *, content: str):
        """Sends a message through the wormhole."""
        row = self.table.find_one(linked_to=ctx.message.channel.id)
        if row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to send Message',
                description=('No Wormhole connection has been set up yet. Ask somebody with the `Manage Channels` '
                             'permission to open one using `wormhole open`.'),
                colour=discord.Colour.red()
            ))
        elif row.linked_to is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to send Message',
                description='A Wormhole was opened, but no other Guild has linked itself towards this wormhole yet.',
                colour=discord.Colour.red()
            ))
        else:
            target_channel = self.bot.get_channel(row.channel_id)
            if target_channel is None:
                await ctx.send(embed=discord.Embed(
                    title='Failed to Send Message',
                    description='Destination channel was not found',
                    colour=discord.Colour.red()
                ))
            else:
                await target_channel.send(embed=discord.Embed(
                    description=content,
                    colour=discord.Colour.blue()
                ).set_author(
                    name=f'{ctx.author} ({ctx.author.top_role.name})',
                    icon_url=ctx.author.avatar_url
                ).set_footer(
                    text=ctx.guild.name,
                    icon_url=ctx.guild.icon_url
                ))

    @wormhole.command()
    async def info(self, ctx):
        """Displays information about the current wormhole, if present."""
        guild_row = self.table.find_one(guild_id=ctx.guild.id)
        if guild_row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to display stats',
                description='No Wormhole has been opened in this Guild yet.',
                colour=discord.Colour.red()
            ))
        else:
            open_delta = datetime.datetime.utcnow() - guild_row.open_since
            linked_to = self.table.find_one(linked_to=ctx.message.channel.id)
            await ctx.send(embed=discord.Embed(
                title='Wormhole Information',
                colour=discord.Colour.blue()
            ).add_field(
                name='Open since',
                value=f'{humanize.naturaldate(guild_row.open_since)} ({humanize.naturaldelta(open_delta)})'
            ).add_field(
                name='Linked to',
                value=f'{linked_to.guild_name if linked_to is not None else "No Link established"}'
            ).add_field(
                name='Channel',
                value=f'{"#" + self.bot.get_channel(guild_row.channel_id).name}'
            ).add_field(
                name='Mode',
                value=f'**{"Explicit Invocation" if guild_row.mode == 2 else "Implicit Sending"}**'
            ))

    @wormhole.command()
    async def token(self, ctx):
        """Get this Guild's wormhole token, used for linking wormholes."""
        guild_row = self.table.find_one(guild_id=ctx.guild.id)
        if guild_row is None:
            await ctx.send(embed=discord.Embed(
                title='Failed to get Token',
                description='No wormhole is opened in this Guild.',
                colour=discord.Colour.red()
            ))
        else:
            state = '**Locked**' if guild_row.locked else "**Unlocked**"
            if guild_row.linked_to is not None:
                state += f' and linked to **{self.table.find_one(channel_id=guild_row.linked_to).guild_name}**.'
            await ctx.send(embed=discord.Embed(
                title='Wormhole Token',
                description=(f'The token for channel #{self.bot.get_channel(guild_row.channel_id).name} is '
                             f'`{guild_row.token}.`'),
                colour=discord.Colour.blue()
            ).add_field(
                name='State',
                value=state
            ))

    @wormhole.command(hidden=True)
    @commands.is_owner()
    async def drop(self, ctx):
        """Removes all entries from the wormhole table."""
        self.table.delete()
        await ctx.send(embed=discord.Embed(
            title='Dropped the Wormhole table.',
            colour=discord.Colour.green()
        ))
        logger.warning('Deleted all entries from the wormhole table.')


def setup(bot):
    bot.add_cog(Wormhole(bot))
