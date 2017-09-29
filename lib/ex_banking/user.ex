defmodule ExBanking.User do
  use GenServer

  import ExBanking.Lib.SimpleDecimal
  import ExBanking.Lib.RequestsLimit

  @registry ExBanking.Registry
  @default_amount 0.0

  @wrong_arguments_error {:error, :wrong_arguments}

  def start_link(user) do
    GenServer.start_link(__MODULE__, nil, name: via_registry(user))
  end

  @doc ~S"""
    Increases user's balance in given currency by amount value.
    Returns new_balance of the user in given format.
  """
  @spec deposit(user :: String.t, amount :: number, currency :: String.t) ::
               {:ok, new_balance :: number} | ExBanking.banking_error
  def deposit(user, amount, currency)
  when is_binary(user) and is_binary(currency) and is_number(amount) and amount > 0 do
    safe_call(user, {:deposit, amount, currency})
  end
  def deposit(_user, _amount, _currency), do: @wrong_arguments_error

  @doc ~S"""
    Decreases user's balance in given currency by amount value.
    Returns new_balance of the user in given format.
  """
  @spec withdraw(user :: String.t, amount :: number, currency :: String.t) ::
                {:ok, new_balance :: number} | ExBanking.banking_error
  def withdraw(user, amount, currency)
  when is_binary(user) and is_binary(currency) and is_number(amount) and amount > 0 do
    safe_call(user, {:withdraw, amount, currency})
  end
  def withdraw(_user, _amount, _currency), do: @wrong_arguments_error

  @doc ~S"""
    Returns balance of the user in given format.
  """
  @spec get_balance(user :: String.t, currency :: String.t) ::
                   {:ok, balance :: number} | ExBanking.banking_error
  def get_balance(user, currency)
  when is_binary(user) and is_binary(currency) do
    safe_call(user, {:get_balance, currency})
  end
  def get_balance(_user, _currency), do: @wrong_arguments_error

  @doc ~S"""
    Decreases from_user's balance in given currency by amount value
    Increases to_user's balance in given currency by amount value
    Returns balance of from_user and to_user in given format
  """
  @spec send(from_user :: String.t, to_user :: String.t, amount :: number, currency :: String.t) ::
            {:ok, from_user_balance :: number, to_user_balance :: number} | ExBanking.banking_error
  def send(from_user, to_user, amount, currency)
  when is_binary(from_user) and is_binary(to_user) and to_user != from_user and
       is_binary(currency) and is_number(amount) and amount > 0
  do
    case safe_call(from_user, {:send, to_user, amount, currency}) do
      {:error, :user_does_not_exist} -> {:error, :sender_does_not_exist}
      {:error, :too_many_requests_to_user} -> {:error, :too_many_requests_to_sender}
      response -> response
    end
  end
  def send(_from_user, _to_user, _amount, _currency), do: @wrong_arguments_error

  # Validates that user exists and queue limit is not reached.
  # If success than sends request to the user
  defp safe_call(user, request) when is_binary(user) do
    case user_availiable?(user) do
      {:ok, pid} -> GenServer.call(pid, request)
      err -> err
    end
  end

  # Validates that user exists and queue limit is not reached.
  # If success than returns user process pid, else error with reason
  defp user_availiable?(user) when is_binary(user) do
    case Registry.lookup(@registry, user) do
      [{pid, _}] -> user_availiable?(pid)
      [] -> {:error, :user_does_not_exist}
    end
  end
  defp user_availiable?(user) when is_pid(user) do
    case limit_reached?(user) do
      false -> {:ok, user}
      true -> {:error, :too_many_requests_to_user}
    end
  end

  defp via_registry(user) do
    {:via, Registry, {@registry, user}}
  end

  # GenServer

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:deposit, amount, currency}, _from, state) do
    balance = Map.get(state, currency, @default_amount)
    new_balance = add(balance, amount)
    new_state = Map.put(state, currency, new_balance)

    {:reply, {:ok, new_balance}, new_state}
  end

  def handle_call({:withdraw, amount, currency}, _from, state) do
    safe_withdraw({amount, currency, state}, fn new_balance, new_state ->
      {:reply, {:ok, new_balance}, new_state}
    end)
  end

  def handle_call({:get_balance, currency}, _from, state) do
    {:reply, {:ok, Map.get(state, currency, @default_amount)}, state}
  end

  def handle_call({:send, to_user, amount, currency}, _from, state) do
    case user_availiable?(to_user) do
      {:ok, to_user_pid} ->
        safe_withdraw({amount, currency, state}, fn new_balance, new_state ->
          {:ok, to_user_balance} = GenServer.call(to_user_pid, {:deposit, amount, currency})

          {:reply, {:ok, new_balance, to_user_balance}, new_state}
        end)
      {:error, :user_does_not_exist} ->
        {:reply, {:error, :receiver_does_not_exist}, state}
      {:error, :too_many_requests_to_user} ->
        {:reply, {:error, :too_many_requests_to_receiver}, state}
    end
  end

  # Validates that the user have enough money for withdraw.
  # If success than call success function with new_balance and new_state.
  defp safe_withdraw({amount, currency, state}, success) do
    balance = Map.get(state, currency, @default_amount)
    new_balance = sub(balance, amount)

    if new_balance >= 0 do
      success.(new_balance, Map.put(state, currency, new_balance))
    else
      {:reply, {:error, :not_enough_money}, state}
    end
  end
end
