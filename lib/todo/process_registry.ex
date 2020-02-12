defmodule Todo.ProcessRegistry do
  import Kernel, except: [send: 2]
  use GenServer

  def start_link do
    IO.puts("Starting process registry.")
    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(key, pid) do
    GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def whereis_name(key) do
    GenServer.call(:process_registry, {:whereis_name, key})
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined ->
        {:badarg, {key, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def init(_) do
    {:ok, Map.new()}
  end

  def handle_call({:register_name, key, pid}, _, registry) do
    case Map.get(registry, key) do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, Map.put(registry, key, pid)}

      _ ->
        {:reply, :no, registry}
    end
  end

  def handle_call({:whereis_name, key}, _, registry) do
    {:reply, Map.get(registry, key, :undefined), registry}
  end

  def handle_info({:DOWN, _, :process, pid, _}, registry) do
    {:noreply, deregister_pid(registry, pid)}
  end

  defp deregister_pid(registry, pid) do
    Enum.filter(registry, fn {_, v} -> v != pid end)
    |> Enum.into(Map.new)
  end
end
