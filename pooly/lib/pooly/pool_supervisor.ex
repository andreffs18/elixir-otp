defmodule Pooly.PoolSupervisor do
  @moduledoc """
  Documentation for Pooly PoolSupervisor.
  """

  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config, name: :"#{pool_config[:name]}Supervisor")
  end


  def init(pool_config) do
    ops = [
      strategy: :one_for_all,
    ]

    children = [
      worker(Pooly.PoolServer, [self(), pool_config])
    ]

    supervise(children, ops)
  end
end
