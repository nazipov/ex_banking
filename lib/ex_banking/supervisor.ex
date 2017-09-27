defmodule ExBanking.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def create_user(user_name) when is_binary(user_name), do: create_child(user_name)
  def create_user(_), do: {:error, :wrong_arguments}

  def init(_) do
    children = [
      worker(ExBanking.User, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp create_child(user_name) do
    case Supervisor.start_child(@name, [user_name]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> {:error, :user_already_exists}
    end
  end
end
