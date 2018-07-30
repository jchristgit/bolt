defmodule Bolt.Schema.USWRuleConfig do
  @moduledoc "Configuration for the rules applied by USW."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "usw_rule_config" do
    field(:guild_id, :id, primary_key: true)
    field(:rule, :string, primary_key: true)
    field(:count, :integer)
    field(:interval, :integer)
  end

  @spec changeset(Changeset.t(), map()) :: Changeset.t()
  def changeset(config, params \\ %{}) do
    config
    |> cast(params, [:guild_id, :rule, :count, :interval])
    |> validate_required([:guild_id, :rule, :count, :interval])
    |> validate_inclusion(:count, 2..150, message: "needs to be within 3 and 120")
    |> validate_inclusion(:interval, 5..60, message: "needs to be within 5 and 60")
    |> validate_inclusion(:rule, existing_rules())
  end

  @spec existing_rules :: [String.t()]
  def existing_rules do
    [
      "BURST",
      "DUPLICATES",
      "LINKS",
      "MENTIONS",
      "NEWLINES"
    ]
  end
end
