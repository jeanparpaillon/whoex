defmodule Whoex.Zones do
  @moduledoc """
  Store and retrieve authoritative zones
  """
  use Whoex.Records
  
  alias Whoex.Helpers
  alias Whoex.Zone
  alias Whoex.Storage

  @doc """
  Retrieve authority records for given query message
  (last question only)
  """
  @spec get_authority(dns_message) :: nil | [dns_rr]
  def get_authority(dns_message(questions: [])) do
    raise "No question in message"
  end

  def get_authority(dns_message(questions: questions)) do
    question = List.last(questions)

    question
    |> dns_query(:name)
    |> find_zone()
    |> case do
         nil -> nil
         zone -> Zone.authorities(zone)
       end
  end

  @doc """
  Store zone
  """
  def put(%Zone{name: name} = zone) do
    Storage.insert(:zones, {Helpers.normalize_name(name), zone})
  end

  ###
  ### Priv
  ###
  def find_zone(name) do
    name = Helpers.normalize_name(name)
    find_zone(name, :dns.dname_to_labels(name))
  end

  defp find_zone(_name, []), do: nil

  defp find_zone(name, [_ | labels]) do
    case Storage.select(:zones, name) do
      [{^name, zone}] ->
        zone

      _ ->
        case labels do
          [] ->
            nil

          _ ->
            find_zone(:dns.labels_to_dname(labels))
        end
    end
  end
end
