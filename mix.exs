defmodule TowerBugsnag.MixProject do
  use Mix.Project

  @description "Exception tracking and reporting to Insight Hub (formerly BugSnag)"
  @source_url "https://github.com/mimiquate/tower_bugsnag"
  @changelog_url @source_url <> "/blob/-/CHANGELOG.md"
  @version "0.3.6"

  def project do
    [
      app: :tower_bugsnag,
      description: @description,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "TowerBugsnag",
      source_url: @source_url,
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :public_key],
      env: [
        base_url: "https://notify.bugsnag.com",
        api_key: nil,
        app_version: nil,
        release_stage: nil
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tower, "~> 0.7.1 or ~> 0.8.0"},

      # Optional
      # Only needed for Elixir < 1.18
      {:jason, "~> 1.4", optional: true},

      # Dev
      {:ex_doc, "~> 0.37.1", only: :dev, runtime: false},
      {:blend, "~> 0.5.0", only: :dev},

      # Test
      {:bandit, "~> 1.5", only: :test},
      {:lasso, "~> 0.1.4", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @changelog_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
