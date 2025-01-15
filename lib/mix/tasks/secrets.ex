defmodule Mix.Tasks.Secrets do
  use Mix.Task
  @requirements ["app.start"]

  @moduledoc """
  fetches secrets from infisical
  """
  require Logger

  defp login!(client_id, client_secret) do
    resp =
      Req.new(url: "https://app.infisical.com/api/v1/auth/universal-auth/login")
      |> Req.Request.put_header("content-type", "application/x-www-form-urlencoded")
      |> Req.post!(
        form: [
          clientId: URI.encode_www_form(client_id),
          clientSecret: URI.encode_www_form(client_secret)
        ]
      )

    case resp.status do
      status when status >= 200 and status < 300 ->
        resp.body["accessToken"]

      _ ->
        raise("error in login: " <> to_string(resp.status))
    end
  end

  @spec list!(binary(), binary()) :: :ok
  defp list!(token, path) do
    uri =
      "https://app.infisical.com/api/v3/secrets/raw"
      |> URI.new!()
      |> URI.append_query(URI.encode_query(workspaceId: "a27d8691-0740-478f-842a-380ad56efa92"))
      |> URI.append_query(URI.encode_query(environment: "dev"))
      |> URI.append_query(URI.encode_query(secretPath: path))

    resp =
      Req.new(url: uri, auth: {:bearer, token})
      |> Req.get!()

    case resp.status do
      status when status >= 200 and status < 300 ->
        Enum.map(resp.body["secrets"], fn %{"secretKey" => key, "secretValue" => value} ->
          {key, value}
        end)

      _ ->
        raise("error in list: " <> to_string(resp.status))
    end
  end

  @spec createEnv(binary(), binary()) :: :ok | :error
  defp createEnv(folder, content) do
    {:ok, cwd} = File.cwd()
    path = Path.join([cwd, folder, ".env"])
    IO.write("Writing " <> path <> " ... ")

    case File.write(path, content) do
      {:error, :enoent} ->
        IO.puts("errored." <> " Directory doesn't exist.")
        :error

      {:error, reason} ->
        IO.puts("errored." <> to_string(reason))
        :error

      :ok ->
        IO.puts("done.")
    end
  end

  @impl Mix.Task
  def run([client_id, client_secret, path | []]) do
    login!(client_id, client_secret)
    |> list!(path)
    |> Enum.each(fn {path, content} ->
      createEnv(path, content)
    end)
  end

  def run(_args) do
    IO.puts("bad input")
    :error
  end
end
