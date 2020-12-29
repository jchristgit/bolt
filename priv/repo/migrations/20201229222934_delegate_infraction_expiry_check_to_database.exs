defmodule Bolt.Repo.Migrations.DelegateInfractionExpiryCheckToDatabase do
  use Ecto.Migration

  def change do
    create(
      constraint("infractions", :expiry_required_on_timed_infractions,
        check: "type::text NOT LIKE 'temp%' OR expires_at IS NOT NULL"
      )
    )
  end
end
