from enum import Enum


class InfractionType(Enum):
    note = 'note'
    warning = 'warning'
    mute = 'mute'
    kick = 'kick'
    ban = 'ban'
