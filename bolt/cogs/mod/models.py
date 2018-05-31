import peewee

from bolt.cogs.infractions.models import Infraction
from bolt.database import Model


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
