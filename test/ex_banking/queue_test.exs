defmodule ExBanking.QueueTest do
  use ExUnit.Case

  describe "ExBanking.Queue.user_queue_len/1" do
    test "returns process incoming messages count" do
      assert 0 == ExBanking.Queue.user_queue_len(self())
      send self(), :ping
      assert 1 == ExBanking.Queue.user_queue_len(self())
      send self(), :ping
      assert 2 == ExBanking.Queue.user_queue_len(self())
      receive do
        :ping -> :pong
      end
      assert 1 == ExBanking.Queue.user_queue_len(self())
    end
  end
end
