defmodule PRNG do
  import PRNG.Threefry

  @type prng_key() :: [integer()]

  @doc ~S"""
  Create a pseudo-random number generator (PRNG) key given an integer seed.

  ## Examples

      iex> PRNG.key(1701)
      [0, 1701]

  """
  @spec key(integer()) :: prng_key()
  def key(seed), do: threefry_seed(seed)

  @doc """
  Folds in data to a PRNG key to form a new PRNG key.

  ## Examples

    iex> key = PRNG.key(1701)
    [0, 1701]
    iex> PRNG.fold_in(key, 1234)
    [3803315293, 1414594004]
  """
  @spec fold_in(prng_key(), integer()) :: prng_key()
  def fold_in(key, data), do: threefry_fold_in(key, data)

  @doc ~S"""
  Splits a PRNG key into num new keys by adding a leading axis.

  ## Examples

      iex> key = PRNG.key(1701)
      [0, 1701]
      iex> PRNG.split(key)
      [[56197195, 1801093307], [961309823, 1704866707]]

      iex> key = PRNG.key(1701)
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
