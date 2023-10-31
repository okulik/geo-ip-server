defmodule GeoIpServer.Downloader do
  @moduledoc """
  The module for downloading files from URLs.
  """

  @http_receive_timeout 150_000

  require Logger

  @doc """
    Downloads the file from the URL and saves it to the target directory.
    File download supports big files as it uses streams i.e. file is downloaded
    in chunks. Function returns the path to the downloaded file in local
    file system.
  """
  def download_from_url(url, target_dir) do
    file_name = get_file_name!(url)
    save_path = Path.join([target_dir, file_name])

    stream_url(url)
    |> Stream.into(File.stream!(save_path))
    |> Stream.run()

    file_name
  end

  @doc """
    Generates a random string of the given length.
  """
  def random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  defp get_file_name!(url) do
    case :hackney.head(url) do
      {:ok, 200, headers} ->
        headers
        |> Enum.into(%{})
        |> Map.get("Content-Disposition")
        |> String.replace("attachment; filename=", "")

      {:ok, 401, _} ->
        raise "unauthorised"

      {:ok, 400, _} ->
        raise "bad request"

      {:ok, error_code, _} ->
        raise "unexpected error #{error_code}"
    end
  end

  defp stream_url(url) do
    Stream.resource(
      fn -> begin_download(url) end,
      &continue_download/1,
      &finish_download/1
    )
  end

  defp begin_download(url) do
    {:ok, _status, headers, client} =
      :hackney.get(url, [], <<>>, recv_timeout: @http_receive_timeout)

    total_size =
      headers
      |> Enum.into(%{})
      |> Map.get("Content-Length")
      |> String.to_integer()

    {client, total_size, 0, url, System.monotonic_time(:millisecond)}
  end

  defp continue_download({client, total_size, size, url, t0}) do
    case :hackney.stream_body(client) do
      {:ok, data} ->
        new_size = size + byte_size(data)
        {[data], {client, total_size, new_size, url, t0}}

      :done ->
        {:halt, {client, total_size, size, url, t0}}

      {:error, reason} ->
        raise reason
    end
  end

  defp finish_download({client, total_size, size, url, t0}) do
    :hackney.close(client)
    t1 = System.monotonic_time(:millisecond)

    Logger.debug(
      "Complete download #{cleanup_string(url)}, #{size}(#{total_size}) bytes, took #{t1 - t0} ms"
    )
  end

  defp cleanup_string(str), do: String.replace(str, ~r/&license_key=.*/, "")
end
