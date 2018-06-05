from asyncio import TimeoutError
from typing import List

from discord import Embed
from discord.ext.commands import Context


MOVE_LEFT_REACTION = '👈'
MOVE_RIGHT_REACTION = '👉'
DELETE_REACTION = '🗑'
VALID_REACTIONS = (MOVE_LEFT_REACTION, MOVE_RIGHT_REACTION, DELETE_REACTION)


class LinePaginator:
    def __init__(self, ctx: Context, lines: List[str], lines_per_page: int, embed: Embed):
        self.ctx = ctx
        self.pages = tuple(
            '\n'.join(lines[n:n + lines_per_page])
            for n in range(0, len(lines), lines_per_page)
        )
        self.embed = embed

    async def send(self, timeout: int = 60 * 5):
        if len(self.pages) == 1:
            # No need to paginate. We're done here.
            self.embed.description = self.pages[0]
            return await self.ctx.send(embed=self.embed)

        self.embed.set_footer(text=f"Page 1 / {len(self.pages)}")
        self.embed.description = self.pages[0]
        message = await self.ctx.send(embed=self.embed)
        for reaction in VALID_REACTIONS:
            await message.add_reaction(reaction)

        current_index = 0
        while True:
            try:
                def check(reaction, user):
                    return (user != self.ctx.bot.user
                            and reaction.message.id == message.id
                            and str(reaction) in VALID_REACTIONS)

                reaction, author = await self.ctx.bot.wait_for(
                    'reaction_add',
                    check=check,
                    timeout=timeout
                )
            except TimeoutError:
                self.embed.set_footer(text=f"{self.embed.footer.text} (inactive)")
                await message.edit(embed=self.embed)
            else:
                if str(reaction) == MOVE_LEFT_REACTION and current_index != 0:
                    current_index -= 1
                    self.embed.description = self.pages[current_index]
                    self.embed.set_footer(text=f"Page {current_index + 1} / {len(self.pages)}")
                    await message.remove_reaction(MOVE_LEFT_REACTION, author)
                    await message.edit(embed=self.embed)
                elif str(reaction) == MOVE_RIGHT_REACTION and current_index != len(self.pages) - 1:
                    current_index += 1
                    self.embed.description = self.pages[current_index]
                    self.embed.set_footer(text=f"Page {current_index + 1} / {len(self.pages)}")
                    await message.remove_reaction(MOVE_RIGHT_REACTION, author)
                    await message.edit(embed=self.embed)
                elif str(reaction) == DELETE_REACTION:
                    await message.delete()
                    break
