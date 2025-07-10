if Code.ensure_loaded?(Tower.Igniter) do
  defmodule Mix.Tasks.TowerBugsnug.Task.InstallTest do
    use ExUnit.Case, async: true
    import Igniter.Test

    test "generates everything from scratch" do
      test_project()
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> assert_creates("config/config.exs", """
      import Config
      config :tower, reporters: [TowerBugsnug]
      """)
      |> assert_creates("config/runtime.exs", """
      import Config

      if config_env() == :prod do
        config :tower_bugsnug, api_key: System.get_env("BUGSNUG_API_KEY")
      end
      """)
    end

    test "modifies existing tower configs if available" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail]
          """,
          "config/runtime.exs" => """
          import Config
          """
        }
      )
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> assert_has_patch("config/config.exs", """
      |import Config
      |
      - |config :tower, reporters: [TowerEmail]
      + |config :tower, reporters: [TowerEmail, TowerBugsnug]
      """)
      |> assert_has_patch("config/runtime.exs", """
      |import Config
      |
      + |if config_env() == :prod do
      + |  config :tower_bugsnug, api_key: System.get_env("BUGSNUG_API_KEY")
      + |end
      + |
      """)
    end

    test "modifies existing tower configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            IO.puts("hello")
          end
          """
        }
      )
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> assert_has_patch("config/config.exs", """
      |import Config
      |
      - |config :tower, reporters: [TowerEmail]
      + |config :tower, reporters: [TowerEmail, TowerBugsnug]
      """)
      |> assert_has_patch("config/runtime.exs", """
      |if config_env() == :prod do
      |  IO.puts("hello")
      + |  config :tower_bugsnug, api_key: System.get_env("BUGSNUG_API_KEY")
      |end
      |
      """)
    end

    test "does not modify existing tower_bugsnug configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail, TowerBugsnug]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :tower_bugsnug, api_key: System.get_env("BUGSNUG_API_KEY")
          end
          """
        }
      )
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> assert_unchanged()
    end

    test "is idempotent" do
      test_project()
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("tower_bugsnug.install", [])
      |> assert_unchanged()
    end
  end
end
