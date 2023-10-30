defmodule GeoIpServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :geo_ip_server,
      version: "1.0.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: ["test.ci": :test],
      consolidated_protocols: Mix.env() != :test,
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/project.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications:
        if Mix.env() == :prod do
          [:logger, :runtime_tools]
        else
          [:logger, :runtime_tools, {:observer, :optional}, {:wx, :optional}]
        end,
      mod: {GeoIpServer.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~>1.20"},
      {:ecto_ip_range, "~> 0.2.0"},
      {:ecto_sql, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:nebulex, "~> 2.5"},
      {:nimble_csv, "~> 1.1"},
      {:observer_cli, "~> 1.7"},
      {:phoenix, "~> 1.7.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:shards, "~> 1.1"},
      {:telemetry, "~> 1.2"},
      {:benchee, "~> 1.1", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:meck, "~> 0.9", only: [:test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.drop", "ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "test.ci": ["ecto.drop", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
