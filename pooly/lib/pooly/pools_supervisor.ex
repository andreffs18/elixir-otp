defmodule Pooly.PoolsSupervisor do
  @moduledoc """
  Documentation for Pooly PoolsSupervisor.
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end


  def init(_) do
    ops = [
      strategy: :one_for_one,
    ]

    supervise([], ops)
  end
end
