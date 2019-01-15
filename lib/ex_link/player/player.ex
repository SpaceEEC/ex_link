defmodule ExLink.Player do
  @moduledoc """

  """

  @typedoc """
    Possible return values in `c:handle_info/2`, `c:handle_cast/2`, and `c:handle_dispatch/2`.
    `c:handle_call/3` also allows to synchronously respond via additional allowed return values.
  """
  @type common_return ::
          {:noreply, new_state :: term()}
          | {:stop, reason :: term(), new_state :: term()}

  @doc """
    Invoked when the player is started.
    See `GenServer.init/1`.
  """
  @callback init(client :: pid(), guild_id :: ExLink.Message.id()) ::
              {:ok, term()} | {:stop, reason :: term()}

  @doc """
    Invoked to handle all other messages.
    See `GenServer.handle_info/2`.
  """
  @callback handle_info(msg :: :timeout | term(), state :: term) :: common_return()

  @doc """
    Invoked to handle synchronous `call/3` messages. `call/3` will block until a reply is received (unless the call times out or nodes ar disconnected).
    See `GenServer.handle_call/3`.
  """
  @callback handle_call(request :: term(), from :: term(), state :: term()) ::
              common_return()
              | {:reply, reply :: term(), new_state :: term()}
              | {:stop, reply :: term(), reason :: term(), new_state :: term()}

  @doc """
    Invoked to handle asynchronous `cast/2` messages.
    See `GenServer.handle_cast/2`.
  """
  @callback handle_cast(request :: term(), state :: term()) :: term() :: common_return()

  @doc """
    Invoked to handle events from a lavalink node.

  > For non guild specific dispatches this function will be invoked outside of a player process, with the state `nil`.
    Return values will be ignored.
  """
  @callback handle_dispatch(data :: map(), state :: term()) :: common_return()

  @optional_callbacks handle_info: 2, handle_call: 3, handle_cast: 2

  use GenServer

  import Kernel, except: [send: 2]

  @doc """
    Sends a synchrounous request to the `server` and waits for its reply.
    See `GenServer.cast/3`.
  """
  @spec call(GenServer.server(), term(), timeout()) :: term()
  def call(player, request, timeout \\ 5000) do
    GenServer.call(player, {:"$exlink_call", request}, timeout)
  end

  @doc """
    Sends an asynchrounous request to the `server`.
    See `GenServer.call/3`.
  """
  @spec cast(GenServer.server(), term()) :: :ok
  def cast(player, request) do
    GenServer.cast(player, {:"$exlink_cast", request})
  end

  @doc false
  @spec dispatch(GenServer.server(), term()) :: :ok
  def dispatch(player, data) do
    GenServer.cast(player, {:"$exlink_dispatch", data})
  end

  @doc false
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @doc false
  def init({client, guild_id, module}) do
    module.init(client, guild_id)
    |> case do
      {:ok, module_state} ->
        state = %{
          module: module,
          module_state: module_state,
          client: client,
          guild_id: guild_id
        }

        {:ok, state}

      {:stop, _reason} = stop ->
        ExLink.Connection.send(client, ExLink.Message.stop(guild_id))

        stop
    end
  end

  @doc false
  def handle_info(
        msg,
        %{module: module, module_state: module_state} = state
      ) do
    module.handle_info(msg, module_state)
    |> handle_async(state)
  end

  @doc false
  def handle_call(
        {:"$exlink_call", data},
        from,
        %{module: module, module_state: module_state} = state
      ) do
    module.handle_call(data, from, module_state)
    |> case do
      {:reply, reply, new_state} ->
        {:reply, reply, %{state | state: new_state}}

      {:noreply, new_state} ->
        {:noreply, %{state | state: new_state}}

      {:stop, reason, reply, new_state} ->
        ExLink.Connection.send(state.client, ExLink.Message.stop(state.guild_id))

        {:stop, reason, reply, %{state | state: new_state}}

      {:stop, reason, new_state} ->
        ExLink.Connection.send(state.client, ExLink.Message.stop(state.guild_id))

        {:stop, reason, %{state | state: new_state}}
    end
  end

  @doc false
  def handle_cast(
        {:"$exlink_cast", data},
        %{module: module, module_state: module_state} = state
      ) do
    module.handle_cast(data, module_state)
    |> handle_async(state)
  end

  def handle_cast(
        {:"$exlink_dispatch", data},
        %{module: module, module_state: module_state} = state
      ) do
    module.handle_dispatch(data, module_state)
    |> handle_async(state)
  end

  @doc false
  defp handle_async(ret, state) do
    case ret do
      {:noreply, new_state} ->
        {:noreply, %{state | module_state: new_state}}

      {:stop, reason, new_state} ->
        ExLink.Connection.send(state.client, ExLink.Message.stop(state.guild_id))

        {:stop, reason, %{state | module_state: new_state}}
    end
  end

  @doc false
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]}
    }
  end
end
