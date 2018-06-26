defmodule Bolt.Schema.USWFilterConfig do
  @moduledoc "Configuration for the filters applied by USW."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "usw_filter_config" do
    field(:guild_id, :id)
    field(:filter, :string)
    field(:count, :integer)
    field(:interval, :integer)
  end

  @spec changeset(Changeset.t(), map()) :: Changeset.t()
  def changeset(config, params \\ %{}) do
    config
    |> cast(params, [:guild_id, :filter, :count, :interval])
    |> validate_required([:guild_id, :filter, :count, :interval])
    |> validate_inclusion(:count, 3..15)
    |> validate_inclusion(:count, 5..60)
    |> validate_inclusion(:filter, existing_filters())
  end

  @spec existing_filters :: [String.t()]
  def existing_filters do
    [
      "BURST"
    ]
  end
end
