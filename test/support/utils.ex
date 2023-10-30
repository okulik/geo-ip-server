defmodule GeoIpServer.TestUtils do
  @moduledoc """
  A collection of various helper functions for testing.
  """

  @doc """
  Converts a string into a stream of lines.
  """
  def csv_to_stream(csv) do
    {:ok, pid} = StringIO.open(csv)
    IO.stream(pid, :line)
  end
end
