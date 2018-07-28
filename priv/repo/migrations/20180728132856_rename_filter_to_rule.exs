defmodule Bolt.Repo.Migrations.RenameFilterToRule do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE usw_filter_config RENAME TO usw_rule_config")
    execute("ALTER TABLE usw_rule_config RENAME COLUMN filter TO rule")
  end

  def down do
    execute("ALTER TABLE usw_rule_config RENAME COLUMN rule TO filter")
    execute("ALTER TABLE usw_rule_config RENAME TO usw_filter_config")
  end
end
