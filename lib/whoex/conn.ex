defmodule Whoex.Conn do
  @moduledoc """
  The Whoex connection.
  """
  use Whoex.Records
  use Whoex.Constants

  @type dname :: String.t
  @type adapter :: {module, term}
  @type message_id :: 0..65535
  @type opcode :: 0..16
  @type question :: dns_rr
  @type answer :: dns_rr
  @type authority :: dns_rr
  @type additional :: dns_rr
  @type before_send :: [(t -> t)]
  @type halted :: boolean
  @type owner :: pid
  @type private :: %{atom => any}
  @type state :: :unsent | :sent

  @type t :: %__MODULE__{
    adapter: adapter,
    id: message_id,
    qr: boolean,
    oc: opcode,
    aa: boolean,
    tc: boolean,
    rd: boolean,
    ra: boolean,
    ad: boolean,
    cd: boolean,
    rc: opcode,
    questions: [question],
    answers: [answer],
    authority: [authority],
    additional: [additional],
    before_send: before_send,
    halted: halted,
    owner: owner,
    private: private,
    state: state
  }

  defstruct adapter: Whoex.MissingAdapter,
    id: nil,
    qr: false,
    oc: @_DNS_OPCODE_QUERY,
    aa: false,
    tc: false,
    rd: false,
    ra: false,
    ad: false,
    cd: false,
    rc: @_DNS_RCODE_NOERROR,
    questions: [],
    answers: [],
    authority: [],
    additional: [],
    before_send: [],
    halted: false,
    owner: nil,
    private: %{},
    state: :unsent
  
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
  @already_sent {:whoex_conn, :sent}

  @doc """
  Creates connection (for use by adapters)
  """
  def new(adapter, owner, query) do
    %__MODULE__{
      adapter: adapter,
      owner: owner,
      id: dns_message(query, :id),
      qr: dns_message(query, :qr),
      oc: dns_message(query, :oc),
      aa: dns_message(query, :aa),
      tc: dns_message(query, :tc),
      rd: dns_message(query, :rd),
      ra: dns_message(query, :ra),
      ad: dns_message(query, :ad),
      cd: dns_message(query, :cd),
      questions: dns_message(query, :questions)
    }
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
  Set response from a dns_message record (from cache for instance)
  """
  @spec resp(t, dns_message) :: t
  def resp(conn, r) do
    conn
    |> Map.merge(%{
          oc: dns_message(r, :oc),
          aa: dns_message(r, :aa),
          tc: dns_message(r, :tc),
          rd: dns_message(r, :rd),
          ra: dns_message(r, :ra),
          ad: dns_message(r, :ad),
          cd: dns_message(r, :cd),
          rc: dns_message(r, :rc),
          questions: dns_message(r, :questions),
          answers: dns_message(r, :answers),
          authority: dns_message(r, :authority),
          additional: dns_message(r, :additional)
                 })
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

  def send_resp(%Conn{adapter: {adapter, payload}, state: :unsent, owner: owner} = conn) do
    conn = run_before_send(conn, :unsent)

    {:ok, payload} = adapter.send_resp(payload, response(conn))

    send(owner, @already_sent)
    %{conn | adapter: {adapter, payload}, state: :sent}
  end

  def send_resp(%Conn{}) do
    raise AlreadySentError
  end

  @doc """
  Add answer to the response
  """
  def add_answer(%Conn{state: :sent}, _) do
    raise AlreadySentError
  end

  def add_answer(%Conn{}, nil) do
    raise ArgumentError, "answer cannot be nil"
  end

  def add_answer(%Conn{answers: answers} = conn, dns_rr() = record) do
    %{conn | answers: [record | answers]}
  end

  @doc """
  Add authority record to the response
  """
  def add_authority(%Conn{state: :sent}, _) do
    raise AlreadySentError
  end
  
  def add_authority(%Conn{}, nil) do
    raise ArgumentError, "additional record cannot be nil"
  end
  
  def add_authority(%Conn{authority: authority} = conn, dns_rr() = record) do
    %{conn | authority: [record | authority]}
  end

  @doc """
  Add additional record to the response
  """
  def add_additional(%Conn{state: :sent}, _) do
    raise AlreadySentError
  end
  
  def add_additional(%Conn{}, nil) do
    raise ArgumentError, "additional record cannot be nil"
  end
  
  def add_additional(%Conn{additional: additional} = conn, dns_rr() = record) do
    %{conn | additional: [record | additional]}
  end

  @doc """
  Registers a callback to be invoked before the response is sent.

  Callbacks are invoked in the reverse order they are defined (callbacks
  defined first are invoked last).
  """
  @spec register_before_send(t, (t -> t)) :: t
  def register_before_send(%Conn{state: :sent}, _callback) do
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

  @doc """
  Return response as dns_message
  """
  @spec response(t) :: dns_message
  def response(conn) do
    dns_message(
      id: conn.id,
      qr: 1,
      oc: conn.oc,
      aa: conn.aa,
      tc: conn.tc,
      rd: conn.rd,
      ra: conn.ra,
      ad: conn.ad,
      cd: conn.cd,
      rc: conn.rc,
      qc: length(conn.questions),
      anc: length(conn.answers),
      auc: length(conn.authority),
      adc: length(conn.additional),
      questions: conn.questions,
      answers: conn.answers,
      additional: conn.additional
    )
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
