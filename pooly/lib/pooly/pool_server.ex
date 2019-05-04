defmodule Pooly.PoolServer do
  @moduledoc """
  Documentation for Pooly PoolServer.
  """

  use GenServer
  import Supervisor.Spec

  defmodule State do
    defstruct pool_sup: nil,
              worker_sup: nil,
              monitors: nil,
              workers: nil,
              size: nil,
              mfa: nil,
              name: nil
  end

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, pool_config, name: __MODULE__)
  end

  def status(pool_name) do
    GenServer.call("#{pool_name}Server", :status)
  end

  def checkout(pool_name) do
    GenServer.call("#{pool_name}Server", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast("#{pool_name}Server", {:checkin, worker_pid})
  end


  def init(pools_config) do
    pools_config
    |> Enum.each(fn pool_config ->
      send(self(), {:start_pool, pool_config})
    end)

    {:ok, pools_config}
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_call(:checkout, {from_pid, _ref}, %{workers: workers, monitors: monitors} = state) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  def handle_cast({:checkin, worker_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:no_reply, %{state | workers: [pid | workers]}}
      [] ->
       {:no_reply, state}
    end
  end

  def handle_info(:start_worker_supervisor, %{mfa: mfa, sup: sup, size: size} = state) do
    {:ok, worker_sup} = Supervisor.start_child(sup, supervisor_spec(mfa))

    workers = prepopulate(size, worker_sup)
    {:no_reply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:DOWN, ref, _, _, _}, %{workers: workers, monitors: monitors} = state) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:no_reply, new_state}
      [[]] ->
        {:no_reply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, %{workers: workers, worker_sup: worker_sup, monitors: monitors} = state) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [new_worker(worker_sup) | workers]}
        {:no_reply, new_state}
      [[]] ->
        {:no_reply, state}
    end
  end

  defp supervisor_spec(mfa) do
    opts = [restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [mfa], opts)
  end

  defp prepopulate(size, worker_sup) do
    prepopulate(size, worker_sup, [])
  end
  defp prepopulate(size, _worker_sup, workers) when size < 1 do
    workers
  end
  defp prepopulate(size, worker_sup, workers) do
    prepopulate(size - 1, worker_sup, [new_worker(worker_sup) | workers])
  end

  defp new_worker(worker_sup) do
    {:ok, worker} = Supervisor.start_child(worker_sup, [[]])
    worker
  end

end
