defmodule ExBanking.Queue do
  def user_queue_len(user_pid) do
    {:message_queue_len, length} = :erlang.process_info(user_pid, :message_queue_len)

    length
  end
end
