defmodule Bolt.Repo.Migrations.UseBooleanForEscalationValue do
  use Ecto.Migration

  def up do
    alter table("usw_punishment_config") do
      remove(:escalate_by)

      add(
        :escalate,
        :boolean,
        default: false,
        comment: "Whether the punishment should automatically be escalated."
      )
    end
  end

  def down do
    alter table("usw_punishment_config") do
      add(
        :escalate_by,
        :real,
        default: nil,
        comment: "The exponential increase of the punishment, if enabled."
      )

      remove(:escalate)
    end
  end
end
