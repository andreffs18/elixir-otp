defmodule Blitzy do
  @moduledoc """
  Documentation for Blitzy.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Blitzy.hello()
      :world

  """
  def run(n_workers, url) when n_workers > 0 do
    worker_fun = fn -> Blitzy.Worker.start(url) end

    1..n_workers
    |> Enum.map(fn _ -> Task.async(worker_fun) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end


  defp parse_results(results) do
    {successes, _failures} =
      results
      |> Enum.split_with(fn x ->
        case x do
          {:ok, _} -> true
          _        -> false
        end
      end)

      total_workers = Enum.count(results)
      total_successes = Enum.count(successes)
      total_failures = total_workers - total_successes

      data = successes
      |> Enum.map(fn {:ok, time} -> time end)

      average_time = average(data)
      longest_time = Enum.max(data)
      shortest_time = Enum.min(data)

      IO.puts """
      Total workers:    #{total_workers}
      Successful reqs:  #{total_successes}
      Failed res:       #{total_failures}
      Average (msecs):  #{average_time}
      Longest (msecs):  #{longest_time}
      Shortest (msecs): #{shortest_time}
      """
  end

  defp average(data) do
    sum = Enum.sum(data)
    if sum > 0 do
      sum / Enum.count(data)
    else
      0
    end
  end
end
