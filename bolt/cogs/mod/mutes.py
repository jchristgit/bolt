import asyncio
import datetime

import discord
import peewee_async
from peewee import DoesNotExist

from bolt.database import objects
from .models import Infraction, Mute, MuteRole


async def background_unmute_task(bot):
    while True:
        active_mutes = await peewee_async.execute(
            Mute.select()
                .order_by(Mute.expiry.asc())
                .where(Mute.active == True)  # noqa
        )

        for mute in active_mutes:
            # The mute table is ordered by expiry.
            # If the current expiry lies in the future, we can stop here,
            # as all further mutes will also expire in the future.
            if mute.expiry > datetime.datetime.utcnow():
                break

            try:
                configured_mute_role = await objects.get(
                    MuteRole,
                    MuteRole.guild_id == mute.infraction.guild_id
                )
            except DoesNotExist:
                # The guild does not have any mute role configured.
                # That means we cannot unmute the user, so log it.
                continue

            guild = bot.get_guild(mute.infraction.guild_id)

            mute_role = discord.utils.get(guild.roles, id=configured_mute_role.role_id)
            # The previously configured mute role can no longer be found on the Guild.
            if mute_role is None:
                continue

            member = discord.utils.get(guild.members, id=mute.infraction.user_id)
            if member is not None:
                await member.remove_roles(mute_role)
            else:
                # The member that should be released from the mute is no longer present on the Guild.
                # Emit a warning.
                pass

            # We've removed the mute role, or the member was not present on the guild anymore anyways.
            #  Remove the `active` flag for this mute.
            mute.active = False
            await objects.update(mute, only=['active'])

        # Sleep until the next mute we found expires, or 1 hour at most.
        # Default to sleeping for 1 hour if no active mute was found.
        if active_mutes:
            diff_seconds = (mute.expiry - datetime.datetime.utcnow()).total_seconds()
            sleep_seconds = min(diff_seconds, 60 * 60)
        else:
            sleep_seconds = 60 * 60

        # Sleep for either the time given above, or at most for 1 hour.
        await asyncio.sleep(sleep_seconds)


async def unmute_member(member: discord.Member, guild: discord.Guild, mute: Mute):
    try:
        configured_mute_role = await objects.get(
            MuteRole,
            MuteRole.guild_id == guild.id
        )

    except DoesNotExist:
        raise ValueError("no mute role is configured on this guild, cannot unmute")

    else:
        mute_role = discord.utils.get(guild.roles, id=configured_mute_role.role_id)
        if mute_role is None:
            raise ValueError(
                f"cannot find the configured mute role with ID `{configured_mute_role.role_id}` on this guild"
            )

        await member.remove_roles(mute_role)

        mute.active = False
        await objects.update(mute, only=['active'])
