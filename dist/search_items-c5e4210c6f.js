searchNodes=[{"ref":"ExLink.html","title":"ExLink","type":"module","doc":"Handles WebSocket connections to a Lavalink node, providing: ExLink.Players to keep track of Lavalink players and control them ExLink.Messages to send via ExLink.Connection(s) A somewhat example: # define a player defmodule MyApp.Player do @behaviour ExLink.Player # required callbacks... end # define a supervisor defmodule MyApp.Supervisor do use Supervisor def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__) def init(_args) do children = [ {ExLink, {%{ url: &quot;ws://localhost:8080&quot;, authorization: &quot;123&quot;, shard_count: 1, user_id: 123_456_789_123_456_789, player: MyApp.Player }, name: MyApp.Player}} ] Supervisor.init(children, strategy: :one_for_one) end end # after starting the supervisor, play something message = ExLink.Message.play(track, guild_id) ExLink.Connection.send(MyApp.Player, message) Alternatively ExLink.Player provides a __using__ macro to directly start the module under a supervisor."},{"ref":"ExLink.html#child_spec/1","title":"ExLink.child_spec/1","type":"function","doc":"Returns a specification to start this module under a supervisor. See Supervisor."},{"ref":"ExLink.html#ensure_player/2","title":"ExLink.ensure_player/2","type":"function","doc":"Gets a player&#39;s pid, starting it if necessary."},{"ref":"ExLink.html#get_player/2","title":"ExLink.get_player/2","type":"function","doc":"Gets a player&#39;s pid or :error if not started."},{"ref":"ExLink.html#get_players/1","title":"ExLink.get_players/1","type":"function","doc":"Gets all player&#39;s pids mapped by guild ids."},{"ref":"ExLink.html#start_link/1","title":"ExLink.start_link/1","type":"function","doc":"Starts an ExLink process linked to the current process."},{"ref":"ExLink.html#t:options/0","title":"ExLink.options/0","type":"type","doc":"Options for start_link/1: :url - URL of the lavalink node. :authorization - Authorization for the lavalink node :shard_count - Number of shards :user_id - Id of the bot :player - Module implementing the ExLink.Player behaviour. Can be a Map or Keyword."},{"ref":"ExLink.Connection.html","title":"ExLink.Connection","type":"module","doc":"Handles the connection to a Lavalink node."},{"ref":"ExLink.Connection.html#forward/2","title":"ExLink.Connection.forward/2","type":"function","doc":"Forwards incoming Voice Server Updates and Voice State Updates to the Lavalink node."},{"ref":"ExLink.Connection.html#send/2","title":"ExLink.Connection.send/2","type":"function","doc":"Sends a ExLink.Message.message/0 or string to a Lavalink node."},{"ref":"ExLink.Message.html","title":"ExLink.Message","type":"module","doc":"Module used to build Outgoing Messages to send to a Lavalink node."},{"ref":"ExLink.Message.html#destroy/1","title":"ExLink.Message.destroy/1","type":"function","doc":"Builds a &quot;destroy&quot; message used to tell the server to disconnect from the voice server."},{"ref":"ExLink.Message.html#equalizer/2","title":"ExLink.Message.equalizer/2","type":"function","doc":"Builds an &quot;equalizer&quot; message used to change bands of a player. See this for more info on bands. (You need to scroll down until Using the player equalizer)"},{"ref":"ExLink.Message.html#pause/2","title":"ExLink.Message.pause/2","type":"function","doc":"Builds a &quot;pause&quot; (or &quot;resume&quot;) message to pause or resume playback of a player."},{"ref":"ExLink.Message.html#play/3","title":"ExLink.Message.play/3","type":"function","doc":"Builds a &quot;play&quot; message used to start playing a track."},{"ref":"ExLink.Message.html#seek/2","title":"ExLink.Message.seek/2","type":"function","doc":"Builds a &quot;seek&quot; message used to seek the position of a track. Time is in milliseconds."},{"ref":"ExLink.Message.html#stop/1","title":"ExLink.Message.stop/1","type":"function","doc":"Builds a &quot;stop&quot; message used to stop a player."},{"ref":"ExLink.Message.html#voice_update/3","title":"ExLink.Message.voice_update/3","type":"function","doc":"Builds a &quot;voice_update&quot; messages used to connect to a voice channel. event should be a voice_server_update. session_id is obtained from a voice_state_update."},{"ref":"ExLink.Message.html#volume/2","title":"ExLink.Message.volume/2","type":"function","doc":"Builds a &quot;volume&quot; message used to change the volume of a player. Volume may range from 0 to 1000. Default is 100."},{"ref":"ExLink.Message.html#t:id/0","title":"ExLink.Message.id/0","type":"type","doc":"Represents any discord snowflake. For example 218348062828003328 or &quot;218348062828003328&quot;."},{"ref":"ExLink.Message.html#t:message/0","title":"ExLink.Message.message/0","type":"type","doc":"Represents a built message."},{"ref":"ExLink.Player.html","title":"ExLink.Player","type":"behaviour","doc":"Player behaviour used to keep track of running players and manage them. Provides a __using__ macro to start the current module as a ExLink.Player directly under a supervisor. # This time `use ExLink.Player` instead defmodule MyApp.Player do use ExLink.Player def init(client, guild_id) do {:ok, {client, guild_id}} end # dispatches not related to a player (for example stats) # return value doesn&#39;t matter def handle_dispatch(data, nil) do IO.puts(&quot;Players: \#{data[&quot;players&quot;]}&quot;) nil end def handle_dispatch(data, state) do IO.puts(&quot;Received a \#{data[&quot;type&quot;]} event&quot;) {:noreply, state} end end # Now fits into a supervision tree directly defmodule MyApp.Supervisor do use Supervisor def start_link(args) do Supervisor.start_link(__MODULE__, args, name: __MODULE__) end def init(_args) do children = [ {MyApp.Player, {%{ url: &quot;ws://localhost:8080&quot;, authorization: &quot;123&quot;, shard_count: 1, user_id: 123_456_789_123_456_789, # player: Not needed here }, name: MyApp.Player}} ] Supervisor.init(children, strategy: :one_for_one)) end end # after starting the supervisor, play something message = ExLink.Message.play(track, guild_id) ExLink.Connection.send(MyApp.Player, message)"},{"ref":"ExLink.Player.html#call/3","title":"ExLink.Player.call/3","type":"function","doc":"Sends a synchrounous request to the server and waits for its reply. See GenServer.cast/3."},{"ref":"ExLink.Player.html#cast/2","title":"ExLink.Player.cast/2","type":"function","doc":"Sends an asynchrounous request to the server. See GenServer.call/3."},{"ref":"ExLink.Player.html#c:handle_call/3","title":"ExLink.Player.handle_call/3","type":"callback","doc":"Invoked to handle synchronous call/3 messages. call/3 will block until a reply is received (unless the call times out or nodes ar disconnected). See GenServer.handle_call/3."},{"ref":"ExLink.Player.html#c:handle_cast/2","title":"ExLink.Player.handle_cast/2","type":"callback","doc":"Invoked to handle asynchronous cast/2 messages. See GenServer.handle_cast/2."},{"ref":"ExLink.Player.html#c:handle_dispatch/2","title":"ExLink.Player.handle_dispatch/2","type":"callback","doc":"Invoked to handle events from a lavalink node. For non guild specific dispatches this function will be invoked outside of a player process, with the state nil. Return values will be ignored."},{"ref":"ExLink.Player.html#c:handle_info/2","title":"ExLink.Player.handle_info/2","type":"callback","doc":"Invoked to handle all other messages. See GenServer.handle_info/2."},{"ref":"ExLink.Player.html#c:init/2","title":"ExLink.Player.init/2","type":"callback","doc":"Invoked when the player is started. See GenServer.init/1."},{"ref":"ExLink.Player.html#t:common_return/0","title":"ExLink.Player.common_return/0","type":"type","doc":"Possible return values in handle_info/2, handle_cast/2, and handle_dispatch/2. handle_call/3 also allows to synchronously respond via additional allowed return values."}]