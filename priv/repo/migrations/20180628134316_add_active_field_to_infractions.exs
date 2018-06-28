defmodule Bolt.Repo.Migrations.AddActiveFieldToInfractions do
  use Ecto.Migration

  def change do
    alter table("infractions") do
      add(
        :active,
        :boolean,
        default: true,
        null: false,
        comment: "Whether this infraction currently applies (e.g. temporary ban)"
      )
    end
  end
end
