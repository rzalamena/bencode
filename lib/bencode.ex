defmodule Bencode do
  @moduledoc ~S"""
  A bencode implementation specified by the BEP 03.

  ## Examples

      iex> Bencode.decode("d4:samplekeyi50ee")
      {:error, :string, "keyi50ee"}

      iex> Bencode.encode(%{"foobar" => 10, "baz" => [], "bar" => %{}})
      "d3:barde3:bazle6:foobari10ee"
  """

  @doc """
  Encode Elixir data structures into a bencoded string.
  """
  def encode(data) do
    encode_value(data)
  end

  # Helper function to keep encode_value() small
  defp reduce_list(list) do
    Enum.reduce(list, "", fn(x, acc) ->
      acc <> encode_value(x)
    end)
  end

  # Helper function to keep encode_value() small
  defp reduce_dict(dict) do
    Enum.reduce(dict, "", fn({key, value}, acc) ->
      acc <> encode_value(key) <> encode_value(value)
    end)
  end

  defp encode_value(data) when is_integer(data), do: "i#{data}e"
  defp encode_value(data) when is_binary(data), do: "#{byte_size(data)}:#{data}"
  defp encode_value(data) when is_list(data), do: "l" <> reduce_list(data) <> "e"
  defp encode_value(data) when is_map(data), do: "d" <> reduce_dict(data) <> "e"

  @doc """
  Decodes a bencoded string into Elixir data structures.

  Returns `{:ok, value}` on success otherwise `{:error, reason, where}`.

  Reason values might be:
  * `:string`
  * `:number`
  * `:list`
  * `:dict`

  The `where` return contains the part of the input where it stopped parsing the bencoded string.
  """
  def decode(data) when is_binary(data) do
    case decode_value(data) do
      {:ok, value, _tail} ->
        {:ok, value}
      {:error, what, tail} ->
        {:error, what, tail}
    end
  end

  # Find out the structure type by the first character.
  defp decode_value(<<?i, tail :: binary>>), do: decode_number(tail)
  defp decode_value(<<?l, tail :: binary>>), do: decode_list(tail)
  defp decode_value(<<?d, tail :: binary>>), do: decode_dict(tail)
  defp decode_value(data), do: decode_string(data)

  # Decode strings into Elixir strings.
  defp decode_string(<<?:, tail :: binary>>, acc) do
    {length, _} = Integer.parse(acc)
    {:ok, binary_part(tail, 0, length), binary_part(tail, length, byte_size(tail) - length)}
  end

  defp decode_string(<<?0, tail :: binary>>, acc), do: decode_string(tail, acc <> "0")
  defp decode_string(<<?1, tail :: binary>>, acc), do: decode_string(tail, acc <> "1")
  defp decode_string(<<?2, tail :: binary>>, acc), do: decode_string(tail, acc <> "2")
  defp decode_string(<<?3, tail :: binary>>, acc), do: decode_string(tail, acc <> "3")
  defp decode_string(<<?4, tail :: binary>>, acc), do: decode_string(tail, acc <> "4")
  defp decode_string(<<?5, tail :: binary>>, acc), do: decode_string(tail, acc <> "5")
  defp decode_string(<<?6, tail :: binary>>, acc), do: decode_string(tail, acc <> "6")
  defp decode_string(<<?7, tail :: binary>>, acc), do: decode_string(tail, acc <> "7")
  defp decode_string(<<?8, tail :: binary>>, acc), do: decode_string(tail, acc <> "8")
  defp decode_string(<<?9, tail :: binary>>, acc), do: decode_string(tail, acc <> "9")
  defp decode_string(tail, _acc), do: {:error, :string, tail}
  defp decode_string(data), do: decode_string(data, "")

  # Decode number into Elixir Integer.
  defp decode_number(<<?e, tail :: binary>>, acc) do
    {number, _} = Integer.parse(acc)
    {:ok, number, tail}
  end

  defp decode_number(<<?0, tail :: binary>>, acc), do: decode_number(tail, acc <> "0")
  defp decode_number(<<?1, tail :: binary>>, acc), do: decode_number(tail, acc <> "1")
  defp decode_number(<<?2, tail :: binary>>, acc), do: decode_number(tail, acc <> "2")
  defp decode_number(<<?3, tail :: binary>>, acc), do: decode_number(tail, acc <> "3")
  defp decode_number(<<?4, tail :: binary>>, acc), do: decode_number(tail, acc <> "4")
  defp decode_number(<<?5, tail :: binary>>, acc), do: decode_number(tail, acc <> "5")
  defp decode_number(<<?6, tail :: binary>>, acc), do: decode_number(tail, acc <> "6")
  defp decode_number(<<?7, tail :: binary>>, acc), do: decode_number(tail, acc <> "7")
  defp decode_number(<<?8, tail :: binary>>, acc), do: decode_number(tail, acc <> "8")
  defp decode_number(<<?9, tail :: binary>>, acc), do: decode_number(tail, acc <> "9")
  defp decode_number(<<data :: binary>>, _acc), do: {:error, :number, data}
  defp decode_number(<<data :: binary>>), do: decode_number(data, "")

  # Decode list into Elixir list.
  defp decode_list(list, <<?e, tail :: binary>>), do: {:ok, Enum.reverse(list), tail}
  defp decode_list(list, <<data :: binary>>) do
    with {:ok, value, tail} <- decode_value(data),
    do: decode_list([value | list], tail)
  end
  defp decode_list(_list, ""), do: {:error, :list, ""}
  defp decode_list(<<data :: binary>>), do: decode_list([], data)

  # Decode dictionary into Elixir Map.
  defp decode_dict(dict, <<?e, tail :: binary>>), do: {:ok, dict, tail}
  defp decode_dict(dict, <<data :: binary>>) do
    with {:ok, key, tail} <- decode_string(data),
      {:ok, value, tail} <- decode_value(tail),
    do: decode_dict(Map.put(dict, key, value), tail)
  end
  defp decode_dict(_dict, ""), do: {:error, :dict, ""}
  defp decode_dict(<<data :: binary>>), do: decode_dict(%{}, data)
end
