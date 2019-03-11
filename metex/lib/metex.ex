defmodule Metex do
  @moduledoc """
  Documentation for Metex.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Metex.hello()
      :world

  """
  def sentences, do: [
    "Hello World!",
    "How are you?",
    "Hope everything is fine with you!",
    "That's really cool..",
    "Hey, do you wanna hear something?",
    "We buda boy",
    "We zula kil zombies in chronicles",
    "That's the gossple",
    "That's the motherfucking gossple",
    "I don't remember the rest of the lycrics btw.. :)",
    "Next time I'll continue.",
  ]

  def translate(sentences) do
    coordinator_pid = spawn(Metex.Coordinator, :loop, [[], Enum.count(sentences)])

    sentences |> Enum.each(fn sentence ->
      pid = spawn(Metex.Worker, :loop, [])
      send(pid, {coordinator_pid, sentence, "en", "it"})
    end)
  end
end
