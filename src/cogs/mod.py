import asyncio
import discord

from discord.ext import commands


class Mod:
    """Moderation Commands for Guilds. These require appropriate permission to execute."""
    def __init__(self, bot: commands.Bot):
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
        await ctx.guild.ban(member, reason=f'Command invoked by {ctx.message.author}, reason: '
                                           f'{"No reason specified" if reason is "" else reason}.',
                            delete_message_days=prune_days)
        reason = f' for *"{reason}"*.' if reason != '' else '.'
        await ctx.send(embed=discord.Embed(title='Ban successful',
                                           description=f'**Banned {member}**{reason}'))

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
            num = await self.bot.wait_for('message', check=lambda m: m.content.isdigit() and m.author == ctx.message.author,
                                          timeout=20)
        except asyncio.TimeoutError:
            await ctx.send(embed=discord.Embed(description='No User to unban was specified in time.',
                                               colour=discord.Colour.red()))
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
        await ctx.guild.kick(member, reason=f'Command invoked by {ctx.message.author}, reason: '
                                            f'{"No reason specified" if reason is "" else reason}.')
        reason = f' for *"{reason}"*.' if reason != '' else '.'
        await ctx.send(embed=discord.Embed(title='Kick successful',
                                           description=f'**Kicked {member}**{reason}'))

    @commands.group()
    @commands.guild_only()
    @commands.has_permissions(manage_channels=True)
    @commands.bot_has_permissions(manage_channels=True)
    async def channel(self, ctx):
        """Contains Commands for editing a Channel."""

    @channel.command(name='rename', aliases=['setname'])
    async def channel_set_name(self, ctx, *, new_name: str):
        """Change the Name for a Channel.
        
        Also works using `setname` instead of `rename`.
        
        **Example:**
        !channel rename announcements - rename the current channel to "announcements"
        """
        old_name = ctx.message.channel.name
        await ctx.message.channel.edit(name=new_name, reason=f'Invoked by {ctx.message.author}.')
        await ctx.send(embed=discord.Embed(description=f'Changed Channel Name from `#{old_name}` '
                                                       f'to <#{ctx.message.channel.id}>.',
                                           colour=discord.Colour.green()))

    @channel.command(name='desc', aliases=['setdesc'])
    async def channel_set_description(self, ctx, *, new_desc):
        """Set the description for the Channel.
        
        Also works using `setdesc` instead of `desc`.
        
        **Example:**
        !channel desc Bot Testing Channel - change the current channel's description to 'Bot Testing Channel'.
        """
        old_desc = ctx.message.channel.description
        await ctx.message.channel.edit(description=new_desc, reason=f'Invoked by {ctx.message.author}.')
        await ctx.send(embed=discord.Embed(description=f'Changed Channel Description from'
                                                       f' *"{old_desc}"* to *"{new_desc}"*.'))

    @channel.command(name='move')
    async def channel_move(self, ctx, amount: int):
        """Move a channel by the specified amount.
        
        Make sure that the channel position stays within the bounds.
        
        **Example:**
        !channel move 2 - moves the Channel up by two channels.
        !channel move -3 - moves the Channel down by three channels.
        """
        await ctx.message.channel.edit(position=ctx.message.channel.position - amount,
                                       reason=f'Invoked by {ctx.message.author}.')
        await ctx.send(embed=discord.Embed(description=f'**Channel moved {"up" if amount >= 0 else "down"}** by '
                                                       f'`{amount}` channels.'))

    @channel.command(name='find', aliases=['search'])
    @commands.cooldown(rate=3, per=120, type=commands.BucketType.channel)
    async def channel_search(self, ctx, *, contents: str):
        """Search for messages (in the past 500) containing the given message.
        
        May only be used three times per 2 minutes per channel.
        
        **Example:**
        !channel find hello - returns a list of messages containing "hello" in the past 500 messages.
        """
        messages = []
        async for message in ctx.message.channel.history(limit=500).filter(lambda m: contents in m.content):
            messages.append(f'{message.author.display_name}: {message.content}\n')
        response = f'**Messages found ({len(messages)}):**\n{"".join(messages)}'
        if len(response) >= 2000:
            await ctx.send(embed=discord.Embed(description='There are too many messages found to display.',
                                               colour=discord.Colour.red()))
        else:
            await ctx.send(embed=discord.Embed(description=response))

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
        res = await ctx.message.channel.purge(limit=limit, reason=f'Invoked by {ctx.message.author}.')
        info_response = f'Purged a total of **{len(res)} Messages**.'
        resp = await ctx.send(embed=discord.Embed(title='Purge completed', description=info_response))
        await asyncio.sleep(5)
        await resp.delete()

    @commands.command(name='purgeid')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    @commands.bot_has_permissions(manage_messages=True)
    async def purge_by_id(self, ctx, id_to_prune: int):
        """Purge up to 500 Messages sent by the User with the given ID.

        Useful when you want to purge Messages from a User that left the Server.
        
        **Example:**
        !purgeid 290324118665166849 - searches the past 500 messages for messages from the user and purges them.
        """
        res = await ctx.message.channel.purge(check=lambda m: m.author.id == id_to_prune,
                                              reason=f'Invoked by {ctx.message.author} to prune ID {id_to_prune}.')
        info_response = f'Purged a total of **{len(res)} Messages** sent by `{id_to_prune}`.'
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
        res = await ctx.message.channel.purge(check=lambda m: message_contents in m.content,
                                              reason=f'Invoked by {ctx.message.author}.')
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
            total_purged += len(await ctx.message.channel.purge(check=lambda m: m.author == user,
                                                                reason=f'Invoked by {ctx.message.author}.'))
        info_response = f'Purged a total of **{total_purged} Messages** from ' \
                        f'{", ".join(str(x) for x in ctx.message.mentions)}.'
        resp = await ctx.send(embed=discord.Embed(title='User purge completed', description=info_response))
        await asyncio.sleep(5)
        await resp.delete()


def setup(bot):
    bot.add_cog(Mod(bot))
