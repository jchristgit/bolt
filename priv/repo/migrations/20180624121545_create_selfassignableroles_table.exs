defmodule Bolt.Repo.Migrations.CreateSelfassignablerolesTable do
  use Ecto.Migration

  def change do
    create table("selfassignableroles", comment: "Roles that are self-assignable by members") do
      add :guild_id, :bigint, [primary_key: true, comment: "The Discord guild ID these self-assignable roles are for"]
      add :roles, {:array, :bigint}, [null: false, comment: "The role IDs that are self-assignable on this Guild"]
    end
  end
end
