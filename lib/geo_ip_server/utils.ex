defmodule GeoIpServer.Utils do
  @moduledoc """
  A collection of various helper functions.
  """

  @doc """
    Converts a map to a struct.
  """
  def struct_from_map(map, to: struct) do
    struct_keys =
      Map.keys(struct)
      |> Enum.filter(fn key -> key != :__meta__ and key != :__struct__ end)

    filtered_map =
      Enum.reduce(
        struct_keys,
        %{},
        fn key, acc ->
          Map.put(acc, key, Map.get(map, key))
        end
      )

    Map.merge(struct, filtered_map)
  end

  @doc """
    Converts raw SQL query's result to a map.
  """
  def map_from_sql_query_result(query_result) do
    if query_result.num_rows == 0 do
      []
    else
      Enum.map(query_result.rows, fn row ->
        Enum.zip(query_result.columns, row)
        |> Enum.into(%{})
      end)
    end
  end

  @doc """
    Converts raw SQL query's result to a struct.
  """
  def struct_from_sql_query_result(query_result, to: target_struct) do
    Enum.map(query_result.rows, fn row ->
      struct(target_struct, Enum.zip(Enum.map(query_result.columns, &String.to_atom/1), row))
    end)
  end

  @doc """
    Converts a value to a string for logging purposes.
  """
  def val_for_log(val) when is_nil(val), do: "<nil>"
  def val_for_log(val) when val == "", do: "<blank>"
  def val_for_log(val), do: val

  @doc """
    Converts a string to a boolean.

    ## Examples

        iex> GeoIpServer.Utils.to_boolean("true")
        true

        iex> GeoIpServer.Utils.to_boolean("false")
        false

        iex> GeoIpServer.Utils.to_boolean("1")
        true

        iex> GeoIpServer.Utils.to_boolean("0")
        false

        iex> GeoIpServer.Utils.to_boolean("unknown")
        ** (RuntimeError) Invalid boolean: unknown
  """
  def to_boolean(string) do
    case string do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _ -> raise "invalid boolean #{string}"
    end
  end
end
