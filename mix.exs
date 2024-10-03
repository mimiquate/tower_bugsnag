defmodule TowerBugsnag.MixProject do
  use Mix.Project

  @description "Error tracking and reporting to BugSnag"
  @source_url "https://github.com/mimiquate/tower_bugsnag"
  @version "0.1.3"

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
      env: [base_url: "https://notify.bugsnag.com", api_key: nil, environment: nil]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:tower, "~> 0.5.0"},

      # Dev
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false},

      # Test
      {:bypass, github: "mimiquate/bypass", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
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
