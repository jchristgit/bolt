defmodule Bolt.Repo.Migrations.AlterTagNameTypeCitext do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION citext")

    alter table("tags") do
      modify(:name, :citext, from: :string)
    end
  end

  def down do
    alter table("tags") do
      modify(:name, :citext, from: :text)
    end

    execute("DROP EXTENSION citext")
  end
end
