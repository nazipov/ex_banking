defmodule ExBanking.Lib.RequestsLimit do
  @doc ~S"""
    Validates that process queue length is reached.
    Default queue len is 10. Value can be changed in config.
  """
  def limit_reached?(user_pid) do
    {:message_queue_len, length} = :erlang.process_info(user_pid, :message_queue_len)

    Application.get_env(:ex_banking, :requests_limit) < length
  end
end
