from datetime import datetime

import dateparser
from discord.ext.commands import BadArgument, Converter


DATEPARSER_SETTINGS = {
    'PREFER_DATES_FROM': 'future',
    'TIMEZONE': 'UTC',
    'TO_TIMEZONE': 'UTC'
}


class ExpirationDate(Converter):
    async def convert(self, ctx, expiration_string: str):
        expiry = dateparser.parse(expiration_string, settings=DATEPARSER_SETTINGS)
        if expiry is None:
            raise BadArgument(f"Failed to parse expiration date from `{expiration_string}`")

        now = datetime.utcnow()
        if expiry < now:
            expiry = now + (now - expiry)

        return expiry
