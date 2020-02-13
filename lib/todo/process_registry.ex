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

  def unregister_name(key) do
    GenServer.call(:process_registry, {:unregister_name, key})
  end

  def whereis_name(key) do
    read_cached(key) || :undefined
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
    :ets.new(:ets_process_registry, [:set, :named_table, :protected])
    {:ok, nil}
  end

  def handle_call({:register_name, key, pid}, _, _registry) do
    case read_cached(key) do
      nil ->
        Process.monitor(pid)
        cache_process(key, pid)
        {:reply, :yes, nil}

      _ ->
        {:reply, :no, nil}
    end
  end

  def handle_call({:unregister_name, key}, _, _registry) do
    :ets.match_delete(:ets_process_registry, key)
    {:noreply, nil}
  end

  def handle_info({:DOWN, _, :process, pid, _}, nil) do
    :ets.match_delete(:process_registry, {:_, pid})
    {:noreply, nil}
  end

  defp read_cached(key) do
    case :ets.lookup(:ets_process_registry, key) do
      [{^key, cached}] -> cached
      _ -> nil
    end
  end

  defp cache_process(key, pid) do
    :ets.insert(:ets_process_registry, {key, pid})
    pid
  end
end
