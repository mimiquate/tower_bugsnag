defmodule TowerBugsnag.Bugsnag.Client do
  @api_key_header ~c"Bugsnag-Api-Key"
  @payloadVersion 5

  def send(event) do
    event
    |> payload()
    |> post()
  end

  defp payload(event) do
    %{
      apiKey: api_key(),
      payloadVersion: @payloadVersion,
      notifier: notifier(),
      events: [event]
    }
  end

  defp post(payload) when is_map(payload) do
    :httpc.request(
      :post,
      {
        ~c"#{base_url()}",
        [{@api_key_header, api_key()}],
        ~c"application/json",
        Jason.encode!(payload)
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          # Support wildcard certificates
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ],
      []
    )
  end

  defp notifier do
    %{
      name: "tower_bugsnag",
      version: "0.1.0",
      url: "https://hex.pm/packages/tower_bugsnag"
    }
  end

  defp api_key do
    Application.fetch_env!(:tower_bugsnag, :api_key)
  end

  defp base_url do
    Application.fetch_env!(:tower_bugsnag, :base_url)
  end
end
