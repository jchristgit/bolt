defmodule Bolt.Repo.Migrations.MoveTagChecksIntoDatabase do
  use Ecto.Migration

  def change do
    create(constraint("tags", :name_length, check: "length(name) BETWEEN 3 AND 40"))
    create(constraint("tags", :content_length, check: "length(content) BETWEEN 10 AND 2000"))

    create(
      constraint("tags", :name_not_blacklisted,
        check:
          "name NOT IN ('create', 'del', 'delete', 'edit', 'help', 'info', 'insert', 'modify', 'pop', 'push', 'raw', 'recent', 'remove', 'replace', 'rm', 'show', 'update')"
      )
    )

    create(
      constraint("tags", :name_no_guild_mentions,
        check: "position('@everyone' IN name) = 0 AND position('@here' IN name) = 0"
      )
    )
  end
end
