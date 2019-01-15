defmodule ExLink.Message do
  @moduledoc since: "0.1.0"
  @moduledoc """
    Module used to build [Outgoing Messages](https://github.com/Frederikam/Lavalink/blob/master/IMPLEMENTATION.md#outgoing-messages) to send to a Lavalink node.
  """

  @typedoc """
    Represents any discord snowflake.

    For example `218348062828003328` or `"218348062828003328"`.
  """
  @typedoc since: "0.1.0"
  @type id :: String.t() | non_neg_integer()

  @typedoc """
    Represents a built message.
  """
  @typedoc since: "0.1.0"
  @type message :: map()

  @doc """
    Builds a "voice_update" messages used to connect to a voice channel.

  > `event` should be a [voice_server_update](https://discordapp.com/developers/docs/topics/gateway#voice-server-update).
  > `session_id` is obtained from a [voice_state_update](https://discordapp.com/developers/docs/resources/voice#voice-state-object).
  """
  @doc since: "0.1.0"
  @spec voice_update(event :: map(), session_id :: id(), guild_id :: id()) :: message()
  def voice_update(event, session_id, guild_id) do
    %{"sessionId" => session_id, "event" => event}
    |> finalize("voiceUpdate", guild_id)
  end

  @doc """
    Builds a "play" message used to start playing a track.
  """
  @doc since: "0.1.0"
  @spec play(
          track :: String.t(),
          guild_id :: id(),
          opts ::
            [{:startTime, Integer.t()} | {:endTime, Integer.t()} | {:noReplace, boolean()}]
            | %{
                optional(:startTime) => Integer.t(),
                optional(:endTime) => Integer.t(),
                optional(:noReplace) => boolean()
              }
        ) :: message()
  def play(track, guild_id, opts \\ %{}) do
    opts
    |> Map.new()
    |> Map.put("track", track)
    |> finalize("play", guild_id)
  end

  @doc """
    Builds a "stop" message used to stop a player.
  """
  @doc since: "0.1.0"
  @spec stop(guild_id :: id()) :: message()
  def stop(guild_id), do: finalize(%{}, "stop", guild_id)

  @doc """
    Builds a "pause" (or resume") message to pause or resume playback of a player.
  """
  @doc since: "0.1.0"
  @spec pause(paused :: boolean(), guild_id :: id()) :: message()
  def pause(paused, guild_id) do
    %{"pause" => paused}
    |> finalize("pause", guild_id)
  end

  @doc """
    Builds a "seek" message used to seek the position of a track.

  > Time is in milliseconds.
  """
  @doc since: "0.1.0"
  @spec seek(time_millis :: non_neg_integer(), guild_id :: id()) :: message()
  def seek(time_millis, guild_id) do
    %{"position" => time_millis}
    |> finalize("seek", guild_id)
  end

  @doc """
    Builds a "volume" message used to change the volume of a player.

  > Volume may range from 0 to 1000. Default is 100.
  """
  @doc since: "0.1.0"
  @spec volume(volume :: non_neg_integer(), guild_id :: id()) :: message()
  def volume(volume, guild_id) do
    %{"volume" => volume}
    |> finalize("volume", guild_id)
  end

  @doc """
    Builds an "equalizer" message used to change bands of a player.

  > See [this](https://github.com/Frederikam/Lavalink/blob/master/IMPLEMENTATION.md#opening-a-connection) for more info on `bands`.
  > (You need to scroll down until `Using the player equalizer`)
  """
  @doc since: "0.1.0"
  @spec equalizer(bands :: list(), guild_id :: id()) :: message()
  def equalizer(bands, guild_id) do
    %{"bands" => bands}
    |> finalize("equalizer", guild_id)
  end

  @doc """
    Builds a "destroy" message used to tell the server to disconnect from the voice server.
  """
  @doc since: "0.1.0"
  @spec destroy(guild_id :: id()) :: message()
  def destroy(guild_id) do
    %{}
    |> finalize("destroy", guild_id)
  end

  @spec finalize(data :: map(), op :: String.t(), guild_id :: id()) :: message()
  defp finalize(data, op, guild_id) do
    %{
      "op" => op,
      "guildId" => to_string(guild_id)
    }
    |> Map.merge(data)
  end
end
