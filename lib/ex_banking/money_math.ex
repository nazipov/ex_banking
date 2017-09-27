defmodule ExBanking.MoneyMath do
  @doc ~S"""
    Adds one value to another

    ## Example
    iex> ExBanking.MoneyMath.add(100.99, 10.02)
    111.01

    iex> ExBanking.MoneyMath.add(100.99, 10.029)
    111.01

    iex> ExBanking.MoneyMath.add(100.99, 10)
    110.99
  """
  def add(balance, amount) do
    (to_integer(balance) + to_integer(amount)) |> to_float
  end

  @doc ~S"""
    Subs one value to another

    ## Example
    iex> ExBanking.MoneyMath.sub(100.00, 50.55)
    49.45

    iex> ExBanking.MoneyMath.sub(100.00, 100.01)
    -0.01

    iex> ExBanking.MoneyMath.sub(100.00, 100.00)
    0.0

    iex> ExBanking.MoneyMath.sub(100.99, 10)
    90.99
  """
  def sub(balance, amount) do
    (to_integer(balance) - to_integer(amount)) |> to_float
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
