defmodule Bolt.Repo.Migrations.MoveUswConstraintsToDatabase do
  use Ecto.Migration

  def change do
    create(constraint("usw_rule_config", :count_within_bounds, check: "count BETWEEN 2 AND 150"))

    create(
      constraint("usw_rule_config", :interval_within_bounds, check: "interval BETWEEN 5 AND 60")
    )
  end
end
