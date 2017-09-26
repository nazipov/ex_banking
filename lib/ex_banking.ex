defmodule ExBanking do
  @type banking_error :: {:error,
    :wrong_arguments                |
    :user_already_exists            |
    :user_does_not_exist            |
    :not_enough_money               |
    :sender_does_not_exist          |
    :receiver_does_not_exist        |
    :too_many_requests_to_user      |
    :too_many_requests_to_sender    |
    :too_many_requests_to_receiver
  }

  @spec create_user(user :: String.t) :: :ok | banking_error
  def create_user(user_name) do
    case ExBanking.Supervisor.start_child(user_name) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
    end
  end

  # @spec deposit(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error

  # @spec withdraw(user :: String.t, amount :: number, currency :: String.t) :: {:ok, new_balance :: number} | banking_error

  # @spec get_balance(user :: String.t, currency :: String.t) :: {:ok, balance :: number} | banking_error

  # @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) :: {:ok, from_user_balance :: number, to_user_balance :: number} | banking_error
end
