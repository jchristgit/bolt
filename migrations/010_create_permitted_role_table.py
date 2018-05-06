"""Peewee migrations -- 010_create_permitted_role_table.py."""

import peewee as pw


class PermittedRole(pw.Model):
    id = pw.BigIntegerField()
    guild_id = pw.BigIntegerField()

    class Meta:
        primary_key = pw.CompositeKey('id', 'guild_id')


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(PermittedRole)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('permittedrole')
