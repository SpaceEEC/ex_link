defmodule ExLink.Player.Supervisor do
  @moduledoc false

  use Supervisor

  @doc false
  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil)
  end

  @doc false
  def init(_) do
    Supervisor.init([], strategy: :one_for_one)
  end

  @doc false
  @spec dispatch(client :: term(), event :: map()) :: :ok | :error
  def dispatch(client, %{"guildId" => guild_id} = event) do
    client
    |> ExLink.get_player_supervisor()
    |> get_player(guild_id)
    |> case do
      :error ->
        start_child(client, guild_id)

      # dispatch(client, event)

      pid when is_pid(pid) ->
        ExLink.Player.dispatch(pid, event)
    end
  end

  # Non guild specific events (like "stats")
  def dispatch(client, other) do
    client
    |> ExLink.get_module()
    |> spawn(:handle_dispatch, [other, nil])

    :ok
  end

  @doc false
  def get_player(sup, guild_id) do
    guild_id = to_integer(guild_id)

    sup
    |> Supervisor.which_children()
    |> Enum.find(fn
      {^guild_id, _pid, _type, _modules} -> true
      _ -> false
    end)
    |> case do
      nil -> :error
      {^guild_id, pid, _type, _modules} when is_pid(pid) -> pid
    end
  end

  @doc false
  def get_players(sup) do
    sup
    |> Supervisor.which_children()
    |> Enum.into(%{}, fn {guild_id, pid, _type, _modules} -> {to_string(guild_id), pid} end)
  end

  @doc false
  @spec start_child(
          client :: term(),
          guild_id :: ExLink.Message.id()
        ) :: Supervisor.on_start()
  def start_child(client, guild_id) do
    guild_id = to_integer(guild_id)
    module = ExLink.get_module(client)

    client
    |> ExLink.get_player_supervisor()
    |> Supervisor.start_child(
      Supervisor.child_spec(
        {ExLink.Player, {client, guild_id, module}},
        id: guild_id,
        restart: :temporary
      )
    )
  end

  defp to_integer(int) when is_integer(int), do: int
  defp to_integer(str) when is_binary(str), do: str |> String.to_integer()
end
