defmodule PRNG.Threefry do
  import Kernel, except: [unless: 2]
  use Bitwise

  defp is_threefry_key(key) when is_list(key) do
    length(key) == 2 and Enum.all?(
      fn x -> is_integer(x) end
    )
  end

  def threefry_seed(seed) when is_integer(seed) do
    k1 = seed >>> 32
    k2 = seed &&& 0xFFFFFFFF
    [k1, k2]
  end


  defp rotate_left(x, rot) when is_integer(x) do
    nbits = 32
    (x <<< rot) ||| (x >>> (nbits - rot))
  end

  defp apply_round([x1, x2], rot) do
    y1 = x1 + x2
    y2 = bxor(x1, rotate_left(x2, rot))

    [y1, y2]
  end

  defp rolled_loop_step(i, [xs, _ks = [k1, k2, k3], _rotations = [r1, r2]]) do
      [x1, x2] = Enum.reduce(r1, xs, fn rot, x ->
        apply_round(x, rot)
      end)

      new_x = [x1+k1, x2+k2+i+1]
      new_k = [k2, k3, k1]
      new_r = [r1, r2]

      [new_x, new_k, new_r]
  end

  def threefry2x32_20([key1, key2] = ks, [_x1, _x2] = xs) do
    rotations = [[13, 15, 26, 6],
               [17, 29, 16, 24]]

    xs = Enum.zip_with([xs, ks], fn [x, k] -> x+k end)
    ks = [key1, key2, bxor(key1, key2) |> bxor(0x1BD11BDA)]

    state = [xs, ks, rotations]


    [final_xs, _final_ks, _final_rotations] = Enum.reduce(
      Enum.to_list(0..5), state, fn i, state ->
        rolled_loop_step(i, state)
    end)

    final_xs |> Enum.map(fn x -> x &&& 0xFFFFFFFF end)
  end

  defp split_in_half(list) do
    len = round(length(list)/2)
    Enum.split(list, len)
  end
  def threefry2x32([_key1, _key2] = keypair, count) when is_list(count) do
    even? = rem(length(count), 2) == 0
    {l1, l2} = if even? do
      List.flatten(count)
          |> split_in_half()
    else
      [0 | List.flatten(count)]
          |> split_in_half()
    end

    out = Enum.zip_with([l1, l2], fn
      [x1, x2] -> [x1, x2]
      end)
      |> Enum.map(fn xs ->
        IO.puts(xs)
        threefry2x32_20(keypair, xs)
      end)

    if not even? do Enum.reverse(out) else out end
  end

  def threefry_split(key, num) do
    counts = Enum.to_list(0..num*2)
    threefry2x32(key, counts)
  end

end
