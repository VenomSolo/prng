defmodule PRNG.Threefry do
  use Bitwise

  defguard is_threefry_key(term)
           when is_list(term) and length(term) == 2 and is_integer(hd(term)) and
                  is_integer(hd(tl(term)))

  @spec threefry_seed(integer()) :: PRNG.prng_key()
  def threefry_seed(seed) when is_integer(seed) do
    k1 = seed >>> 32
    k2 = seed &&& 0xFFFFFFFF
    [k1, k2]
  end

  @spec threefry_split(PRNG.prng_key(), pos_integer()) :: [PRNG.prng_key()]
  def threefry_split(key, num) when is_threefry_key(key) do
    counts = Enum.to_list(0..(num * 2 - 1))

    key
    |> threefry2x32(counts)
    |> Enum.chunk_every(2)
  end

  @spec threefry_fold_in(PRNG.prng_key(), integer()) :: PRNG.prng_key()
  def threefry_fold_in(key, data) when is_threefry_key(key) and is_integer(data) do
    threefry2x32(key, threefry_seed(data))
  end

  @spec threefry_random_bits(PRNG.prng_key(), pos_integer()) :: [integer()]
  def threefry_random_bits(key, num \\ 1) when is_threefry_key(key) and num >= 1 do
    threefry2x32(key, Enum.to_list(0..(num - 1)))
  end

  defp threefry2x32(key, count) when is_threefry_key(key) and is_list(count) do
    even? = rem(length(count), 2) == 0

    if even? do
      List.flatten(count)
    else
      [0 | List.flatten(count)]
    end
    |> split_in_half()
    |> Tuple.to_list()
    |> threefry2x32_20(key)
    |> then(fn output ->
      if even?, do: output, else: tl(output)
    end)
  end

  defp split_in_half(list) do
    len = div(length(list), 2)
    Enum.split(list, len)
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

  defp rotate_left(x, rot) when is_integer(x) do
    nbits = 32
    x <<< rot ||| x >>> (nbits - rot)
  end

  defp list_to_int32(list) do
    Enum.map(list, &(&1 &&& 0xFFFFFFFF))
  end

  defp add_to_list(list, val) when is_integer(val) do
    Enum.map(list, &(&1 + val))
  end

  defp add_to_list(list, val) when is_list(val) do
    Enum.zip_with([list, val], fn [l, v] -> l + v end)
  end
end
