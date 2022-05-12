defmodule PRNG.Threefry do
  use Bitwise

  defguard is_threefry_key(term)
           when is_list(term) and length(term) == 2 and is_integer(hd(term)) and
                  is_integer(hd(tl(term)))

  @doc ~S"""
  Create a pseudo-random number generator (PRNG) key given an integer seed.

  ## Examples

      iex(11)> PRNG.Threefry.threefry_seed(1701)
      [0, 1701]

  """
  @spec threefry_seed(integer) :: [integer, ...]
  def threefry_seed(seed) when is_integer(seed) do
    k1 = seed >>> 32
    k2 = seed &&& 0xFFFFFFFF
    [k1, k2]
  end

  defp rotate_left(x, rot) when is_integer(x) do
    nbits = 32
    x <<< rot ||| x >>> (nbits - rot)
  end

  defp list_to_int32(list) do
    Enum.map(list, &(&1 &&& 0xFFFFFFFF))
  end

  defp apply_round([x1, x2], rot) do
    y1 =
      add_to_list(x1, x2)
      |> list_to_int32()

    y2 =
      Enum.map(x2, &rotate_left(&1, rot))
      |> Enum.zip(y1)
      |> Enum.map(fn {x2_rot, x1_nrot} -> bxor(x2_rot, x1_nrot) end)
      |> list_to_int32()

    [y1, y2]
  end

  defp rolled_loop_step(i, [xs, _ks = [k1, k2, k3], _rotations = [r1, r2]]) do
    [x1, x2] = Enum.reduce(r1, xs, &apply_round(&2, &1))

    new_x =
      [add_to_list(x1, k1), add_to_list(x2, k2 + i + 1)]
      |> Enum.map(&list_to_int32(&1))

    new_k = [k2, k3, k1]
    new_r = [r2, r1]

    [new_x, new_k, new_r]
  end

  defp threefry2x32_20([_x1, _x2] = xs, [key1, key2] = ks) do
    rotations = [[13, 15, 26, 6], [17, 29, 16, 24]]

    xs = Enum.zip_with([xs, ks], fn [x, k] -> add_to_list(x, k) end)
    ks = [key2, bxor(key1, key2) |> bxor(0x1BD11BDA), key1]

    state = [xs, ks, rotations]

    0..4
    |> Enum.reduce(state, &rolled_loop_step/2)
    |> hd()
    |> Enum.map(&list_to_int32(&1))
    |> List.flatten()
    |> Enum.chunk_every(2)
  end

  defp split_in_half(list) do
    len = round(length(list) / 2)
    Enum.split(list, len)
  end

  defp add_to_list(list, val) when is_integer(val) do
    Enum.map(list, &(&1 + val))
  end

  defp add_to_list(list, val) when is_list(val) do
    Enum.zip_with([list, val], fn [l, v] -> l + v end)
  end

  defp threefry2x32([_key1, _key2] = keypair, count) when is_list(count) do
    even? =
      length(count)
      |> rem(2) == 0

    if even? do
      List.flatten(count)
    else
      [0 | List.flatten(count)]
    end
    |> split_in_half()
    |> Tuple.to_list()
    |> threefry2x32_20(keypair)
    |> then(fn output ->
      if not even? do
        Enum.reverse(output)
      else
        output
      end
    end)
  end

  @doc ~S"""
  Splits a PRNG key into num new keys by adding a leading axis.

  ## Examples

      iex(2)> key = PRNG.Threefry.threefry_seed(1701)
      [0, 1701]
      iex(3)> PRNG.Threefry.threefry_split(key)
      [[56197195, 1801093307], [961309823, 1704866707]]

      iex(14)> key = PRNG.Threefry.threefry_seed(1701)
      [0, 1701]
      iex(15)> PRNG.Threefry.threefry_split(key, 3)
      [
        [927208350, 3916705582],
        [1835323421, 676898860],
        [3164047411, 4010691890]
      ]

  """
  @spec threefry_split([integer, ...], integer) :: list
  def threefry_split(key, num \\ 2) when is_threefry_key(key) do
    counts = Enum.to_list(0..(num * 2 - 1))
    threefry2x32(key, counts)
  end
end
