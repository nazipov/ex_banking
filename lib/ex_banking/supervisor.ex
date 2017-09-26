defmodule ExBanking.Supervisor do
  use Supervisor

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def start_child(user_name) do
    Supervisor.start_child(@name, [user_name])
  end

  def init(_) do
    children = [
      worker(ExBanking.User, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
