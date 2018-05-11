import asyncio
import itertools
import logging
import operator
from contextlib import suppress
from datetime import datetime

import discord
import peewee_async
from discord.ext import commands
from peewee import DoesNotExist

from bolt.database import objects
from .converters import ExpirationDate
from .models import Infraction, Mute, MuteRole
from .mutes import background_unmute_task, unmute_member
from .types import InfractionType


INFRACTION_TYPE_EMOJI = {
    InfractionType.note: '📔',
    InfractionType.warning: '⚠',
    InfractionType.mute: '🔇',
    InfractionType.kick: '👢',
    InfractionType.ban: '🔨'
}


log = logging.getLogger(__name__)


class Mod:
    """Moderation Commands for Guilds."""

    def __init__(self, bot):
        self.bot = bot
        self.unmute_task = None
        log.debug('Loaded Cog Mod.')

    def __unload(self):
        if self.unmute_task is not None:
            self.unmute_task.cancel()
        log.debug('Unloaded Cog Mod.')

    async def start_unmute_task(self):
        try:
            await background_unmute_task(self.bot)
        except asyncio.CancelledError:
            pass
        except Exception as e:
            log.error(f"Unhandled Exception in unmute task: {e}")

    async def restart_unmute_task(self):
        if self.unmute_task is not None:
            self.unmute_task.cancel()
        self.unmute_task = self.bot.loop.create_task(self.start_unmute_task())
        log.debug("Restarted unmute task.")

    async def on_ready(self):
        if self.unmute_task is None:
            self.unmute_task = self.bot.loop.create_task(self.start_unmute_task())
            log.debug("Started unmute task from `on_ready`")

    async def on_member_join(self, member: discord.Member):
        active_mute = await peewee_async.execute(
            Mute.select()
                .where(Mute.active == True,  # noqa
                       Infraction.user_id == member.id,
                       Infraction.guild_id == member.guild.id)
                .join(Infraction)
        )

        if not active_mute:
            return

        try:
            configured_mute_role = await objects.get(
                MuteRole,
                MuteRole.guild_id == member.guild.id
            )
        except DoesNotExist:
            pass
        else:
            mute_role = discord.utils.get(member.guild.roles, id=configured_mute_role.role_id)
            if mute_role is not None:
                await member.add_roles(
                    mute_role,
                    reason=f"User rejoined while still being muted, mute infraction ID: {active_mute.id}"
                )

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(kick_members=True)
    @commands.bot_has_permissions(kick_members=True)
    async def kick(self, ctx, member: discord.Member, *, reason: str=''):
        """Kick a Member with an optional reason.

        **Examples:**
        !kick @Guy#1337 - kicks Guy
        !kick @Guy#1337 spamming - kick Guy and specifies the reason "spamming" for the Audit Log.
        """

        if ctx.message.guild.me.top_role.position <= member.top_role.position:
            return await ctx.send(embed=discord.Embed(
                title='Cannot kick:',
                description=('I cannot kick any Members that are in the same or higher position in the role hierarchy '
                             'as I am.'),
                colour=discord.Colour.red()
             ))

        await ctx.guild.kick(
            member,
            reason=f'Command invoked by {ctx.message.author}, reason: '
                   f'{"No reason specified" if reason == "" else reason}.'
        )

        response = discord.Embed(
            title=f'Kicked `{member}` (`{member.id}`)',
            colour=discord.Colour.green()
        )
        response.set_footer(
            text=f'Kicked by {ctx.author} ({ctx.author.id})',
            icon_url=ctx.author.avatar_url
        )

        created_infraction = await objects.create(
            Infraction,
            type=InfractionType.kick,
            guild_id=ctx.guild.id,
            user_id=member.id,
            moderator_id=ctx.author.id,
            reason=reason
        )

        response.add_field(
            name='Reason',
            value=reason or 'no reason specified'
        ).add_field(
            name='Infraction',
            value=f'created with ID `{created_infraction.id}`'
        )
        await ctx.send(embed=response)

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(ban_members=True)
    @commands.bot_has_permissions(ban_members=True)
    async def ban(self, ctx, member: discord.Member, *, reason: str=''):
        """Ban a Member with an optional reason.

        **Examples:**
        !ban @Guy#1337
        !ban @Guy#1337 spamming - bans Guy and specifies the reason "spamming" for the audit Log.
        """

        if ctx.message.guild.me.top_role.position <= member.top_role.position:
            return await ctx.send(embed=discord.Embed(
                title='Cannot ban:',
                description=('I cannot ban any Members that are in the same '
                             'or higher position in the role hierarchy as I am.'),
                colour=discord.Colour.red()
            ))

        await ctx.guild.ban(
            member,
            reason=f'banned by command invocation from {ctx.message.author}, reason: '
                   f'{"No reason specified" if reason == "" else reason}.',
            delete_message_days=7
        )

        response = discord.Embed(
            title=f'Banned `{member}` (`{member.id}`)',
            colour=discord.Colour.green()
        ).set_footer(
            text=f'Banned by {ctx.author} ({ctx.author.id})',
            icon_url=ctx.author.avatar_url
        )

        if reason:
            response.description = f'**Reason**: {reason}'

        created_infraction = await objects.create(
            Infraction,
            type=InfractionType.ban,
            guild_id=ctx.guild.id,
            user_id=member.id,
            moderator_id=ctx.author.id,
            reason=reason
        )

        response.add_field(
            name='Reason',
            value=reason or 'no reason specified'
        ).add_field(
            name='Infraction',
            value=f'created with ID `{created_infraction.id}`'
        )

        await ctx.send(embed=response)

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def note(self, ctx, user: discord.User, *, note: str):
        """Add the given note to the infraction database for the given user.

        **Examples:**
        note @Person#1337 likes ducks
        """

        created_infraction = await objects.create(
            Infraction,
            type=InfractionType.note,
            guild_id=ctx.guild.id,
            user_id=user.id,
            moderator_id=ctx.author.id,
            reason=note
        )

        info_response = discord.Embed(
            title=f'Added a note for `{user}` (`{user.id}`)',
            description=f'View it in detail by using `infraction detail {created_infraction.id}`.',
            colour=discord.Colour.green()
        )
        info_response.set_footer(
            text=f'Note added by {ctx.author} ({ctx.author.id})',
            icon_url=ctx.author.avatar_url
        )
        await ctx.send(embed=info_response)

    @commands.command()
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def warn(self, ctx, user: discord.User, *, reason: commands.clean_content):
        """Warn the specified user with the given reason."""

        created_infraction = await objects.create(
            Infraction,
            type=InfractionType.warning,
            guild_id=ctx.guild.id,
            user_id=user.id,
            moderator_id=ctx.author.id,
            reason=reason
        )
        try:
            warn_embed = discord.Embed(
                title=f"You have been warned by a staff member on {ctx.guild} for the following reason:",
                description=reason,
                colour=0xFFCC00
            ).set_thumbnail(
                url=ctx.guild.icon_url
            )
            warn_embed.timestamp = datetime.utcnow()
            await user.send(embed=warn_embed)
        except discord.Forbidden:
            await ctx.send(embed=discord.Embed(
                title="Warned user has direct messages disabled.",
                description="If you want to warn them in a channel, reply with a mention of it. "
                            "Otherwise, simply reply `no`, or wait for `120` seconds.",
                colour=discord.Colour.dark_green()
            ))
            while True:
                try:
                    response = await self.bot.wait_for(
                        'message',
                        check=lambda m: m.guild == ctx.guild and m.author == ctx.author,
                        timeout=120
                    )
                except asyncio.TimeoutError:
                    await ctx.send(embed=discord.Embed(
                        title="Waiting for a response timed out. Not warning per direct message.",
                        colour=discord.Colour.green()
                    ))
                    break
                else:
                    if response.content == 'no':
                        await ctx.send(embed=discord.Embed(
                            title="Aborted warning the user per direct message.",
                            colour=discord.Colour.green()
                        ))
                        break

                    try:
                        channel = await commands.TextChannelConverter().convert(ctx, response.content)
                    except commands.BadArgument:
                        await ctx.send(embed=discord.Embed(
                            title=f"Failed to convert `{response.clean_content}` to a text channel - please retry.",
                            description="(expiring in `120` seconds)",
                            colour=discord.Colour.red()
                        ))
                    else:
                        await channel.send(user.mention, embed=discord.Embed(
                            title=f"`{user}` has been warned for the following reason:",
                            description=f"{reason}",
                            colour=0xFFCC00
                        ))
                        break

        info_response = discord.Embed(
            title=f'Warned user `{user}` (`{user.id}`)',
            colour=0xFFCC00
        ).add_field(
            name='Reason',
            value=reason or 'no reason specified'
        ).add_field(
            name='Infraction',
            value=f'created with ID `{created_infraction.id}`'
        ).set_footer(
            text=f'Authored by {ctx.author} ({ctx.author.id})',
            icon_url=user.avatar_url
        )
        await ctx.send(embed=info_response)

    @commands.group(invoke_without_command=True)
    @commands.guild_only()
    @commands.bot_has_permissions(manage_roles=True)
    @commands.has_permissions(manage_roles=True)
    async def mute(self, ctx, member: discord.Member, expiry: ExpirationDate, *, reason: str):
        """Mute the mentioned member for the given duration with an optional reason.

        To specify a duration spanning multiple words, use double quotes.
        """

        try:
            mute_role = await objects.get(
                MuteRole,
                MuteRole.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title=f'Cannot mute user `{member}` (`{member.id}`)',
                description='You need to set a role to assign with this command through `mute setrole` first.',
                colour=discord.Colour.red()
            ))
        else:
            role = discord.utils.get(ctx.guild.roles, id=mute_role.role_id)
            if role is None:
                return await ctx.send(embed=discord.Embed(
                    title=f'Cannot mute user `{member}` (`{member.id}`)',
                    description='The currently configured mute role could not '
                                'be found. Reconfigure it with `mute setrole`.',
                    colour=discord.Colour.red()
                ))

            elif role in member.roles:
                return await ctx.send(embed=discord.Embed(
                    title=f'Cannot mute user `{member}` (`{member.id}`)',
                    description=f'The user already has the role {role.mention} assigned, '
                                'and is therefore assumed to already be muted.',
                    colour=discord.Colour.red()
                ))

            active_user_mutes = await peewee_async.execute(
                Mute.select()
                    .where(Mute.active == True,  # noqa
                           Infraction.guild_id == ctx.guild.id,
                           Infraction.user_id == member.id)
                    .join(Infraction)
            )

            if not active_user_mutes:
                await member.add_roles(
                    role,
                    reason=f"Mute command invoked by {member} ({member.id}), expiry: {expiry}, reason: {reason}"
                )

                created_infraction = await objects.create(
                    Infraction,
                    type=InfractionType.mute,
                    guild_id=ctx.guild.id,
                    user_id=member.id,
                    moderator_id=ctx.author.id,
                    reason=reason
                )
                await objects.create(
                    Mute,
                    expiry=expiry,
                    infraction=created_infraction
                )

                # Restart the unmute task as it could be sleeping until a mute
                # with a later expiry than the newly created mute expires.
                await self.restart_unmute_task()

                response_embed = discord.Embed(
                    title=f'Muted user `{member}` (`{member.id}`)',
                    colour=discord.Colour.blue()
                ).add_field(
                    name='Reason',
                    value=reason or 'no reason specified'
                ).add_field(
                    name='Expiry',
                    value=str(expiry)
                ).add_field(
                    name='Infraction',
                    value=f'created with ID `{created_infraction.id}`'
                ).set_footer(
                    text=f'Authored by {ctx.author} ({ctx.author.id})',
                    icon_url=ctx.author.avatar_url
                )
                await ctx.send(embed=response_embed)

            else:
                active_mute = active_user_mutes[0]
                await ctx.send(embed=discord.Embed(
                    title=f'Cannot mute user `{member}` (`{member.id}`)',
                    description=f'A mute is already active under infraction ID `{active_mute.infraction.id}`, '
                                f'expiring at {str(active_mute.expiry)}. Edit it to change the mute.',
                    colour=discord.Colour.red()
                ))

    @mute.command(name='setrole')
    @commands.guild_only()
    @commands.has_permissions(manage_roles=True)
    async def mute_setrole(self, ctx, *, role: discord.Role):
        """Set the role to be used for muting users."""

        try:
            mute_role = await objects.get(
                MuteRole,
                MuteRole.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            pass
        else:
            await objects.delete(mute_role)

        await objects.create(
            MuteRole,
            guild_id=ctx.guild.id,
            role_id=role.id
        )

        info_embed = discord.Embed(
            title=f'Mute role was set to {role}.',
            colour=discord.Colour.green()
        ).set_footer(
            text=f'Authored by {ctx.author} ({ctx.author.id})',
            icon_url=ctx.author.avatar_url
        )
        await ctx.send(embed=info_embed)

    @commands.group(aliases=['infr', 'infractions'])
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def infraction(self, _):
        """Contains infraction management commands."""

    @infraction.command(name='edit')
    @commands.guild_only()
    @commands.has_permissions(administrator=True)
    async def infraction_edit(self, ctx, id_: int, *, new_reason: str):
        """Change the reason of the given infraction ID to the given new reason."""

        try:
            infraction = await objects.get(
                Infraction,
                Infraction.id == id_,
                Infraction.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title=f'Failed to find infraction #`{id_}` on this guild.',
                colour=discord.Colour.red()
            ))
        else:
            infraction.reason = new_reason
            await objects.update(infraction, only=['reason'])

            await ctx.send(embed=discord.Embed(
                title=f'Successfully edited infraction #`{id_}`.',
                description=f'**New reason**: {new_reason}',
                colour=discord.Colour.green()
            ))

    @infraction.command(name='delete')
    @commands.guild_only()
    @commands.has_permissions(administrator=True)
    @commands.bot_has_permissions(manage_roles=True)
    async def infraction_delete(self, ctx, id_: int):
        """Delete the given infraction from the database."""

        try:
            infraction = await objects.get(
                Infraction,
                Infraction.id == id_,
                Infraction.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title=f'Failed to find infraction #`{id_}` on this Guild.',
                colour=discord.Colour.red()
            ))
        else:
            info_response = discord.Embed(
                title=f'Successfully delete infraction #`{id_}`.',
                colour=discord.Colour.green()
            )

            if infraction.type == InfractionType.mute:

                # If an active mute for the original infraction was not found,
                # we can safely ignore the `DoesNotExist` error. This simply means
                # that there is no currently active mute, so we're done here.
                with suppress(DoesNotExist):
                    active_mute = await objects.get(
                        Mute,
                        active=True,
                        infraction_id=infraction.id
                    )
                    member = discord.utils.get(ctx.guild.members, id=infraction.user_id)
                    await unmute_member(member, ctx.guild, active_mute)
                    info_response.description = (
                        f"The accompanying mute expiring on {active_mute.expiry} "
                        "was also deleted, and the user was unmuted."
                    )

            await objects.delete(infraction)
            await ctx.send(embed=info_response)

    @infraction.command(name='detail')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def infraction_detail(self, ctx, id_: int):
        """Look up the given infraction ID in the database."""

        try:
            infraction = await objects.get(
                Infraction,
                Infraction.id == id_,
                Infraction.guild_id == ctx.guild.id
            )
        except DoesNotExist:
            await ctx.send(embed=discord.Embed(
                title=f'Failed to find infraction ID `{id_}`.',
                colour=discord.Colour.red()
            ))
        else:
            infraction_embed = discord.Embed(
                title=f'Infraction: `{infraction.id}`',
                colour=discord.Colour.blue()
            )

            infraction_user = self.bot.get_user(infraction.user_id)
            infraction_embed.add_field(
                name='User',
                value=(f'`{infraction_user}` (`{infraction_user.id}`)'
                       if infraction_user is not None else f'unknown user (`{infraction.user_id}`)')
            )

            infraction_embed.add_field(
                name='Type',
                value=f'{INFRACTION_TYPE_EMOJI[infraction.type]} {infraction.type.value.title()}'
            ).add_field(
                name='Creation',
                value=str(infraction.created_on)
            ).add_field(
                name='Last edited',
                value=str(infraction.edited_on or 'never')
            ).add_field(
                name='Reason',
                value=infraction.reason,
                inline=False
            )

            author_moderator = self.bot.get_user(infraction.moderator_id)
            if author_moderator is not None:
                infraction_embed.set_footer(
                    text=f'Authored by {author_moderator} ({author_moderator.id})',
                    icon_url=author_moderator.avatar_url
                )
            else:
                infraction_embed.set_footer(
                    text=f'Authored by unknown user (ID: {infraction.moderator_id})'
                )

            await ctx.send(embed=infraction_embed)

    @infraction.command(name='list')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def infraction_list(self, ctx, *types: InfractionType):
        """List all infractions, or infractions with the specified type(s)."""

        if types:
            all_infractions = await peewee_async.execute(
                Infraction.select()
                          .where(Infraction.guild_id == ctx.guild.id,
                                 Infraction.type.in_(types))
                          .order_by(Infraction.created_on.desc())
            )
            selected_types = "`, `".join(f"`{type_.value}`" for type_ in types)
            title = f'Infractions with types `{selected_types}` on {ctx.guild.name}'
        else:
            all_infractions = await peewee_async.execute(
                Infraction.select()
                          .where(Infraction.guild_id == ctx.guild.id)
                          .order_by(Infraction.created_on.desc())
            )
            title = f'All infractions on {ctx.guild.name}'

        list_embed_description = []
        for infraction in all_infractions:
            user = self.bot.get_user(infraction.user_id)
            if user is not None:
                user_string = f'`{user}` (`{user.id}`)'
            else:
                user_string = f'unknown user (`{infraction.user_id}`)'
            infraction_emoji = INFRACTION_TYPE_EMOJI[infraction.type]

            list_embed_description.append(
                f'• [`{infraction.id}`] {infraction_emoji} on {user_string} created {infraction.created_on}'
            )

        list_embed = discord.Embed(
            title=title,
            description='\n'.join(list_embed_description) or 'Seems like there\'s nothing here yet.',
            colour=discord.Colour.blue()
        )
        await ctx.send(embed=list_embed)

    @infraction.command(name='user')
    @commands.guild_only()
    @commands.has_permissions(manage_messages=True)
    async def infraction_user(self, ctx, *, user: discord.User):
        """Look up infractions for the specified user."""

        user_infractions = await peewee_async.execute(
            Infraction.select()
                      .where(Infraction.guild_id == ctx.guild.id,
                             Infraction.user_id == user.id)
                      .order_by(Infraction.type)
        )

        if not user_infractions:
            return await ctx.send(embed=discord.Embed(
                title=f'No recorded infractions for `{user}` (`{user.id}`).',
                colour=discord.Colour.blue()
            ))

        most_recent = max(user_infractions, key=operator.attrgetter('created_on'))
        response = discord.Embed(
            title=f'Infractions for `{user}` (`{user.id}`)',
            colour=discord.Colour.blue()
        ).set_footer(
            text=f'total infractions: {len(user_infractions)}, '
                 f'most recent: #{most_recent.id} at {most_recent.created_on}',
            icon_url=user.avatar_url
        )

        for infraction_type, infractions in itertools.groupby(user_infractions, key=operator.attrgetter('type')):
            response.add_field(
                name=f'{INFRACTION_TYPE_EMOJI[infraction_type]} {infraction_type.value}s',
                value='\n'.join(f'• [`{infraction.id}`] on {infraction.created_on}' for infraction in infractions)
            )

        await ctx.send(embed=response)
