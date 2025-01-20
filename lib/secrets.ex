defmodule Secrets do
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

  defp list!(token, path, workspace_id, workspace_env) do
    uri =
      "https://app.infisical.com/api/v3/secrets/raw"
      |> URI.new!()
      |> URI.append_query(URI.encode_query(workspaceId: workspace_id))
      |> URI.append_query(URI.encode_query(environment: workspace_env))
      |> URI.append_query(URI.encode_query(secretPath: path))

    resp =
      Req.new(url: uri, auth: {:bearer, token})
      |> Req.get!()

    case resp.status do
      status when status >= 200 and status < 300 ->
        Enum.map(resp.body["secrets"], fn %{
                                            "secretKey" => key,
                                            "secretValue" => value,
                                            "tags" => tags
                                          } ->
          case tags do
            [] ->
              {key, value, ""}

            [tag | []] ->
              {key, value, tag["slug"]}
          end
        end)

      _ ->
        raise("error in list: " <> to_string(resp.status))
    end
  end

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

  # specialization of createEnv that takes a filename, replaces - with . and makes the file with that name instead
  defp createEnv(folder, content, filename) do
    {:ok, cwd} = File.cwd()
    fname = String.replace(filename, "-", ".")
    path = Path.join([cwd, folder, fname])
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

  def main(["pull", inf_path | []]) do
    Hush.resolve!()
    client_id = Application.get_env(:secrets, :client_id)
    client_secret = Application.get_env(:secrets, :client_secret)
    workspace_id = Application.get_env(:secrets, :workspace_id)
    workspace_env = Application.get_env(:secrets, :workspace_env)

    cond do
      client_id == "" ->
        IO.puts("CLIENT_ID not set")

      client_secret == "" ->
        IO.puts("CLIENT_SECRET not set")

      workspace_id == "" ->
        IO.puts("WORKSPACE_ID not set")

      workspace_env == "" ->
        IO.puts("WORKSPACE_ENV not set")

      true ->
        IO.puts("Pulling from workspace " <> workspace_id)
        IO.puts("Pulling from env " <> workspace_env)

        login!(client_id, client_secret)
        |> list!(inf_path, workspace_id, workspace_env)
        |> Enum.each(fn {inf_path, content, filename} ->
          case filename do
            "" ->
              createEnv(inf_path, content)

            _ ->
              createEnv(inf_path, content, filename)
          end
        end)
    end
  end
end
