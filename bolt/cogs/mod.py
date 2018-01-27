import asyncio
import discord

from discord.ext import commands

from ..models import prefix as prefix_model


class Mod:
    """
    Moderation Commands for Guilds, such as kicking / banning or changing configuration.

    Keep in mind that although I'm not primarily intended for Moderation Commands,
    I still provide a bunch of them in case you will ever need it.
    """
    def __init__(self, bot):
        self.bot = bot
        print('Loaded Cog Mod.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Mod.')

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(ban_members=True)
    @commands.bot_has_permissions(ban_members=True)
    async def ban(self, ctx, member: discord.Member, prune_days: int=1, *, reason: str=''):
        """Ban a Member with an optional prune and an optional reason.
        
        If the amount of messages to prune is omitted, all his messages of the past day will be deleted.
        The maximum is 7 and the minimum is 0.
        
        **Example:**
        !ban @Guy#1337 - bans Guy and deletes his messages of the last day
        !ban @Guy#1337 3 - bans Guy and prunes his messages of the last 3 days
        !ban @Guy#1337 4 be nice - bans Guy and specifies the reason "be nice" for the Audit Log.
        """

        if prune_days > 7 or prune_days < 0:
            return await ctx.send(embed=discord.Embed(
                title='Failed to Ban:',
                description='The amount of days to prune Messages for must be within 0 and 7.',
                colour=discord.Colour.red()
            ))
        elif ctx.message.guild.me.top_role.position <= member.top_role.position:
            return await ctx.send(embed=discord.Embed(
                title='Cannot ban:',
                description=('I cannot ban any Members that are in the same or higher position in the role hierarchy '
                             'as I am.'),
                colour=discord.Colour.red()
            ))
        await ctx.guild.ban(member, reason=f'Command invoked by {ctx.message.author}, reason: '
                                           f'{"No reason specified" if reason == "" else reason}.',
                            delete_message_days=prune_days)
        reason = f' for *"{reason}"*.' if reason != '' else '.'
        await ctx.send(embed=discord.Embed(
            title='Ban successful',
            description=f'**Banned {member}**{reason}'
        ))

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(kick_members=True)
    @commands.bot_has_permissions(kick_members=True)
    async def kick(self, ctx, member: discord.Member, *, reason: str=''):
        """Kick a Member with an optional reason.

        **Example:**
        !kick @Guy#1337 - kicks Guy
        !Kick @Guy#1337 be nice - kick Guy and specifies the reason "be nice" for the Audit Log.
        """

        if ctx.message.guild.me.top_role.position <= member.top_role.position:
            return await ctx.send(embed=discord.Embed(
                title='Cannot kick:',
                description=('I cannot kick any Members that are in the same or higher position in the role hierarchy '
                             'as I am.'),
                colour=discord.Colour.red()
            ))
        await ctx.guild.kick(member, reason=f'Command invoked by {ctx.message.author}, reason: '
                                            f'{"No reason specified" if reason == "" else reason}.')
        reason = f' for *"{reason}"*.' if reason != '' else '.'
        await ctx.send(embed=discord.Embed(
            title='Kick successful',
            description=f'**Kicked {member}**{reason}',
            colour=discord.Colour.green()
        ))

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge(self, ctx, limit: int=100):
        """Purge a given amount of messages. Defaults to 100.

        Requires the `manage_messages` permission on both the Bot and
        the User that invokes the Command. Only works on Guilds.

        **Example:**
        purge - deletes 100 messages
        purge 50 - deletes 50 messages
        """

        total = sum(1 for _ in await ctx.message.channel.purge(
            limit=limit
        ))
        info_response = f'Purged a total of **{total} Messages**.'
        resp = await ctx.send(embed=discord.Embed(
            title='Purge completed',
            description=info_response
        ))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgeid')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_by_id(self, ctx, *ids_to_prune: int):
        """Purge up to 500 Messages sent by the User with the given ID.

        Useful when you want to purge Messages from a User that left the Server.

        **Example:**
        purgeid 129301
            searches the past 500 messages for messages from the user and purges them.
        purgeid 129301 128195
            searches the past 500 messages for messages from these ID's and purges them.
        """

        total = sum(1 for _ in await ctx.message.channel.purge(
            check=lambda m: m.author.id in ids_to_prune
        ))
        pruned = f'`{"`, `".join(str(x) for x in ids_to_prune)}`'
        info_response = f'Purged a total of **{total} Messages** sent by {pruned}.'
        resp = await ctx.send(embed=discord.Embed(
            title='Purge completed',
            description=info_response,
            colour=discord.Colour.green()
        ))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgemsg')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_messages(self, ctx, amount: str, *, message_contents: str):
        """Purges up to `amount` Messages with the specified content in them.

        **Example:**
        !purgemsg 30 evil
            deletes messages in the last 30 messages containing 'evil'
        !purgemsg 80 zalgo comes
            deletes messages in the last 80 messages containing 'zalgo comes'
        """

        if not amount.isdigit():
            return await ctx.send(embed=discord.Embed(
                title='Failed to Purge Messages:',
                description='You need to specify the amount of Messages to be purged for example `purge 30 evil`.',
                colour=discord.Colour.red()
            ))
        res = await ctx.message.channel.purge(
            check=lambda m: message_contents in m.content,
            limit=int(amount)
        )
        info_response = f'Purged a total of **{len(res)} Messages** containing `{message_contents}`.'
        resp = await ctx.send(embed=discord.Embed(
            title='Message purge completed',
            description=info_response,
            colour=discord.Colour.green()
        ))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgeuser')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_user(self, ctx, amount: str, *to_purge: discord.Member):
        """Purge a mentioned User, or a list of mentioned Users.

        The amount defaults to 100, but can be set manually.

        **Example:**
        purgeuser 300 @Person#1337 @Robot#7331
            purges messages from Person and Robot in the past 300 Messages.
        purgeuser 40 @Person#1337
            purges messages from Person in the past 40 Messages.
        """

        if not amount.isdigit():
            return await ctx.send(embed=discord.Embed(
                title='Failed to Purge Messages:',
                description=('You need to specify the amount of Messages to be purged for example '
                             '`purgeuser 30 @Guy#1337`.'),
                colour=discord.Colour.red()
            ))
        if not to_purge:
            return await ctx.send(embed=discord.Embed(
                title='Failed to purge User(s)',
                description='You need to mention at least one User to purge.',
                color=discord.Colour.red()
            ))
        total_purged = sum(1 for _ in await ctx.message.channel.purge(
            check=lambda m: m.author in to_purge,
            limit=int(amount)
        ))
        resp = await ctx.send(embed=discord.Embed(
            title='User purge completed',
            description=f'Purged a total of **{total_purged} Messages** from '
                        f'{", ".join(str(x) for x in to_purge)}.',
            colour=discord.Colour.green()
        ))
        await asyncio.sleep(5)
        await resp.delete()


def setup(bot):
    bot.add_cog(Mod(bot))
