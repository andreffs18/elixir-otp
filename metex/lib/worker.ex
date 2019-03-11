defmodule Metex.Worker do

  def loop do
    receive do
      {sender_pid, sentence, source_language, target_language} ->
        send(sender_pid, {:ok, translation(sentence, source_language, target_language)})
      _ -> IO.puts("Message not supported")
    end
    loop
  end

  def translation(text, source_language, target_language) do
    result =  build_url(text, source_language, target_language) |> HTTPoison.get |> parse_response

    case result do
      {:ok, translation} ->
        "#{translation}"
      {:error, reason} ->
        "Failed to get translation: #{reason}."
    end
  end

  def build_url(text, source_language, target_language) do
    "https://translate.googleapis.com/translate_a/single?client=gtx&sl=#{source_language}&tl=#{target_language}&dt=t&q=#{URI.encode(text)}"
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    {:ok, body |> JSON.decode! |> get_translation}
  end

  def parse_response({:error, response}) do
    {:error, response}
  end

  # [[["texto", "text", nil, nil, 2]], nil, "en"]
  def get_translation([translations, _, source_language] = response) do
    try do
      translations
      |> Enum.map(&List.first(&1))
      |> Enum.join
    rescue
      _ -> {:error, "Error parsing response from HTTP request."}
    end
  end
end
