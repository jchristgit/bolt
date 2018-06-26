defmodule Bolt.Repo.Migrations.CreateUswFilterConfigTable do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE TYPE filter_name AS ENUM (
        'BURST',
        'MENTIONS',
        'DUPLICATES'
      );
      """,
      "DROP TYPE filter_name;"
    )

    create table(
             "usw_filter_config",
             primary_key: false,
             comment: "Per-guild Configuration for the USW filters"
           ) do
      add(
        :guild_id,
        :bigint,
        primary_key: true,
        comment: "The Discord guild ID this configuration row applies to"
      )

      add(
        :filter,
        :filter_name,
        primary_key: true,
        comment: "The filter that is configured by this row"
      )

      add(
        :count,
        :int,
        null: false,
        comment: "The count of objects the filter shall let pass through"
      )

      add(
        :interval,
        :int,
        null: false,
        comment:
          "The interval in which the filter should allow the given objects through, in seconds"
      )
    end

    create(
      constraint(
        "usw_filter_config",
        "count_must_be_positive",
        check: "count > 0"
      )
    )

    create(
      constraint(
        "usw_filter_config",
        "interval_must_be_positive",
        check: "interval > 0"
      )
    )
  end
end
