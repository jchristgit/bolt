"""Peewee migrations -- 003_create_infraction_table.py."""

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
    edited_on = pw.DateTimeField(default=datetime.utcnow)  # ON UPDATE handled through trigger
    type = EnumField(InfractionType)
    user_id = pw.BigIntegerField()
    moderator_id = pw.BigIntegerField()
    reason = pw.CharField(max_length=250)


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Infraction)
    migrator.sql("""
        CREATE FUNCTION update_edited_timestamp() RETURNS TRIGGER AS $$
        BEGIN
            IF row(NEW.*) IS DISTINCT FROM row(OLD.*) THEN
                NEW.edited_on := (NOW() AT TIME ZONE 'UTC');
                RETURN NEW;
            END IF;

            RETURN OLD;
        END;
        $$ LANGUAGE plpgsql;
    """)
    migrator.sql("""
        CREATE TRIGGER update_edited_timestamp_trigger BEFORE UPDATE ON infraction
        FOR EACH ROW EXECUTE PROCEDURE update_edited_timestamp();
    """)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.sql("""
        DROP TRIGGER update_edited_timestamp_trigger ON infraction;
    """)
    migrator.sql("""
        DROP FUNCTION update_edited_timestamp;
    """)
    migrator.drop_table('infraction')
