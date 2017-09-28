defmodule ExBanking.Lib.SimpleDecimal do
  @moduledoc ~S"""
    Float is not save for money. Simple solution without any external libs.
  """

  @doc ~S"""
    Adds one number to another.

    ## Example
    iex> ExBanking.Lib.SimpleDecimal.add(100.99, 10.02)
    111.01

    iex> ExBanking.Lib.SimpleDecimal.add(100.99, 10.029)
    111.01

    iex> ExBanking.Lib.SimpleDecimal.add(100.99, 10)
    110.99
  """
  def add(a, b) do
    (to_integer(a) + to_integer(b)) |> to_float
  end

  @doc ~S"""
    Subtracts the second number from the first number.

    ## Example
    iex> ExBanking.Lib.SimpleDecimal.sub(100.00, 50.55)
    49.45

    iex> ExBanking.Lib.SimpleDecimal.sub(100.00, 100.01)
    -0.01

    iex> ExBanking.Lib.SimpleDecimal.sub(100.00, 100.00)
    0.0

    iex> ExBanking.Lib.SimpleDecimal.sub(100.99, 10)
    90.99
  """
  def sub(a, b) do
    (to_integer(a) - to_integer(b)) |> to_float
  end

  defp to_integer(float) do
    case float * 100 do
      v when is_float(v) -> v |> Float.floor |> round
      v -> v
    end
  end

  defp to_float(v) do
    v / 100
  end
end
