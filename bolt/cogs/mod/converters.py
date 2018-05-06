from datetime import datetime

import dateparser
from discord.ext.commands import BadArgument, Converter


class ExpirationDate(Converter):
    async def convert(self, ctx, expiration_string: str):
        expiry = dateparser.parse(expiration_string)
        if expiry is None:
            raise BadArgument(f"Failed to parse expiration date `{expiration_string}`.")

        # Check if the given expiration date lies within the past.
        # This usually happens when not explicitly specifying whether
        # the date is within the future or in the past, for example "2 hours".
        now = datetime.now()
        if expiry < now:
            expiry = now + (now - expiry)

        return expiry
