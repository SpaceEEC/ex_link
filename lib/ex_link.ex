defmodule ExLink do
  @moduledoc """
    TODO: Description
  """
  use Supervisor

  @typedoc """
    Options for `start_link/1`:

    - `:url` - URL of the lavalink node.
    - `:authorization` - Authorization for the lavalink node
    - `:shard_count` - Number of shards
    - `:user_id` - Id of the bot
    - `:module` - Module implementing the `ExLink.Player` behaviour.
    - All `t:Supervisor.options/0`
  """
  @type options ::
          %{
            url: String.t(),
            authorization: String.t(),
            shard_count: non_neg_integer(),
            user_id: ExLink.Payload.id(),
            module: module()
          }
          | GenServer.options()

  @doc """
    Starts an `ExLink` process linked to the current process.

    Intended to be used as part of a supervision tree.
  """
  @spec start_link(opts :: options()) :: Supervisor.on_start()
  def start_link(opts) do
    opts = Map.new(opts)

    gen_opts =
      opts
      |> Map.drop([:url, :authorization, :shard_count, :user_id, :module])
      |> Map.to_list()

    opts = Map.take(opts, [:url, :authorization, :shard_count, :user_id, :module])

    Supervisor.start_link(__MODULE__, opts, gen_opts)
  end

  @doc false
  def init(opts) do
    opts = Map.put(opts, :client, self())

    children = [
      {Agent, fn -> opts.module end},
      {ExLink.Connection, opts},
      {ExLink.Player.Supervisor, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
    Gets a player's pid or :error if not started.
  """
  @spec get_player(client :: term(), guild_id :: ExLink.Message.id()) :: pid() | :error
  def get_player(client, guild_id) do
    client
    |> get_player_supervisor()
    |> ExLink.Player.Supervisor.get_player(guild_id)
  end

  @doc """
    Gets or starts a player's process (id).
  """
  @spec ensure_player(client :: term(), guild :: ExLink.Message.id()) :: pid()
  def ensure_player(client, guild_id) do
    with :error <- get_player(client, guild_id) do
      ExLink.Player.Supervisor.start_child(client, guild_id)

      ensure_player(client, guild_id)
    end
  end

  @doc false
  @spec get_module(client :: term()) :: module()
  def get_module(client) do
    client
    |> Supervisor.which_children()
    |> Enum.find(fn
      {Agent, _pid, _type, _modules} -> true
      _ -> false
    end)
    |> elem(1)
    |> Agent.get(& &1)
  end

  @doc false
  @spec get_player_supervisor(client :: term()) :: pid() | :error
  def get_player_supervisor(client) do
    client
    |> Supervisor.which_children()
    |> Enum.find(fn
      {ExLink.Player.Supervisor, _pid, _type, _modules} -> true
      _ -> false
    end)
    |> case do
      {_id, pid, _type, _modules} -> pid
      _ -> :error
    end
  end

  @doc false
  @spec get_connection(client :: term()) :: pid() | :error
  def get_connection(client) do
    client
    |> Supervisor.which_children()
    |> Enum.find(fn
      {ExLink.Connection, _pid, _type, _modules} -> true
      _ -> false
    end)
    |> case do
      {_id, pid, _type, _modules} -> pid
      _ -> :error
    end
  end
end
