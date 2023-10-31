defmodule GeoIpServer.DownloaderTest do
  use ExUnit.Case

  import :meck, only: [expect: 3, expect: 4, seq: 1]

  alias GeoIpServer.Downloader

  setup_all do
    headers_head = [
      {"Content-Disposition", "attachment; filename=GeoLite2-City-CSV_20231027.zip.sha256"}
    ]

    headers_get = [
      {"Content-Length", "97"}
    ]

    body =
      "507080d84b95b5c383bc9aa950aa9f4f09c1fd01f227a33959daf9d93fa6ff31  GeoLite2-City-CSV_20231027.zip"

    expect(:hackney, :head, fn _ -> {:ok, 200, headers_head} end)
    expect(:hackney, :get, fn _, _, _, _ -> {:ok, 200, headers_get, nil} end)
    expect(:hackney, :stream_body, 1, seq([{:ok, body}, :done]))
    expect(:hackney, :close, fn _ -> :ok end)

    [body: body]
  end

  describe "downloader tests" do
    test "download_from_url/2 downloads the file from the URL and saves it to the target directory",
         context do
      temp_dir = Path.join([System.tmp_dir!(), Downloader.random_string(10)])
      File.mkdir_p!(temp_dir)

      try do
        file_name = Downloader.download_from_url("http://geolocation.db.com", temp_dir)
        file_path = Path.join([temp_dir, file_name])
        {:ok, body} = File.read(file_path)

        assert body == context[:body]
      after
        File.rm_rf!(temp_dir)
      end
    end

    test "random_string/1 returns a random string of the given length" do
      assert String.length(Downloader.random_string(10)) == 10
    end
  end
end
