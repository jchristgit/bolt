"""Peewee migrations -- 001_create_prefix_table.py."""

import peewee as pw


class Prefix(pw.Model):
    guild_id = pw.BigIntegerField(primary_key=True)
    prefix = pw.CharField(max_length=25)


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(Prefix)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('prefix')
