defmodule PRNG do
  import PRNG.Threefry

  @type prng_key() :: [integer()]

  @doc ~S"""
  Create a pseudo-random number generator (PRNG) key given an integer seed.

  ## Examples

      iex> PRNG.prng_key(1701)
      [0, 1701]

  """
  @spec prng_key(integer()) :: prng_key()
  def prng_key(seed), do: threefry_seed(seed)

  @doc """
  Folds in data to a PRNG key to form a new PRNG key.

  ## Examples

    iex> key = PRNG.prng_key(1701)
    [0, 1701]
    iex> PRNG.fold_in(key, 1234)
    [3803315293, 1414594004]
  """
  @spec fold_in(prng_key(), integer()) :: prng_key()
  def fold_in(key, data), do: threefry_fold_in(key, data)

  @doc ~S"""
    Sample num uniform random values in [minval, maxval).

    ## Examples
      iex> key = PRNG.prng_key(1700)
      [0, 1700]
      iex> PRNG.randint(key, 2, -15, 15)
      [12, 10]

      iex> key = PRNG.prng_key(1701)
      [0, 1701]
      iex> PRNG.randint(key, 5, 0, 100)
      [65, 80, 41, 92, 24]


  """
  @spec randint(prng_key(), pos_integer(), integer(), integer()) :: [integer()]
  def randint(key, num \\ 1, min_val, max_val) when num >= 1 and max_val > min_val do
    span = max_val - min_val
    multiplier = rem(0xFFFFFFFF + 1, span)

    key
    |> split()
    |> Enum.map(&threefry_random_bits(&1, num))
    |> then(fn [higher, lower] -> Enum.zip(higher, lower) end)
    |> Enum.map(&(min_val + random_offset(&1, multiplier, span)))
  end

  defp random_offset({higher_bits, lower_bits}, multiplier, span) do
    (rem(higher_bits, span) * multiplier + rem(lower_bits, span)) |> rem(span)
  end

  @doc ~S"""
  Splits a PRNG key into num new keys by adding a leading axis.

  ## Examples

      iex> key = PRNG.prng_key(1701)
      [0, 1701]
      iex> PRNG.split(key)
      [[56197195, 1801093307], [961309823, 1704866707]]

      iex> key = PRNG.prng_key(1701)
      [0, 1701]
      iex> PRNG.split(key, 3)
      [
        [927208350, 3916705582],
        [1835323421, 676898860],
        [3164047411, 4010691890]
      ]

  """
  @spec split(prng_key(), pos_integer()) :: [prng_key()]
  def split(key, num \\ 2), do: threefry_split(key, num)
end
