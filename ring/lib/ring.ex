defmodule Ring do
  @moduledoc """
  Documentation for Ring.
  """

  def create_processes(n) do
    1..n |> Enum.map(fn _ -> spawn(fn -> loop() end) end)
  end

  def loop do
    receive do
      {:link, link_to} when is_pid(link_to) ->
        Process.link(link_to)
        loop()

      :trap_exit ->
        Process.flag(:trap_exit, true)
        loop()

      :crash ->
        1/0

      {:EXIT, pid, reason} ->
        IO.puts "#{inspect self} received {:EXIT, #{inspect pid}, #{reason}}"
        loop()
     end
  end

  def link_processes(processes), do: link_processes(processes, [])

  def link_processes([process_1, process_2 | rest], linked_processes) do
    send(process_1, {:link, process_2})
    link_processes([process_2 | rest], [process_1 | linked_processes])
  end

  def link_processes([last_process | []], linked_processes) do
    first_process = linked_processes |> List.last
    send(last_process, {:link, first_process})
    :ok
  end

  def print_links(pids) do
    pids |> Enum.map(fn pid ->
      "#{inspect pid}: #{inspect Process.info(pid, :links)}"
    end)
  end

  def alive?(pids) do
    pids |> Enum.map(fn pid ->
      "#{inspect pid}: #{Process.alive?(pid)}"
    end)
  end

end
