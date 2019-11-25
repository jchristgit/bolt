defmodule Bolt.Repo.Migrations.IncreaseReasonWidth do
  use Ecto.Migration

  def change do
    alter table("infractions") do
      modify(:reason, :"VARCHAR(2000)", from: :"VARCHAR(255)")
    end
  end
end
