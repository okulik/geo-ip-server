defimpl String.Chars, for: EctoIPRange.IP4 do
  @doc """
    Converts an EctoIPRange.IP4 struct to a string.
  """
  def to_string(ip4) do
    case :inet.ntoa(ip4.ip) do
      {:error, :einval} -> nil
      addr -> Kernel.to_string(addr)
    end
  end
end

defimpl String.Chars, for: EctoIPRange.IP4R do
  @doc """
    Converts an EctoIPRange.IP4R struct to a string.
  """
  def to_string(ip4r), do: ip4r.range
end

defimpl String.Chars, for: EctoIPRange.IP6 do
  @doc """
    Converts an EctoIPRange.IP6 struct to a string.
  """
  def to_string(ip6) do
    case :inet.ntoa(ip6.ip) do
      {:error, :einval} -> nil
      addr -> Kernel.to_string(addr)
    end
  end
end

defimpl String.Chars, for: EctoIPRange.IP6R do
  @doc """
    Converts an EctoIPRange.IP6R struct to a string.
  """
  def to_string(ip6r), do: ip6r.range
end
