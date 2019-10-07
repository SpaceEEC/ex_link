defmodule ExLink do
  @moduledoc """
    Handles WebSocket connections to a Lavalink node, providing:
    - `ExLink.Player`s to keep track of Lavalink players and control them
    - `ExLink.Message`s to send via `ExLink.Connection`(s)


  A somewhat example:
  ```
  # define a player
  defmodule MyApp.Player do
    @behaviour ExLink.Player

    # required callbacks...
  end

  # define a supervisor
  defmodule MyApp.Supervisor do
    use Supervisor

    def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

    def init(_args) do
      children = [
        {ExLink,
        {%{
            url: "ws://localhost:8080",
            authorization: "123",
            shard_count: 1,
            user_id: 123_456_789_123_456_789,
            player: MyApp.Player
          }, name: MyApp.Player}}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  # after starting the supervisor, play something
  message = ExLink.Message.play(track, guild_id)
  ExLink.Connection.send(MyApp.Player, message)
  ```

  Alternatively `ExLink.Player` provides a `__using__` macro to directly start the module under a supervisor.
  """
  use Supervisor

  @typedoc """
    Options for `start_link/1`:

    - `:url` - URL of the lavalink node.
    - `:authorization` - Authorization for the lavalink node
    - `:shard_count` - Number of shards
    - `:user_id` - Id of the bot
    - `:player` - Module implementing the `ExLink.Player` behaviour.

  > Can be a `Map` or `Keyword`.
  """
  @typedoc since: "0.1.0"
  @type options ::
          [
            {:url, String.t()}
            | {:authorization, String.t()}
            | {:shard_count, non_neg_integer()}
            | {:user_id, ExLink.Payload.id()}
            | {:player, module()}
          ]
          | map()

  @doc """
    Starts an `ExLink` process linked to the current process.
  """
  @doc since: "0.1.0"
  @spec start_link(opts :: options() | {options(), GenServer.options()}) :: Supervisor.on_start()
  def start_link({opts, gen_opts}) do
    Supervisor.start_link(__MODULE__, Map.new(opts), gen_opts)
  end

  def start_link(opts), do: start_link({opts, []})

  @doc false
  def init(opts) do
    opts = Map.put(opts, :client, self())

    children = [
      {Agent, fn -> opts.player end},
      {ExLink.Connection, opts},
      {ExLink.Player.Supervisor, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
    Gets a player's pid or :error if not started.
  """
  @doc since: "0.1.0"
  @spec get_player(client :: term(), guild_id :: ExLink.Message.id()) :: pid() | :error
  def get_player(client, guild_id) do
    client
    |> get_player_supervisor()
    |> ExLink.Player.Supervisor.get_player(guild_id)
  end

  @doc """
    Gets all player's pids mapped by guild ids.
  """
  @doc since: "0.1.0"
  @spec get_players(client :: term()) :: %{required(ExLink.Message.id()) => pid()}
  def get_players(client) do
    client
    |> get_player_supervisor()
    |> ExLink.Player.Supervisor.get_players()
  end

  @doc """
    Gets a player's pid, starting it if necessary.
  """
  @doc since: "0.1.0"
  @spec ensure_player(client :: term(), guild :: ExLink.Message.id()) :: pid()
  def ensure_player(client, guild_id) do
    with :error <- get_player(client, guild_id) do
      ExLink.Player.Supervisor.start_child(client, guild_id)
      |> case do
        {:ok, child} ->
          child

        {:ok, child, _info} ->
          child

        {:error, {:already_started, child}} ->
          child

        {:error, error} ->
          raise "Starting the player failed: #{inspect(error)}"
      end
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
