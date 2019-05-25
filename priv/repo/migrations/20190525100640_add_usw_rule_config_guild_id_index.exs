defmodule Bolt.Repo.Migrations.AddUswRuleConfigGuildIdIndex do
  use Ecto.Migration

  def change do
    create(index("usw_rule_config", [:guild_id]))
  end
end
