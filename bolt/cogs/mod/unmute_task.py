import asyncio
import datetime

import discord

from .models import mute as mute_db, infraction as infraction_db, mute_role as mute_role_db


async def background_unmute_task(bot):
    while True:
        query = (mute_db.select()
                 .order_by(mute_db.c.expiry)
                 .where(mute_db.c.active.is_(True))
                 .join(infraction_db)
                 .select())

        result = await bot.db.execute(query)
        rows = await result.fetchall()

        for row in rows:
            # The mute table is ordered by expiry.
            # If the current expiry lies in the future, we can stop here,
            # as all further mutes will also expire in the future.
            if row.expiry > datetime.datetime.now():
                break

            query = (mute_role_db.select()
                     .where(mute_role_db.c.guild_id == row.guild_id))
            result = await bot.db.execute(query)
            role_row = await result.first()

            guild = bot.get_guild(row.guild_id)
            mute_role = discord.utils.get(guild.roles, id=role_row.role_id)
            member = discord.utils.get(guild.members, id=row.user_id)

            await member.remove_roles(mute_role)

            query = (mute_db.update()
                     .where(mute_db.c.infraction_id == row.infraction_id)
                     .values(active=False))
            await bot.db.execute(query)

        # Find the mute that expires next, default to 5 minutes from now.
        sleep_until = next(
            (row.expiry for row in rows if row.expiry > datetime.datetime.now()),
            datetime.datetime.now() + datetime.timedelta(minutes=5)
        )
        total_seconds = (sleep_until - datetime.datetime.now()).total_seconds()

        # Sleep for either the time given above, or at most for 1 hour.
        await asyncio.sleep(min(total_seconds, 60 * 60))
