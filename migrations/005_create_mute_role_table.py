"""Peewee migrations -- 005_create_mute_role_table.py."""

import peewee as pw


class MuteRole(pw.Model):
    guild_id = pw.BigIntegerField()
    role_id = pw.BigIntegerField()

    class Meta:
        primary_key = pw.CompositeKey('guild_id', 'role_id')


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(MuteRole)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('muterole')
