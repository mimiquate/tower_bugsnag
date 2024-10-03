defmodule TowerBugsnagTest do
  use ExUnit.Case
  doctest TowerBugsnag

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    bypass = Bypass.open()

    Application.put_env(:tower_bugsnag, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:tower_bugsnag, :api_key, "test-api-key")
    Application.put_env(:tower_bugsnag, :release_stage, :test)
    Application.put_env(:tower, :reporters, [TowerBugsnag])

    on_exit(fn ->
      Application.put_env(:tower_bugsnag, :api_key, nil)
      Application.put_env(:tower_bugsnag, :release_stage, nil)
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
                          "lineNumber" => 69
                        }
                        | _
                      ]
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "unhandled" => true
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
                      "errorClass" => "(throw) \"something\"",
                      "message" => "\"something\"",
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
                  },
                  "unhandled" => true
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
                      "errorClass" => "(exit) :abnormal",
                      "message" => ":abnormal",
                      "stacktrace" => [
                        %{
                          "file" => "test/tower_bugsnag_test.exs",
                          "method" =>
                            ~s(anonymous fn/0 in TowerBugsnagTest."test reports abnormal exit"/1),
                          "lineNumber" => 171
                        }
                        | _
                      ]
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "unhandled" => true
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

  test "reports :gen_server bad exit", %{bypass: bypass} do
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
                      "errorClass" => "(exit) bad return value: \"bad value\"",
                      "message" => "bad return value: \"bad value\"",
                      "stacktrace" => [
                        %{
                          "file" => "test/tower_bugsnag_test.exs",
                          "method" =>
                            ~s(anonymous fn/0 in TowerBugsnagTest."test reports :gen_server bad exit"/1),
                          "lineNumber" => 222
                        }
                        | _
                      ]
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "unhandled" => true
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
          exit({:bad_return_value, "bad value"})
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
                  },
                  "unhandled" => true
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

  test "reports throw with Bandit", %{bypass: bypass} do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

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
                      "errorClass" => "(throw) \"something\"",
                      "message" => "\"something\"",
                      "stacktrace" => [
                        %{
                          "file" => "test/support/error_test_plug.ex",
                          "method" => ~s(anonymous fn/2 in TowerBugsnag.ErrorTestPlug.do_match/4),
                          "lineNumber" => 14
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
                  },
                  "unhandled" => true
                }
              ]
            }
          } = Jason.decode(body)
        )

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"ok" => true}))
      end)

      capture_log(fn ->
        start_supervised!(
          {Bandit, plug: TowerBugsnag.ErrorTestPlug, scheme: :http, port: plug_port}
        )

        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "reports Exception manually", %{bypass: bypass} do
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
                      "errorClass" => "RuntimeError",
                      "message" => "an error"
                    }
                  ],
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "unhandled" => false
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

      in_unlinked_process(fn ->
        try do
          raise "an error"
        rescue
          exception ->
            Tower.report_exception(exception, __STACKTRACE__)
        end
      end)
    end)
  end

  test "reports message", %{bypass: bypass} do
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
                      "errorClass" => "\"something interesting happened\"",
                      "message" => "\"something interesting happened\"",
                      "stacktrace" => []
                    }
                  ],
                  "severity" => "info",
                  "app" => %{
                    "releaseStage" => "test"
                  },
                  "unhandled" => false
                }
              ]
            }
          } = Jason.decode(body)
        )

        done.()

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, Jason.encode!(%{"ok" => true}))
      end)

      Tower.report_message(:info, "something interesting happened")
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
