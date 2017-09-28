defmodule ExBanking.Lib.RequestsLimitTest do
  use ExUnit.Case

  setup %{messages_count: count} do
    send_ping_to_self(count)
    :ok
  end

  describe "ExBanking.Lib.RequestsLimit.limit_reached?/1" do
    @tag messages_count: Application.get_env(:ex_banking, :requests_limit) + 1
    test "return true then incoming messages count more than :requests_limit" do
      assert true == ExBanking.Lib.RequestsLimit.limit_reached?(self())
    end

    @tag messages_count: Application.get_env(:ex_banking, :requests_limit)
    test "return false then incoming messages count less or equal to :requests_limit" do
      assert false == ExBanking.Lib.RequestsLimit.limit_reached?(self())
    end
  end

  defp send_ping_to_self(n) when n <= 1, do: send self(), :ping
  defp send_ping_to_self(n) do
    send self(), :ping
    send_ping_to_self(n - 1)
  end
end
