defmodule Bolt.MixProject do
  use Mix.Project

  def project do
    [
      app: :bolt,
      version: "0.7.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Bolt.Application, []},
      # applications: [:timex],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:ecto, "~> 2.2"},
      {:postgrex, "~> 0.13"},
      {:timex, "~> 3.1"},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test, runtime: false}
    ]
  end
end
