"""Peewee migrations -- 004_create_mute_table.py."""

from datetime import datetime
from enum import Enum

import peewee as pw


class EnumField(pw.CharField):
    def __init__(self, enum, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._enum = enum

    def db_value(self, value):
        return value.name

    def python_value(self, value):
        return self._enum(value)


class InfractionType(Enum):
    note = 'note'
    warning = 'warning'
    mute = 'mute'
    kick = 'kick'
    ban = 'ban'


class Infraction(pw.Model):
    guild_id = pw.BigIntegerField()
    created_on = pw.DateTimeField(default=datetime.utcnow)
    edited_on = pw.DateTimeField(
        default=datetime.utcnow,
        constraints=[
            pw.SQL(
                "ON UPDATE (NOW() AT TIME ZONE 'UTC')"
            )
        ]
    )
    type = EnumField(InfractionType)
    user_id = pw.BigIntegerField()
    moderator_id = pw.BigIntegerField()
    reason = pw.CharField(max_length=250)


class Mute(pw.Model):
    active = pw.BooleanField(default=True)
    expiry = pw.DateTimeField()
    infraction = pw.ForeignKeyField(
        Infraction,
        primary_key=True,
        on_delete='CASCADE'
    )


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Mute)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('mute')
