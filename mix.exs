defmodule Bolt.MixProject do
  use Mix.Project

  def project do
    [
      app: :bolt,
      version: "0.11.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [coveralls: :test],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Bolt.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Discord interfacing
      {:nosedrum, "~> 0.2"},
      {:nostrum, github: "Kraigie/nostrum", override: true},

      # PostgreSQL interfacing
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:postgrex, "~> 0.14"},

      # Monitoring
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_httpd, "~> 2.1"},

      # Miscellaneous
      {:timex, "~> 3.1"},
      # See https://github.com/edgurgel/httpoison/issues/393
      {:hackney, ">= 1.15.2", override: true},

      # Linting
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.migrate --quiet", "test --no-start"]
    ]
  end
end
