defmodule TowerBugsnag.MixProject do
  use Mix.Project

  def project do
    [
      app: :tower_bugsnag,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end
