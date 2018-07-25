defmodule Bolt.Repo.Migrations.AddNewlinesToFilterNameEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE filter_name ADD VALUE 'NEWLINES';")
  end
end
