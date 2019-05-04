defmodule Pooly.Server do
  @moduledoc """
  Documentation for Pooly Server.
  """

  use GenServer

  import Supervisor.Spec

  defmodule State do
    defstruct sup: nil,
              size: nil,
              mfa: nil,
              worker_sup: nil,
              workers: nil,
              monitors: nil
  end

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
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

  def handle_info({:start_pool, pool_config}, state) do
    {:ok, _pool_supervisor} = Supervisor.start_child(Pooly.PoolsSupervisor, supervisor_spec(pool_config))
    {:no_reply, state}
  end

  defp supervisor_spec(pool_config) do
    opts = [
      id: :"#{pool_config[:name]}Supervisor",
    ]
    supervisor(Pooly.PoolSupervisor, [pool_config], opts)
  end

end
