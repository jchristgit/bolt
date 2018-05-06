"""Peewee migrations -- 006_create_self_assignable_role_table.py."""

import peewee as pw


class SelfAssignableRole(pw.Model):
    id = pw.BigIntegerField(primary_key=True)
    name = pw.CharField(150)
    guild_id = pw.BigIntegerField()


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(SelfAssignableRole)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('selfassignablerole')
