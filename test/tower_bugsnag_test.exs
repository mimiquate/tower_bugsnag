defmodule TowerBugsnagTest do
  use ExUnit.Case
  doctest TowerBugsnag

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    bypass = Bypass.open()

    Application.put_env(:tower_bugsnag, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:tower_bugsnag, :api_key, "test-api-key")
    Application.put_env(:tower_bugsnag, :environment, :test)
    Application.put_env(:tower, :reporters, [TowerBugsnag])
    Tower.attach()

    on_exit(fn ->
      Tower.detach()
      Application.put_env(:tower_bugsnag, :api_key, nil)
      Application.put_env(:tower_bugsnag, :environment, nil)
      Application.put_env(:tower, :reporters, [])
    end)

    {:ok, bypass: bypass}
  end

  test "reports arithmetic error", %{bypass: bypass} do
    waiting_for(fn done ->
      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert(
          {
            :ok,
            %{
              "events" => [
                %{
                  "exceptions" => [
                    %{
                      "errorClass" => "ArithmeticError",
                      "message" => "bad argument in arithmetic expression",
                      "stacktrace" => stacktrace_entries
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  }
                }
              ]
            }
          } = Jason.decode(body)
        )

        assert(
          %{
            "file" => "test/tower_bugsnag_test.exs",
            "method" => ~s(anonymous fn/0 in TowerBugsnagTest."test reports arithmetic error"/1),
            "lineNumber" => 70
          } = List.first(stacktrace_entries)
        )

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
      end)

      capture_log(fn ->
        in_unlinked_process(fn ->
          1 / 0
        end)
      end)
    end)
  end

  defp waiting_for(fun) do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    fun.(fn ->
      send(parent, {ref, :sent})
    end)

    assert_receive({^ref, :sent}, 500)
  end

  defp in_unlinked_process(fun) when is_function(fun, 0) do
    {:ok, pid} = Task.Supervisor.start_link()

    pid
    |> Task.Supervisor.async_nolink(fun)
    |> Task.yield()
  end
end
