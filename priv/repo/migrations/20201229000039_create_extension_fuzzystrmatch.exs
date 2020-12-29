defmodule Bolt.Repo.Migrations.CreateExtensionFuzzystrmatch do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION fuzzystrmatch", "DROP EXTENSION fuzzystrmatch")
  end
end
