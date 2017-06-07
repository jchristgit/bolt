import dataset
import datetime
import discord
import random
import string

from discord.ext import commands
from enum import Enum
from stuf import stuf
from ..util import create_logger

logger = create_logger('wormhole')
db = dataset.connect('sqlite:///data/guilds.guild_db', row_type=stuf)


class Mode(Enum):
    # Send all Messages inside the Wormhole channel to its link
    IMPLICIT = 1

    # Only send explicit invocations using `wormhole send`
    EXPLICIT = 2


class Wormhole:
    """
    Commands for communicating between two Guilds.

    Wormholes redirect Messages between two Guilds, allowing Guilds with
    similiar interests to easily communicate.
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
        """Subcommands for interacting with Wormholes. Aliased to `wh`."""

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
                mode=Mode.EXPLICIT,
                channel_id=ctx.message.channel.id,
                linked_to=None,
                open_since=datetime.datetime.utcnow()
            ))
            await ctx.send(embed=discord.Embed(
                title='Wormhole Opened',
                description='A Wormhole has successfully been opened for this Guild.'
            ).add_field(
                name='Connecting the Wormhole',
                value=(f'Another Guild can connect to this Wormhole by using `wormhole link {token}`. After another '
                       f'Guild has connected, no other Guild can connect to it. To unlink the other Guild from the '
                       f'Wormhole, use `wormhole unlink`.')
            ).add_field(
                name='Token',
                value=token
            ))

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
                mode=Mode.EXPLICIT,
                channel_id=ctx.message.channel.id,
                linked_to=row.channel_id,
                open_since=datetime.datetime.utcnow()
            ))
            await ctx.send(embed=discord.Embed(
                title='Link established',
                description=f'A link between this Guild and `{row.guild_name}` has been established!',
                colour=discord.Colour.blue()
            ))


def setup(bot):
    bot.add_cog(Wormhole(bot))
