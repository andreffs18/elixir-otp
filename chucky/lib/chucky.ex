defmodule Chucky do
  @moduledoc """
  Documentation for Chucky.
  """
  use Application
  require Logger

  def start(type, _args) do
    import Supervisor.Spec

    children = [
      worker(Chucky.Server, [])
    ]

    case type do
      :normal ->
        Logger.info("Application is started on node #{node}")
      {:takeover, old_node} ->
        Logger.info("#{node} is taking over #{old_node}")
      {:failover, old_node} ->
        Logger.info("#{old_node} if failing over to #{node}")
    end

    options = [strategy: :one_for_one, name: {:global, Chucky.Supervisor}]
    Supervisor.start_link(children, options)
  end

  def fact do
    Chucky.Server.fact
  end
end
