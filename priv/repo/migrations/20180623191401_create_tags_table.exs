defmodule Bolt.Repo.Migrations.CreateTagsTable do
  use Ecto.Migration

  def change do
    create table("tags", comment: "User-created tags") do
      add(:author_id, :bigint, null: false, comment: "Discord user ID of the tag author")
      add(:guild_id, :bigint, null: false, comment: "Discord guild ID the tag was created on")

      add(
        :name,
        :string,
        size: 40,
        null: false,
        comment: "Tag name, used for searches and as the title"
      )

      add(
        :content,
        :string,
        size: 2000,
        null: false,
        comment: "Tag content, usually in Discord's markdown"
      )

      timestamps(type: :utc_datetime)
    end

    create(index("tags", [:guild_id, :name], unique: true))
  end
end
