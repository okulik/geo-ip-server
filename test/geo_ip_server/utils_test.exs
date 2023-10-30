defmodule GeoIpServer.UtilsTest do
  use ExUnit.Case, async: true

  alias GeoIpServer.Utils

  defstruct [:a, :b]

  describe "struct_from_map" do
    test "converts provided map to a struct, all fields" do
      struct = Utils.struct_from_map(%{a: 3, b: 4}, to: %__MODULE__{})

      assert struct.a == 3
      assert struct.b == 4
    end

    test "converts provided map to a struct, partial fields" do
      struct = Utils.struct_from_map(%{a: 3}, to: %__MODULE__{})

      assert struct.a == 3
      assert struct.b == nil
    end
  end

  describe "val_for_log" do
    test "formats nil" do
      assert Utils.val_for_log(nil) == "<nil>"
    end

    test "formats empty string" do
      assert Utils.val_for_log("") == "<blank>"
    end

    test "formats a number" do
      assert Utils.val_for_log(42) == 42
    end

    test "formats a string" do
      assert Utils.val_for_log("a string") == "a string"
    end
  end

  describe "to_boolean" do
    test "to_boolean/1 with valid data" do
      assert Utils.to_boolean("true") == true
      assert Utils.to_boolean("false") == false
      assert Utils.to_boolean("1") == true
      assert Utils.to_boolean("0") == false
    end

    test "to_boolean/1 with invalid data" do
      assert_raise RuntimeError, fn ->
        Utils.to_boolean("threw")
      end
    end
  end
end
