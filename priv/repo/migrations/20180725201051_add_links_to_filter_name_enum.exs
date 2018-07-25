defmodule Bolt.Repo.Migrations.AddLinksToFilterNameEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE filter_name ADD VALUE 'LINKS';")
  end
end
