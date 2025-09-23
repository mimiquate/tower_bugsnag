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

        config :tower_bugsnag,
          api_key: System.get_env("BUGSNAG_API_KEY"),
          release_stage: System.get_env("DEPLOYMENT_ENV", to_string(config_env()))
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
