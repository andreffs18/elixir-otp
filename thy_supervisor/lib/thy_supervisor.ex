defmodule ThySupervisor do
  @moduledoc """
  Documentation for ThySupervisor.
  """
  use GenServer

  # API FUNCTIONS
  def start_link(child_spec_list) do
    GenServer.start_link(__MODULE__, [child_spec_list])
  end

  def start_child(supervisor, child_spec) do
    GenServer.call(supervisor, {:start_child, child_spec})
  end

  def terminate_child(supervisor, pid) when is_pid(pid) do
    GenServer.call(supervisor, {:terminate_child, pid})
  end

  def restart_child(supervisor, pid, child_spec) when is_pid(pid) do
    GenServer.call(supervisor, {:restart_child, pid, child_spec})
  end

  def count_children(supervisor) do
    GenServer.call(supervisor, :count_children)
  end

  def which_children(supervisor) do
    GenServer.call(supervisor, :which_children)
  end

  def terminate(_reason, state) do
    terminate_children(state)
    :ok
  end

  # CALLBACK FUNCTIONS
  def init([child_spec_list]) do
    Process.flag(:trap_exit, true)

    state = child_spec_list
      |> start_children()
      |> Enum.into(Map.new)
    {:ok, state}
  end

  def handle_call({:start_child, child_spec}, _from, state) do
    case start_child(child_spec) do
      {:ok, pid} ->
        {:reply, {:ok, pid}, Map.put(state, pid, child_spec)}
      :error ->
        {:reply, {:error, "error starting child"}, state}
    end
  end

  def handle_call({:terminate_child, pid}, _from, state) do
    case terminate_child(pid) do
      :ok ->
        {:reply, :ok, Map.delete(state, pid)}
      :error ->
        {:reply, {:error, "error terminating child"}, state}
    end
  end

  def handle_call({:restart_child, old_pid}, _from, state) do
    case Map.fetch(state, old_pid) do
      {:ok, child_spec} ->
        case restart_child(old_pid, child_spec) do
          {:ok, {pid, child_spec}} ->
            new_state = state
              |> Map.delete(old_pid)
              |> Map.put(pid, child_spec)
            {:reply, {:ok, pid}, new_state}
          :error ->
            {:reply, {:error, "error restarting child"}, state}
        end
      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_call(:count_children, _from, state) do
    {:reply, Map.size(state), state}
  end

  def handle_call(:which_children, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:EXIT, from_pid, :killed}, state) do
    {:no_reply, Map.delete(state, from_pid)}
  end

  def handle_info({:EXIT, from_pid, :normal}, state) do
    {:no_reply, Map.delete(state, from_pid)}
  end

  def handle_info({:EXIT, from_pid, _reason}, state) do
    case Map.fetch(state, from_pid) do
      {:ok, child_spec} ->
        case restart_child(from_pid, child_spec) do
          {:ok, {pid, child_spec}} ->
            new_state = state
              |> Map.delete(from_pid)
              |> Map.put(pid, child_spec)
            {:no_reply, new_state}
          :error ->
            {:no_reply, state}
        end
      _ ->
        {:no_reply, state}
    end
  end

  # PRIVATE FUNCTIONS
  defp start_children([]), do: []
  defp start_children([child_spec | rest]) do
    case start_child(child_spec) do
      {:ok, pid} ->
        [{pid, child_spec} | start_children(rest)]
      :error ->
        :error
    end
  end

  defp start_child({mod, fun, args}) do
    case apply(mod, fun, args) do
      pid when is_pid(pid) ->
        Process.link(pid)
        {:ok, pid}
      _ ->
        :error
    end
  end

  defp terminate_children([]), do: []
  defp terminate_children(child_specs) do
    child_specs
    |> Enum.each(fn {pid, _} ->
        terminate_child(pid)
    end)
  end

  defp terminate_child(pid) do
    Process.exit(pid, :kill)
    :ok
  end

  defp restart_child(old_pid, child_spec) do
    case terminate_child(old_pid) do
      :ok ->
        case start_child(child_spec) do
          {:ok, pid} ->
            {:ok, {pid, child_spec}}
          :error ->
            :error
        end
      :error ->
        :error
    end
  end
end
