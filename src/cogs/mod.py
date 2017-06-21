import asyncio
import dataset
import discord

from discord.ext import commands
from stuf import stuf

db = dataset.connect('sqlite:///data/guilds.db', row_type=stuf)
guild_prefixes = db['prefixes']


class Mod:
    """
    Moderation Commands for Guilds, such as kicking / banning or changing configuration.

    Keep in mind that although I'm not primarily intended for Moderation Commands,
    I still provide a bunch of them in case you will ever need it.
    """
    def __init__(self, bot: commands.Bot):
        self.bot = bot
        print('Loaded Cog Mod.')

    @staticmethod
    def __unload():
        print('Unloaded Cog Mod.')

    @commands.command(name='setprefix')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def set_prefix(self, ctx, *, new_prefix: str=''):
        """Change the prefix of this Guild for me to the given Prefix.

        To use a prefix that ends with a space, e.g. `botty lsar`, use `_` to set it,
        since spaces will get truncated by Discord automatically, for example:
        `setprefix botty_`
        `botty help`

        If you prefer being polite, you could use the following:
        `setprefix botty pls_`
        `botty pls help`

        Keep in mind that if you ever forget the prefix, I also react to mentions, so just mention me if you need help.
        Alternatively, to reset the prefix, just use this command
        without specifying a new prefix you wish to use, like `setprefix`.
        """
        if new_prefix == '':
            guild_prefixes.delete(guild_id=ctx.guild.id)
            await ctx.send(embed=discord.Embed(
                title='Reset this Guild\'s prefix',
                description='My prefix is now reset to `?` and `!`. Alternatively, you can mention me.',
                colour=discord.Colour.green()
            ))
        else:
            new_prefix = new_prefix.replace('_', ' ')
            guild_prefixes.upsert(dict(guild_id=ctx.guild.id, prefix=new_prefix), ['guild_id'])
            await ctx.send(embed=discord.Embed(
                title=f'Set Prefix to `{new_prefix}`{", with a space" if new_prefix[-1] == " " else ""}.',
                colour=discord.Colour.green()
            ))

    @set_prefix.error
    async def err_set_prefix(self, ctx: commands.Context, err: commands.CommandError):
        if not isinstance(err, commands.NoPrivateMessage):
            await ctx.send(embed=discord.Embed(
                title='Failed to set prefix:',
                description='You need the permission **`Manage Messages`** to use this Command.',
                colour=discord.Colour.red()
            ))

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
        if prune_days > 7 or prune_days < 1:
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
    @commands.has_permissions(ban_members=True)
    @commands.bot_has_permissions(ban_members=True)
    async def unban(self, ctx):
        """Interactively unban a User."""
        banned_users = await ctx.message.guild.bans()
        description = '**The following Users are banned. Specify which User you would like to unban by typing the ' \
                      'number of the User. This Message will get deleted in 20 seconds automatically.**\n '
        for idx, ban in enumerate(banned_users):
            description += f'**`{idx + 1}`**: {ban.user} {f"for *{ban.reason}*" if ban.reason is not None else ""}\n'
        ban_list = await ctx.send(embed=discord.Embed(title='Banned Members', description=description))
        try:
            num = await self.bot.wait_for(
                'message',
                check=lambda m: m.content.isdigit() and m.author == ctx.message.author,
                timeout=20
            )
        except asyncio.TimeoutError:
            await ctx.send(embed=discord.Embed(
                description='No User to unban was specified in time.',
                colour=discord.Colour.red()
            ))
        else:
            num = int(num.content)
            if num < 1 or num > len(banned_users) + 1:
                await ctx.send(embed=discord.Embed(description='Invalid Number specified.'))
            else:
                await ctx.message.guild.unban(banned_users[num - 1].user, reason=f'Invoked by {ctx.message.author}.')
                unban_notification = await ctx.send(embed=discord.Embed(
                    description=f'Successfully unbanned **{banned_users[num - 1].user}**k')
                )
                await asyncio.sleep(5)
                await unban_notification.delete()
        finally:
            await ban_list.delete()

    @ban.error
    @unban.error
    async def err_bans(self, ctx: commands.Context, err: commands.CommandError):
        if not isinstance(err, commands.NoPrivateMessage) and not isinstance(err, commands.BadArgument):
            await ctx.send(embed=discord.Embed(
                title='Error while banning or unbanning',
                description=('The Bot as well as the command invoker (you) need to have the permission '
                             '**`Ban Members`**. Please make sure the permission is given and '
                             'retry the Command if so.'),
                colour=discord.Colour.red()
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

    @kick.error
    async def err_kick(self, ctx: commands.Context, err: commands.CommandError):
        if not isinstance(err, commands.NoPrivateMessage) and not isinstance(err, commands.BadArgument):
            await ctx.send(embed=discord.Embed(
                title='Error while modifying Channels:',
                description=('The Bot as well as the command invoker (you) need to have the permission '
                             '**`Kick Members`**. Please make sure the permission is given and '
                             'retry the Command if so.'),
                colour=discord.Colour.red()
            ))

    @commands.group()
    @commands.guild_only()
    async def channel(self, ctx):
        """Contains Commands for editing a Channel."""

    @channel.command(name='rename', aliases=['setname'])
    @commands.has_permissions(manage_channels=True)
    @commands.bot_has_permissions(manage_channels=True)
    async def channel_set_name(self, ctx, *, new_name: str):
        """Change the Name for a Channel.
        
        Also works using `setname` instead of `rename`.
        
        **Example:**
        !channel rename announcements - rename the current channel to "announcements"
        """
        old_name = ctx.message.channel.name
        await ctx.message.channel.edit(name=new_name, reason=f'Invoked by {ctx.message.author}.')
        await ctx.send(embed=discord.Embed(
            description=f'Changed Channel Name from `#{old_name}` to <#{ctx.message.channel.id}>.',
            colour=discord.Colour.green()
        ))

    @channel.command(name='desc', aliases=['setdesc'])
    @commands.has_permissions(manage_channels=True)
    @commands.bot_has_permissions(manage_channels=True)
    async def channel_set_description(self, ctx, *, new_desc):
        """Set the description for the Channel.
        
        Also works using `setdesc` instead of `desc`.
        
        **Example:**
        !channel desc Bot Testing Channel - change the current channel's description to 'Bot Testing Channel'.
        """
        old_desc = ctx.message.channel.description
        await ctx.message.channel.edit(description=new_desc, reason=f'Invoked by {ctx.message.author}.')
        await ctx.send(embed=discord.Embed(
            description=f'Changed Channel Description from *"{old_desc}"* to *"{new_desc}"*.',
            colour=discord.Colour.green()
        ))

    @channel.command(name='move')
    @commands.has_permissions(manage_channels=True)
    @commands.bot_has_permissions(manage_channels=True)
    async def channel_move(self, ctx, amount: int):
        """Move a channel by the specified amount.
        
        Make sure that the channel position stays within the bounds.
        
        **Example:**
        !channel move 2 - moves the Channel up by two channels.
        !channel move -3 - moves the Channel down by three channels.
        """
        curr_pos = ctx.message.channel.position
        offset = curr_pos - amount
        maximum = sum(1 for _ in ctx.message.guild.text_channels)
        if offset < 0 or offset > maximum:
            await ctx.send(embed=discord.Embed(
                title='Failed to move Channel:',
                description=(f'The channel must not be moved below `{maximum}` or above `0`, this channel\'s position '
                             f'is `{curr_pos}`, so this Command can be used with arguments ranging from '
                             f'`-{maximum - curr_pos - 1}` to `{curr_pos}`.'),
                colour=discord.Colour.red()
            ))
        else:
            await ctx.message.channel.edit(
                position=ctx.message.channel.position - amount,
                reason=f'Invoked by {ctx.message.author}.'
            )
            await ctx.send(embed=discord.Embed(
                description=f'**Channel moved {"up" if amount >= 0 else "down"}** by `{amount}` channels.',
                colour=discord.Colour.green()
            ))

    @channel_set_name.error
    @channel_set_description.error
    @channel_move.error
    async def err_channel_modify(self, ctx: commands.Context, err: commands.CommandError):
        if not isinstance(err, commands.NoPrivateMessage):
            await ctx.send(embed=discord.Embed(
                title='Error while modifying Channels:',
                description=('The Bot as well as the command invoker (you) need to have the permission '
                             '**`Manage Channels`**. Please make sure the permission is given and '
                             'retry the Command if so.'),
                colour=discord.Colour.red()
            ))

    @channel.command(name='find', aliases=['search'])
    @commands.cooldown(rate=3, per=120, type=commands.BucketType.channel)
    async def channel_search(self, ctx, *, contents: str):
        """Search for messages (in the past 500) containing the given message.
        
        **Example:**
        !channel find hello - returns a list of messages containing "hello" in the past 500 messages.
        """
        messages = []
        async for message in ctx.message.channel.history(limit=500).filter(lambda m: contents in m.content):
            messages.append(f'{message.author.display_name}: {message.content}\n')
        response = f'**Messages found ({len(messages)}):**\n{"".join(messages)}'
        if len(response) >= 2000:
            await ctx.send(embed=discord.Embed(
                description='There are too many messages found to display. Try a more specific search term.',
                colour=discord.Colour.red()
            ))
        else:
            await ctx.send(embed=discord.Embed(
                description=response,
                colour=discord.Colour.blue()
            ))

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge(self, ctx, limit: int=100):
        """Purge a given amount of messages. Defaults to 100.
        
        Requires the `manage_messages` permission on both the Bot and the User that invokes the Command.
        Only works on Guilds.
        
        **Example:**
        purge - deletes 100 messages
        purge 50 - deletes 50 messages
        """
        total = sum(1 for _ in await ctx.message.channel.purge(
            limit=limit,
            reason=f'Invoked by {ctx.message.author}.'
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
        purgeid 129301 - searches the past 500 messages for messages from the user and purges them.
        purgeid 129301 128195 - searches the past 500 messages for messages from these ID's and purges them.
        """
        total = sum(1 for _ in await ctx.message.channel.purge(
            check=lambda m: m.author.id in ids_to_prune,
            reason=f'Invoked by {ctx.message.author} to prune ID {", ".join(str(x) for x in ids_to_prune)}.'
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
        !purgemsg 30 evil - deletes messages in the last 30 messages containing 'evil'
        !purgemsg 80 zalgo comes - deletes messages in the last 80 messages containing 'zalgo comes'
        """
        if not amount.isdigit():
            return await ctx.send(embed=discord.Embed(
                title='Failed to Purge Messages:',
                description='You need to specify the amount of Messages to be purged for example `purge 30 evil`.',
                colour=discord.Colour.red()
            ))
        res = await ctx.message.channel.purge(
            check=lambda m: message_contents in m.content,
            reason=f'Invoked by {ctx.message.author}.',
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
        """Purge a mentioned User, or a list of mentioned Users. The amount defaults to 100, but can be set manually.
        
        **Example:**
        purgeuser 300 @Person#1337 @Robot#7331 - purges messages from Person and Robot in the past 300 Messages.
        purgeuser 40 @Person#1337 - purges messages from Person in the past 40 Messages.
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
            reason=f'Invoked by {ctx.message.author}.',
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

    @purge.error
    @purge_by_id.error
    @purge_messages.error
    @purge_user.error
    async def err_purge(self, ctx: commands.Context, error: commands.CommandError):
        if not isinstance(error, commands.NoPrivateMessage):
            await ctx.send(embed=discord.Embed(
                title='Failed to purge Messages:',
                description=('The Bot as well as the command invoker (you) need to have the permission '
                             '**`Manage Messages`**. Please make sure the permission is given and '
                             'retry the Command if so.'),
                colour=discord.Colour.red()
            ))


def setup(bot):
    bot.add_cog(Mod(bot))
