# Top-level supervisor


defmodule Todo.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    children = [
      worker(Todo.ProcessRegistry, []),
      supervisor(Todo.SystemSupervisor, []),
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
