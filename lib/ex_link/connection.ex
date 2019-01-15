defmodule ExLink.Connection do
  @moduledoc since: "0.1.0"
  @moduledoc """
    Handles the connection to a Lavalink node.
  """

  use WebSockex

  import Kernel, except: [send: 2]

  ### Client Api

  @doc """
    Sends a `t:ExLink.Message.message/0` or string to a Lavalink node.
  """
  @doc since: "0.1.0"
  @spec send(client :: term(), data :: ExLink.Message.message() | String.t()) ::
          :ok | {:error, term()}
  def send(client, data)

  def send(client, %{} = data) do
    data
    |> Poison.encode()
    |> case do
      {:ok, data} ->
        send(client, data)

      {:error, _error} = error ->
        error
    end
  end

  def send(client, data) when is_binary(data) do
    client
    |> ExLink.get_connection()
    |> WebSockex.send_frame({:text, data})
  end

  @doc """
    Forwards incoming [Voice Server Update](https://discordapp.com/developers/docs/topics/gateway#voice-server-update)s
    and [Voice State Update](https://discordapp.com/developers/docs/topics/gateway#voice-state-update)s to the Lavalink node.
  """
  @doc since: "0.1.0"
  @spec forward(client :: term(), data :: map()) :: :ok
  def forward(client, %{} = data) do
    data = Map.new(data, fn {k, v} -> {to_string(k), v} end)

    client
    |> ExLink.get_connection()
    |> WebSockex.cast({:forward, data})
  end

  ### Server Api

  alias ExLink.Message

  alias WebSockex.Conn

  require Logger

  @doc false
  def start_link(%{
        url: url,
        authorization: authorization,
        shard_count: shard_count,
        user_id: user_id,
        client: client
      }) do
    Logger.info(fn -> "[ExLink][Connection]: Starting" end)

    state = %{
      servers: %{},
      states: %{},
      client: client
    }

    Conn.new(
      "ws://#{url}",
      extra_headers: [
        {"Authorization", authorization},
        {"Num-Shards", shard_count},
        {"User-Id", to_string(user_id)}
      ]
    )
    |> WebSockex.start_link(
      __MODULE__,
      state,
      handle_initial_conn_failure: true,
      async: true
    )
  end

  @doc false
  def handle_info(_, state), do: {:ok, state}
  @doc false
  def handle_ping(_, state), do: {:reply, :pong, state}
  @doc false
  def handle_pong(_, state), do: {:ok, state}
  @doc false
  def code_change(_, state, _), do: {:ok, state}

  @doc false
  def handle_connect(_conn, state) do
    Logger.info(fn -> "[ExLink][Connection]: Connected" end)

    {:ok, state}
  end

  @doc false
  def handle_disconnect(%{reason: {_, code, reason}}, state) do
    Logger.warn(fn -> "[ExLink][Connection]: Disconnected: #{code} - #{reason}" end)

    {:reconnect, state}
  end

  def handle_disconnect(reason, state) do
    Logger.warn(fn ->
      "[ExLink][Connection]: Disconnected #{inspect(reason)}; Reconnecting in 5 seconds..."
    end)

    :timer.sleep(5000)

    {:reconnect, state}
  end

  @doc false
  def terinate({error, stacktrace}, _state) do
    Logger.error(fn ->
      "[ExLink][Connection]: Terminating: #{Exception.format(:error, error, stacktrace)}"
    end)
  end

  def terminate(reason, _state) do
    Logger.error(fn -> "[ExLink][Connection]: Terminating: #{inspect(reason)}" end)
  end

  @doc false
  def handle_frame({:text, frame}, %{client: client} = state) do
    frame
    |> Poison.decode()
    |> case do
      {:ok, data} ->
        client
        |> ExLink.Player.Supervisor.dispatch(data)

      _ ->
        nil
    end

    {:ok, state}
  end

  def handle_frame(_, state), do: {:ok, state}

  @doc false
  def handle_cast(
        {:forward, %{"user_id" => _, "guild_id" => guild_id} = voice_state},
        state
      ) do
    guild_id = to_integer(guild_id)

    state
    |> Map.update!(:states, &Map.put(&1, guild_id, voice_state))
    |> try_join(guild_id)
  end

  def handle_cast(
        {:forward, %{"token" => _, "guild_id" => guild_id} = voice_server},
        state
      ) do
    guild_id = to_integer(guild_id)

    state
    |> Map.update!(:servers, &Map.put(&1, guild_id, voice_server))
    |> try_join(guild_id)
  end

  def handle_cast(_other, state), do: {:ok, state}

  defp try_join(%{servers: servers, states: states} = state, guild_id)
       when :erlang.is_map_key(guild_id, servers) and :erlang.is_map_key(guild_id, states) do
    voice_server = Map.get(servers, guild_id)
    voice_state = Map.get(states, guild_id)

    Logger.debug(fn -> "[ExLink][Connection]: Attempting to join #{guild_id}..." end)

    packet =
      voice_server
      |> Message.voice_update(Map.fetch!(voice_state, "session_id"), guild_id)
      |> Poison.encode!()

    {:reply, {:text, packet}, state}
  end

  defp try_join(state, _guild_id), do: {:ok, state}

  defp to_integer(int) when is_integer(int), do: int
  defp to_integer(str) when is_binary(str), do: str |> String.to_integer()
end
