defmodule Bolt.MixProject do
  use Mix.Project

  def project do
    [
      app: :bolt,
      version: "0.11.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Bolt.Application, []},
      applications: [:ecto, :postgrex, :nostrum]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:ecto, "~> 2.2"},
      {:postgrex, "~> 0.13"},
      {:timex, "~> 3.1"},
      {:aho_corasick, "~> 0.0.1"},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.migrate --quiet", "test --no-start"]
    ]
  end
end
