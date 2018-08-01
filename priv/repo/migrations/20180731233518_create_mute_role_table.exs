defmodule Bolt.Repo.Migrations.CreateMuteRoleTable do
  use Ecto.Migration

  def change do
    create table("mute_role", primary_key: false) do
      add(:guild_id, :bigint, primary_key: true)
      add(:role_id, :bigint, null: false)
    end
  end
end
