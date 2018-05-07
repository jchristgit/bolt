from datetime import datetime

import peewee

from bolt.database import EnumField, Model
from .types import InfractionType


class Infraction(Model):
    guild_id = peewee.BigIntegerField()
    created_on = peewee.DateTimeField(default=datetime.utcnow)
    edited_on = peewee.DateTimeField(default=datetime.utcnow)  # ON UPDATE handled through trigger
    type = EnumField(InfractionType)
    user_id = peewee.BigIntegerField()
    moderator_id = peewee.BigIntegerField()
    reason = peewee.CharField(max_length=250)


class Mute(Model):
    active = peewee.BooleanField(default=True)
    expiry = peewee.DateTimeField()
    infraction = peewee.ForeignKeyField(
        Infraction,
        primary_key=True,
        on_delete='CASCADE'
    )


class MuteRole(Model):
    guild_id = peewee.BigIntegerField()
    role_id = peewee.BigIntegerField()

    class Meta:
        primary_key = peewee.CompositeKey('guild_id', 'role_id')
