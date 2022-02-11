defmodule Bolt.Repo.Migrations.CreateActionGroups do
  use Ecto.Migration

  def change do
    # We let ecto manage the primary key here because we're sane
    create table(:action_group) do
      add :guild_id, :bigint, null: false
      add :name, :'varchar(30)', null: false
      add :deduplicate, :bool, null: false, default: true
    end

    create table(:action) do
      add :group_id, references(:action_group, on_delete: :delete_all), null: false
      add :module, :map, null: false
    end

    create unique_index(:action_group, [:name, :guild_id])
  end
end
