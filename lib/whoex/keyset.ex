defmodule Whoex.Keyset do
  @moduledoc """
  Keyset structure
  """
  defstruct key_signing_key: nil,
            key_signing_key_tag: 0,
            key_signing_alg: 0,
            zone_signing_key: nil,
            zone_signing_key_tag: 0,
            zone_signing_alg: 0,
            inception: nil,
            valid_until: nil

  @type t :: %__MODULE__{
          key_signing_key: :crypto.rsa_private(),
          key_signing_key_tag: non_neg_integer,
          key_signing_alg: non_neg_integer,
          zone_signing_key: :crypto.rsa_private(),
          zone_signing_key_tag: non_neg_integer,
          zone_signing_alg: non_neg_integer,
          inception: :erlang.timestamp() | :calendar.datetime1970(),
          valid_until: :erlang.timestamp() | :calendar.datetime1970()
        }
end
