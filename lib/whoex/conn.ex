defmodule Whoex.Conn do
  @moduledoc """
  The Whoex connection.

  DNS message record and manipulation functions can be found here:
  `https://github.com/dnsimple/dns_erlang`

  TODO: import DNS message manipulation functions here
  """
  require Record

  import Whoex.Records

  alias Whoex.Records

  @type adapter :: {module, term}
  @type before_send :: [(t -> t)]
  @type halted :: boolean
  @type message :: Records.dns_message()
  @type owner :: pid
  @type private :: %{atom => any}
  @type state :: :unset | :set | :sent

  @type t :: %__MODULE__{
          adapter: adapter,
          before_send: before_send,
          halted: halted,
          owner: owner,
          private: private,
          query: message,
          reply: message,
          state: state
        }

  defstruct adapter: Whoex.MissingAdapter,
            before_send: [],
            halted: false,
            owner: nil,
            private: %{},
            query: nil,
            reply: nil,
            state: :unset

  defmodule NotSentError do
    defexception message: "a response was neither set nor sent from the connection"

    @moduledoc """
    Error raised when no response is sent in a request
    """
  end

  defmodule AlreadySentError do
    defexception message: "the response was already sent"

    @moduledoc """
    Error raised when trying to modify or send an already sent response
    """
  end

  alias Whoex.Conn
  @unsent [:unset, :set]
  @already_sent {:whoex_conn, :sent}

  @doc """
  Get query message
  """
  def query(%Conn{query: query}) do
    query
  end

  @doc """
  Returns query ID
  """
  def query_id(%Conn{query: dns_message(id: id)}) do
    id
  end

  @doc """
  Returns questions
  """
  def questions(%Conn{query: dns_message(questions: questions)}) do
    questions
  end

  @doc """
  Returns additional
  """
  def additional(%Conn{query: dns_message(additional: additional)}) do
    additional
  end

  @doc """
  Is response authoritative ?
  """
  def aa?(%Conn{reply: dns_message(aa: aa)}) do
    aa
  end

  def aa?(_) do
    raise NotSentError
  end

  @doc """
  Set authoritative answer
  """
  def aa(conn, authoritative \\ true)
  
  def aa(%Conn{reply: dns_message() = response} = conn, authoritative) do
    %{conn | reply: dns_message(response, aa: authoritative)}
  end

  def aa(_, _) do
    raise NotSentError
  end

  @doc """
  Returns response
  """
  def response(%Conn{reply: response}) do
    response
  end

  @doc """
  Assigns a new **private** key and value in the connection.

  This storage is meant to be used by libraries and frameworks to avoid writing
  to the user storage (the `:assigns` field). It is recommended for
  libraries/frameworks to prefix the keys with the library name.

  For example, if some plug needs to store a `:hello` key, it
  should do so as `:whoex_hello`:

      iex> conn.private[:whoex_hello]
      nil
      iex> conn = put_private(conn, :whoex_hello, :world)
      iex> conn.private[:whoex_hello]
      :world

  """
  @spec put_private(t, atom, term) :: t
  def put_private(%Conn{private: private} = conn, key, value) when is_atom(key) do
    %{conn | private: Map.put(private, key, value)}
  end

  @doc """
  Assigns multiple **private** keys and values in the connection.

  Equivalent to multiple `put_private/3` calls.

  ## Examples

      iex> conn.private[:plug_hello]
      nil
      iex> conn = merge_private(conn, whoex_hello: :world)
      iex> conn.private[:whoex_hello]
      :world
  """
  @spec merge_private(t, Keyword.t()) :: t
  def merge_private(%Conn{private: private} = conn, keyword) when is_list(keyword) do
    %{conn | private: Enum.into(keyword, private)}
  end

  @doc """
  Sends a response to the client.

  It expects the connection state to be `:set`, otherwise raises an
  `ArgumentError` for `:unset` connections or a `Whoex.Conn.AlreadySentError` for
  already `:sent` connections.

  At the end sets the connection state to `:sent`.
  """
  @spec send_resp(t) :: t | no_return
  def send_resp(conn)

  def send_resp(%Conn{state: :unset}) do
    raise ArgumentError, "cannot send a response that was not set"
  end

  def send_resp(%Conn{adapter: {adapter, payload}, state: :set, owner: owner} = conn) do
    conn = run_before_send(conn, :set)

    {:ok, payload} = adapter.send_resp(payload, conn.reply)

    send(owner, @already_sent)
    %{conn | adapter: {adapter, payload}, state: :sent}
  end

  def send_resp(%Conn{}) do
    raise AlreadySentError
  end

  @doc """
  Set message as reply and send it
  """
  def send_resp(conn, reply) do
    conn |> resp(reply) |> send_resp()
  end

  @doc """
  Sets the response to the given `message`.

  It sets the connection state to `:set` (if not already `:set`)
  and raises `Whoex.Conn.AlreadySentError` if it was already `:sent`.
  """
  def resp(%Conn{state: state}, _)
      when not (state in @unsent) do
    raise AlreadySentError
  end

  def resp(%Conn{}, nil) do
    raise ArgumentError, "response message cannot be set to nil"
  end

  def resp(%Conn{} = conn, reply)
      when Record.is_record(reply, :dns_message) do
    %{conn | reply: reply, state: :set}
  end

  @doc """
  Registers a callback to be invoked before the response is sent.

  Callbacks are invoked in the reverse order they are defined (callbacks
  defined first are invoked last).
  """
  @spec register_before_send(t, (t -> t)) :: t
  def register_before_send(%Conn{state: state}, _callback)
      when not (state in @unsent) do
    raise AlreadySentError
  end

  def register_before_send(%Conn{before_send: before_send} = conn, callback)
      when is_function(callback, 1) do
    %{conn | before_send: [callback | before_send]}
  end

  @doc """
  Halts the Plug pipeline by preventing further plugs downstream from being
  invoked. See the docs for `Plug.Builder` for more information on halting a
  plug pipeline.
  """
  @spec halt(t) :: t
  def halt(%Conn{} = conn) do
    %{conn | halted: true}
  end

  ###
  ### Priv
  ###
  defp run_before_send(%Conn{before_send: before_send} = conn, new) do
    conn = Enum.reduce(before_send, %{conn | state: new}, & &1.(&2))

    if conn.state != new do
      raise ArgumentError, "cannot send/change response from run_before_send callback"
    end

    conn
  end
end
