"""Peewee migrations -- 013_allow_infraction_reason_null.py."""

import peewee as pw


def migrate(migrator, database, fake=False, **kwargs):
    """Write your migrations here."""

    migrator.drop_not_null('infraction', 'reason')


def rollback(migrator, database, fake=False, **kwargs):
    """Write your rollback migrations here."""

    migrator.add_not_null('infraction', 'reason')
