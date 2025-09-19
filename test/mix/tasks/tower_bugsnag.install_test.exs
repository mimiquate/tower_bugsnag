if Code.ensure_loaded?(Tower.Igniter) do
  defmodule Mix.Tasks.TowerBugsnag.Task.InstallTest do
    use ExUnit.Case, async: true
    import Igniter.Test

    test "generates everything from scratch" do
      test_project()
      |> Igniter.compose_task("tower_bugsnag.install", [])
      |> assert_creates(
        "config/config.exs",
        """
        import Config
        config :tower, reporters: [TowerBugsnag]
        """
      )
      |> assert_creates(
        "config/runtime.exs",
        """
        import Config

        if config_env() == :prod do
          config :tower_bugsnag,
            api_key: System.get_env("BUGSNAG_API_KEY")
        end
        """
      )
    end

    test "is idempotent" do
      test_project()
      |> Igniter.compose_task("tower_bugsnag.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("tower_bugsnag.install", [])
      |> assert_unchanged()
    end
  end
end
