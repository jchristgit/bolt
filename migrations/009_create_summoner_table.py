"""Peewee migrations -- 009_create_summoner_table.py."""

import peewee as pw


class Summoner(pw.Model):
    id = pw.BigIntegerField(primary_key=True)
    guild_id = pw.BigIntegerField()
    region = pw.FixedCharField(4)


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Summoner)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('summoner')
