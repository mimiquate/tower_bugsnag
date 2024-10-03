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
                      "stacktrace" => [
                        %{
                          "file" => "test/tower_bugsnag_test.exs",
                          "method" =>
                            ~s(anonymous fn/0 in TowerBugsnagTest."test reports arithmetic error"/1),
                          "lineNumber" => 70
                        }
                        | _
                      ]
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

  test "reports throw", %{bypass: bypass} do
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
                      "errorClass" => "(throw) something",
                      "message" => "something",
                      "stacktrace" => [
                        %{
                          "file" => "test/tower_bugsnag_test.exs",
                          "method" =>
                            ~s(anonymous fn/0 in TowerBugsnagTest."test reports throw"/1),
                          "lineNumber" => 120
                        }
                        | _
                      ]
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

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
      end)

      capture_log(fn ->
        in_unlinked_process(fn ->
          throw("something")
        end)
      end)
    end)
  end

  test "reports abnormal exit", %{bypass: bypass} do
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
                      "errorClass" => "(exit) abnormal",
                      "message" => "abnormal",
                      "stacktrace" => [
                        %{
                          "file" => "test/tower_bugsnag_test.exs",
                          "method" =>
                            ~s(anonymous fn/0 in TowerBugsnagTest."test reports abnormal exit"/1),
                          "lineNumber" => 170
                        }
                        | _
                      ]
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

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
      end)

      capture_log(fn ->
        in_unlinked_process(fn ->
          exit(:abnormal)
        end)
      end)
    end)
  end

  test "includes exception request data if available with Plug.Cowboy", %{bypass: bypass} do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

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
                      "stacktrace" => [
                        %{
                          "file" => "test/support/error_test_plug.ex",
                          "method" => ~s(anonymous fn/2 in TowerBugsnag.ErrorTestPlug.do_match/4),
                          "lineNumber" => 8
                        }
                        | _
                      ]
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "request" => %{
                    "httpMethod" => "GET",
                    "url" => ^url,
                    "headers" => %{"user-agent" => "httpc client"}
                  }
                }
              ]
            }
          } = Jason.decode(body)
        )

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
      end)

      start_supervised!(
        {Plug.Cowboy, plug: TowerBugsnag.ErrorTestPlug, scheme: :http, port: plug_port}
      )

      capture_log(fn ->
        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
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
