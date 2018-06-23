defmodule Bolt.Schema.Tag do
  @moduledoc "A tag with a name and content."

  @disallowed_name_tokens [
    "@everyone",
    "@here"
  ]
  @disallowed_names [
    "create",
    "del",
    "help",
    "modify",
    "delete",
    "del",
    "edit",
    "raw",
    "rm",
    "insert",
    "push",
    "pop",
    "recent",
    "remove",
    "replace",
    "show",
    "update",
  ]

  import Ecto.Changeset
  use Ecto.Schema

  schema "tags" do
    field(:author_id, :id)
    field(:guild_id, :id)

    field(:name, :string)
    field(:content, :string)

    timestamps(type: :utc_datetime)
  end

  def changeset(tag, params \\ %{}) do
    alias Bolt.Helpers

    tag
    |> cast(params, [:author_id, :guild_id, :name, :content])
    |> validate_required([:author_id, :guild_id, :name, :content])
    |> update_change(:name, &String.trim/1)
    |> update_change(:content, &String.trim/1)
    |> validate_length(:name, min: 3, max: 40, count: :codepoints)
    |> validate_length(:content, min: 10, max: 2000, count: :codepoints)
    |> validate_exclusion(:name, @disallowed_names)
    |> validate_change(:name, fn :name, name ->
      cond do
        Enum.any?(@disallowed_name_tokens, &String.contains?(name, &1)) ->
          [name: "must not contain @\u200Beveryone or @\u200Bhere"]

        true ->
          []
      end
    end)
    |> update_change(:name, &Helpers.clean_content/1)
    |> update_change(:content, &Helpers.clean_content/1)
    |> unique_constraint(:name, name: "tags_guild_id_name_index")
    |> validate_name_unique_for_guild()
  end

  defp validate_name_unique_for_guild(changeset) do
    alias Bolt.Repo
    alias Bolt.Helpers
    import Ecto.Query, only: [from: 2]

    name = get_field(changeset, :name)
    guild_id = get_field(changeset, :guild_id)

    existing_names =
      from(tag in __MODULE__, where: tag.guild_id == ^guild_id, select: tag.name)
      |> Repo.all()

    case Enum.find_index(
           existing_names,
           &(String.jaro_distance(String.downcase(&1), String.downcase(name)) > 0.7)
         ) do
      nil ->
        changeset

      index ->
        similar_tag = Enum.fetch!(existing_names, index)

        error_message =
          "is too similar to existing tag name #{Helpers.clean_content(similar_tag)}"

        add_error(changeset, :name, error_message)
    end
  end
end
