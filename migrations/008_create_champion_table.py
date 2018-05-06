"""Peewee migrations -- 008_create_champion_table.py."""

import peewee as pw


class Champion(pw.Model):
    id = pw.IntegerField()
    guild_id = pw.BigIntegerField(primary_key=True)


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Champion)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('champion')
