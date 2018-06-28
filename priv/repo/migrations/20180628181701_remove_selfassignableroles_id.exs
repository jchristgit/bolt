defmodule Bolt.Repo.Migrations.RemoveSelfassignablerolesId do
  use Ecto.Migration

  def up do
    alter table("selfassignableroles") do
      remove(:id)
    end
  end

  def down do
    alter table("selfassignableroles") do
      add(:id, :bigint, primary_key: true)
    end
  end
end
