defmodule Pooly do
  @moduledoc """
  Documentation for Pooly.
  """
  use Application

  def start(_type, _args) do
    pools_config = [
      [
        name: "Pool1",
        mfa: {Pooly.SampleWorker, :start_link, []},
        size: 2
      ], [
        name: "Pool2",
        mfa: {Pooly.SampleWorker, :start_link, []},
        size: 3
      ], [
        name: "Pool3",
        mfa: {Pooly.SampleWorker, :start_link, []},
        size: 4
      ],
    ]
    Pooly.Supervisor.start_link(pools_config)
  end

  def checkout(pool_name) do
    Pooly.Server.checkout(pool_name)
  end

  def checkin(pool_name, worker_pid) do
    Pooly.Server.checkin(pool_name, worker_pid)
  end

  def status() do
    Pooly.Server.status(pool_name)
  end
end
