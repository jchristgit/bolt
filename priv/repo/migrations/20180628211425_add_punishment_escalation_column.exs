defmodule Bolt.Repo.Migrations.AddPunishmentEscalation do
  use Ecto.Migration

  def change do
    alter table("usw_punishment_config") do
      add(
        :escalate_by,
        :real,
        default: nil,
        comment: "The exponential increase of the punishment, if enabled."
      )
    end

    create(
      constraint(
        "usw_punishment_config",
        "escalation_value_must_be_greater_than_1",
        check: "escalate_by IS NULL OR escalate_by > 1"
      )
    )

    create(
      constraint(
        "usw_punishment_config",
        "escalation_value_must_be_smaller_than_or_equal_to_3",
        check: "escalate_by IS NULL OR escalate_by <= 3"
      )
    )
  end
end
