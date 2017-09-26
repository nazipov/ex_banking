defmodule ExBanking.User do
  use GenServer

  def start_link(user_name) do
    GenServer.start_link(__MODULE__, nil, name: via_registry(user_name))
  end

  def init(_) do
    {:ok, %{}}
  end

  defp via_registry(user_name) do
    {:via, Registry, {ExBanking.Registry, user_name}}
  end
end
