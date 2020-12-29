defmodule Bolt.Schema.Tag do
  @moduledoc "A tag with a name and content."

  alias Bolt.Helpers
  import Ecto.Changeset
  use Ecto.Schema

  schema "tags" do
    field(:author_id, :id)
    field(:guild_id, :id)

    field(:name, :string)
    field(:content, :string)

    timestamps(type: :utc_datetime)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(tag, params \\ %{}) do
    tag
    |> cast(params, [:author_id, :guild_id, :name, :content])
    |> validate_required([:author_id, :guild_id, :name, :content])
    |> check_constraint(:name, name: "name_not_blacklisted", message: "is blacklisted")
    |> check_constraint(:name,
      name: "name_no_guild_mentions",
      message: "must not contain @\u200Beveryone or @\u200Bhere"
    )
    |> check_constraint(:name,
      name: "name_length",
      message: "must be between 3 and 40 characters long"
    )
    |> check_constraint(:content,
      name: "content_length",
      message: "must be between 10 and 2000 characters long"
    )
    |> update_change(:name, &String.trim/1)
    |> update_change(:content, &String.trim/1)
    |> update_change(:name, &Helpers.clean_content/1)
    |> update_change(:content, &Helpers.clean_content/1)
    |> unique_constraint(:name, name: "tags_guild_id_name_index")
  end
end
