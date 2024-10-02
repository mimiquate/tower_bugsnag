defmodule TowerBugsnag.MixProject do
  use Mix.Project

  @description "Error tracking and reporting to BugSnag"
  @source_url "https://github.com/mimiquate/tower_bugsnag"
  @version "0.1.0"

  def project do
    [
      app: :tower_bugsnag,
      description: @description,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

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

      # Test
      {:bypass, github: "mimiquate/bypass", only: :test}
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
end
