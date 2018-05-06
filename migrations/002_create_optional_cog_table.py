"""Peewee migrations -- 002_create_optional_cog_table.py."""

import peewee as pw


class OptionalCog(pw.Model):
    id = pw.IntegerField(primary_key=True)
    name = pw.CharField(max_length=20)
    guild_id = pw.BigIntegerField()


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(OptionalCog)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('optionalcog')
