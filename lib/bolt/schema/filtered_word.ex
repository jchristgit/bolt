defmodule Bolt.Schema.FilteredWord do
  @moduledoc "A filtered word in a guild."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "filtered_words" do
    field(:guild_id, :id, primary_key: true)
    field(:word, :string, primary_key: true)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(filtered_word, params \\ %{}) do
    filtered_word
    |> cast(params, [:guild_id, :word])
    |> validate_required([:guild_id, :word])
    |> validate_length(:word, max: 70)
  end
end
