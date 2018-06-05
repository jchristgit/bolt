"""Peewee migrations -- 012_create_stafflog_module.py."""

import peewee as pw


class StaffLogChannel(pw.Model):
    guild_id = pw.BigIntegerField(primary_key=True)
    channel_id = pw.BigIntegerField()
    enabled = pw.BooleanField()


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.create_model(StaffLogChannel)


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.drop_table('stafflogchannel')
