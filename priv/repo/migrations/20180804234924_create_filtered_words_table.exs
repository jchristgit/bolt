defmodule Bolt.Repo.Migrations.AddFilteredWordsTable do
  use Ecto.Migration

  def change do
    create table("filtered_words", primary_key: false) do
      add(:guild_id, :bigint, primary_key: true)
      add(:word, :"varchar(70)", primary_key: true)
    end

    create(index("filtered_words", :guild_id))
  end
end
