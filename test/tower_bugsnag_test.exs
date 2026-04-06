defmodule TowerBugsnagTest do
  use ExUnit.Case
  doctest TowerBugsnag

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    {:ok, test_server} = TestServer.start()

    put_env(:tower_bugsnag, :base_url, TestServer.url(test_server))
    put_env(:tower_bugsnag, :api_key, "test-api-key")
    put_env(:tower_bugsnag, :app_version, "0.1.0")
    put_env(:tower_bugsnag, :release_stage, :test)
    put_env(:tower, :reporters, [TowerBugsnag])

    {:ok, test_server: test_server}
  end

  test "reports arithmetic error", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => true
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          1 / 0
        end)
      end)
    end)
  end

  test "reports throw", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                            "lineNumber" => 127
                          }
                          | _
                        ]
                      }
                    ],
                    "app" => %{
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => true
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          throw("something")
        end)
      end)
    end)
  end

  test "reports abnormal exit", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                            "lineNumber" => 184
                          }
                          | _
                        ]
                      }
                    ],
                    "app" => %{
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => true
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          exit(:abnormal)
        end)
      end)
    end)
  end

  test "reports :gen_server bad exit", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                            "lineNumber" => 241
                          }
                          | _
                        ]
                      }
                    ],
                    "app" => %{
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => true
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          exit({:bad_return_value, "bad value"})
        end)
      end)
    end)
  end

  test "includes exception request data if available with Plug.Cowboy", %{
    test_server: test_server
  } do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                            "method" =>
                              ~s(anonymous fn/2 in TowerBugsnag.ErrorTestPlug.do_match/4),
                            "lineNumber" => 8
                          }
                          | _
                        ]
                      }
                    ],
                    "app" => %{
                      "version" => "0.1.0",
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
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

      start_supervised!(
        {Plug.Cowboy, plug: TowerBugsnag.ErrorTestPlug, scheme: :http, port: plug_port}
      )

      capture_log(fn ->
        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "reports throw with Bandit", %{test_server: test_server} do
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                            "method" =>
                              ~s(anonymous fn/2 in TowerBugsnag.ErrorTestPlug.do_match/4),
                            "lineNumber" => 14
                          }
                          | _
                        ]
                      }
                    ],
                    "app" => %{
                      "version" => "0.1.0",
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
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"ok" => true}))
        end
      )

      capture_log(fn ->
        start_supervised!(
          {Bandit, plug: TowerBugsnag.ErrorTestPlug, scheme: :http, port: plug_port}
        )

        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "reports Exception manually", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => false
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"id" => "123"}))
        end
      )

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

  test "reports message", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
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
                      "version" => "0.1.0",
                      "releaseStage" => "test"
                    },
                    "unhandled" => false
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"ok" => true}))
        end
      )

      Tower.report_message(:info, "something interesting happened")
    end)
  end

  test "properly reports elixir terms in metadata whithout a JSON native formatting", %{
    test_server: test_server
  } do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)

          assert(
            {
              :ok,
              %{
                "events" => [
                  %{
                    "exceptions" => [
                      %{
                        "errorClass" => "\"something\"",
                        "message" => "\"something\""
                      }
                    ],
                    "severity" => "info",
                    "metaData" => %{
                      "function" => "#Function<" <> _,
                      "pid" => "#PID<" <> _,
                      "port" => ["#Port<" <> _ | _],
                      "ref" => "#Reference<" <> _,
                      "{:one, :two}" => "{:three, :four}",
                      "keyword" => ["{:a, #PID<" <> _, "{:b, #PID<" <> _],
                      "struct_with_json_impl" => "2000-01-01"
                    }
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"ok" => true}))
        end
      )

      Tower.report_message(
        :info,
        "something",
        metadata: %{
          :function => fn x -> x end,
          :pid => self(),
          :port => Port.list(),
          :ref => make_ref(),
          {:one, :two} => {:three, :four},
          :keyword => [a: self(), b: self()],
          :struct_with_json_impl => %Date{year: 2000, month: 01, day: 01}
        }
      )
    end)
  end

  test "supports user information (using user key)", %{
    test_server: test_server
  } do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)

          assert(
            {
              :ok,
              %{
                "events" => [
                  %{
                    "exceptions" => [
                      %{
                        "errorClass" => "\"something\"",
                        "message" => "\"something\""
                      }
                    ],
                    "severity" => "info",
                    "user" => %{
                      "id" => 1,
                      "name" => "Test User",
                      "email" => "test@example.com"
                    },
                    "metaData" => %{
                      "user" => %{"extra_key" => "extra"}
                    }
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"ok" => true}))
        end
      )

      Tower.report_message(
        :info,
        "something",
        metadata: %{
          user: %{id: 1, name: "Test User", email: "test@example.com", extra_key: "extra"}
        }
      )
    end)
  end

  test "supports user information (using user_id key)", %{
    test_server: test_server
  } do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)

          assert(
            {
              :ok,
              %{
                "events" => [
                  %{
                    "exceptions" => [
                      %{
                        "errorClass" => "\"something\"",
                        "message" => "\"something\""
                      }
                    ],
                    "severity" => "info",
                    "user" => %{
                      "id" => 1
                    }
                  }
                ]
              }
            } = TowerBugsnag.json_module().decode(body)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, TowerBugsnag.json_module().encode!(%{"ok" => true}))
        end
      )

      Tower.report_message(
        :info,
        "something",
        metadata: %{
          user_id: 1
        }
      )
    end)
  end

  test "logs client request error message", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(
            400,
            TowerBugsnag.json_module().encode!(nil)
          )
        end
      )

      assert capture_log(fn ->
               assert :ok = Tower.report_message(:info, "something")

               Process.sleep(100)
             end) =~
               ~r/\[TowerBugsnag\] Error reporting event to BugSnag: {400, "null"}/
    end)
  end

  test "logs BugSnag internal server error", %{test_server: test_server} do
    waiting_for(fn done ->
      TestServer.add(
        test_server,
        "/",
        via: :post,
        to: fn conn ->
          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(500, TowerBugsnag.json_module().encode!(nil))
        end
      )

      assert capture_log(fn ->
               assert :ok = Tower.report_message(:info, "something")

               Process.sleep(100)
             end) =~
               ~r/\[TowerBugsnag\] Error reporting event to BugSnag: {500, "null"}/
    end)
  end

  test "logs network error" do
    put_env(:tower_bugsnag, :base_url, "")

    assert capture_log(fn ->
             assert :ok = Tower.report_message(:info, "something")

             Process.sleep(100)
           end) =~ ~r/\[TowerBugsnag\] Error reporting event to BugSnag: {:no_scheme}/
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

  defp put_env(app, key, value) do
    original_value = Application.get_env(app, key)
    Application.put_env(app, key, value)

    on_exit(fn ->
      if original_value == nil do
        Application.delete_env(app, key)
      else
        Application.put_env(app, key, original_value)
      end
    end)
  end
end
