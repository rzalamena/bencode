defmodule BencodeTest do
  use ExUnit.Case
  doctest Bencode

  test "decode integer" do
    what = "i5e"
    {status, integer} = Bencode.decode(what)
    assert status == :ok
    assert is_integer(integer)
    assert integer == 5
  end

  test "decode negative integer" do
    what = "i-1e"
    {status, what, _} = Bencode.decode(what)
    assert status == :error
    assert what == :number
  end

  test "decode negative zero integer" do
    what = "i-0e"
    {status, what, _} = Bencode.decode(what)
    assert status == :error
    assert what == :number
  end

  test "decode string" do
    what = "4:spam"
    {status, string} = Bencode.decode(what)
    assert status == :ok
    assert is_binary(string)
    assert string == "spam"
  end

  test "decode negative string" do
    what = "-1:abcd"
    {status, _string, tail} = Bencode.decode(what)
    assert status == :error
    assert what == tail
  end

  test "decode empty string" do
    what = "0:"
    {status, string} = Bencode.decode(what)
    assert status == :ok
    assert string == ""
  end

  test "decode empty list" do
    what = "le"
    {status, list} = Bencode.decode(what)
    assert status == :ok
    assert is_list(list)
    assert Enum.empty?(list) == true
  end

  test "decode empty dict" do
    what = "de"
    {status, dict} = Bencode.decode(what)
    assert status == :ok
    assert is_map(dict)
    assert Map.equal?(dict, %{})
  end

  test "decode filled list" do
    what = "l4:spami3edelee"
    {status, list} = Bencode.decode(what)
    assert status == :ok
    assert is_list(list)
    assert Enum.at(list, 0) == "spam"
    assert Enum.at(list, 1) == 3
    assert Enum.at(list, 2) == %{}
    assert Enum.at(list, 3) == []
  end

  test "decode filled dictionary" do
    what = "d6:numberi3e4:listle4:dictde6:string6:foobare"
    {status, d} = Bencode.decode(what)
    assert status == :ok
    assert is_map(d)

    {status, value} = Map.fetch(d, "number")
    assert status == :ok
    assert value == 3
    {status, value} = Map.fetch(d, "list")
    assert status == :ok
    assert value == []
    {status, value} = Map.fetch(d, "dict")
    assert status == :ok
    assert value == %{}
    {status, value} = Map.fetch(d, "string")
    assert status == :ok
    assert value == "foobar"
  end

  test "encode integer" do
    assert Bencode.encode(10) == "i10e"
  end

  test "encode string" do
    str = "foobar"
    strlen = byte_size(str)
    assert Bencode.encode(str) == "#{strlen}:#{str}"
  end

  test "encode empty list" do
    assert Bencode.encode([]) == "le"
  end

  test "encode empty dict" do
    assert Bencode.encode(%{}) == "de"
  end

  test "encode filled list" do
    assert Bencode.encode(["test", 10, %{}, []]) == "l4:testi10edelee"
  end

  test "encode filled dict" do
    assert Bencode.encode(%{"test" => 10, "dict" => %{}, "list" => []}) ==
      "d4:dictde4:listle4:testi10ee"
  end
end
