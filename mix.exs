defmodule Keila.MixProject do
  use Mix.Project

  def project do
    [
      app: :keila,
      version: "0.14.7",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      mod: {Keila.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto, "~> 3.13"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:floki, ">= 0.34.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.1"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.0"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:swoosh, "~> 1.20"},
      {:gen_smtp, "~> 1.2"},
      {:hackney, "~> 1.20"},
      {:hashids, "~> 2.0"},
      {:argon2_elixir, "~> 2.4"},
      {:httpoison, "~> 1.8"},
      {:nimble_csv, "~> 1.3"},
      {:nimble_parsec, "~> 1.4"},
      {:oban, "~> 2.20"},
      {:solid, "~> 1.2.2"},
      {:earmark, "~> 1.4"},
      {:tzdata, "~> 1.1"},
      {:ex_aws, "~> 2.6.0"},
      {:sweet_xml, "~> 0.6"},
      {:ex_aws_ses, "~> 2.4.1"},
      {:php_serializer, "~> 2.0"},
      {:open_api_spex, "~> 3.22"},
      {:ex_rated, "~> 2.1"},
      {:tls_certificate_check, "~> 1.31"},
      {:mjml, "~> 5.0"},
      {:ex_cldr, "~> 2.44"},
      {:ex_cldr_territories, "~> 2.11"},
      {:xlsx_reader, "~> 0.8"},
      {:lazy_html, ">= 0.0.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "esbuild default --minify",
        "cmd --cd assets npm run deploy",
        "cmd cp -R assets/static/* priv/static/",
        "phx.digest"
      ]
    ]
  end
end
