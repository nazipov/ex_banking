defmodule ExBanking.User do
  use GenServer

  import ExBanking.MoneyMath

  @registry ExBanking.Registry

  @default_amount 0.0

  def start_link(user) do
    GenServer.start_link(__MODULE__, nil, name: via_registry(user))
  end

  def deposit(user, amount, currency) do
    safe_call(user, {:deposit, amount, currency})
  end

  def withdraw(user, amount, currency) do
    safe_call(user, {:withdraw, amount, currency})
  end

  def get_balance(user, currency) do
    safe_call(user, {:get_balance, currency})
  end

  def send(from_user, to_user, amount, currency) do
    safe_call(from_user, {:send, to_user, amount, currency})
  end

  defp safe_call(user, request) do
    case Registry.lookup(@registry, user) do
      [{pid, _}] -> GenServer.call(pid, request)
      [] -> {:error, :user_does_not_exist}
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
    safe_withdraw({amount, currency, state}, fn new_balance, new_state ->
      case deposit(to_user, amount, currency) do
        {:ok, to_user_balance} ->
          {:reply, {:ok, new_balance, to_user_balance}, new_state}
        {:error, :user_does_not_exist} ->
          {:error, :receiver_does_not_exist}
      end
    end)
  end

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
