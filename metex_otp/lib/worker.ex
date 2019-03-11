defmodule MetexOtp.Worker do

  use GenServer

  @name MW

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: MW])
  end

  def get_translation(text, source_language, target_language) do
    GenServer.call(@name, {:translation, text, source_language, target_language})
  end

  def get_state do
    GenServer.call(@name, :get_state)
  end

  def reset_state do
    GenServer.cast(@name, :reset_state)
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  # Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_info(msg, state) do
    IO.puts("Received \"#{msg}\".")
  end

  def handle_call({:translation, text, source_language, target_language}, _from, state) do
    case request_translation(text, source_language, target_language) do
      {:ok, translation} ->
        {:reply, "#{translation}", update_state(state, translation)}
      {:error, _reason} ->
        {:reply, :error, state}
    end
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:reset_state, _state) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, state) do
    IO.puts "Server terminated because of #{inspect reason}"
    IO.inspect state
    :ok
  end

  # Helper Functions

  def request_translation(text, source_language, target_language) do
    build_url(text, source_language, target_language)
    |> HTTPoison.get
    |> parse_response
  end

  def build_url(text, source_language, target_language) do
    "https://translate.googleapis.com/translate_a/single?client=gtx&sl=#{source_language}&tl=#{target_language}&dt=t&q=#{URI.encode(text)}"
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}), do: {:ok, body |> JSON.decode! |> parse_translation}
  def parse_response({:error, response}), do: {:error, response}

  def parse_translation([translations, _, source_language] = response) do
    # [[["texto", "text", nil, nil, 2]], nil, "en"]
    IO.inspect response
    try do
      translations
      |> Enum.map(&List.first(&1))
      |> Enum.join
    rescue
      _ -> {:error, "Error parsing response from HTTP request."}
    end
  end

  def update_state(old_state, translation) do
    case Map.has_key?(old_state, translation) do
      true ->
        Map.update!(old_state, translation, &(&1 + 1))
      false ->
        Map.put_new(old_state, translation, 1)
    end
  end

end
