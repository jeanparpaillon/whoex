defmodule Whoex.Helpers do
  @moduledoc """
  Various (formatters) helpers
  """
  use Whoex.Records

  alias Whoex.Conn
  
  @doc """
  Normalize DNS zone names (lowercase)
  """
  @spec normalize_name(charlist | String.t()) :: String.t()
  def normalize_name(name) when is_list(name) do
    normalize_name("#{name}")
  end

  def normalize_name(name) do
    String.downcase(name)
  end

  @doc """
  Format DNS message questions
  """
  @spec fmt_questions([dns_query]) :: String.t
  def fmt_questions(questions) do
    questions
    |> Enum.map(&fmt_query/1)
    |> Enum.join(" ")
  end

  @doc """
  Format DNS message question
  """
  def fmt_query(dns_query(name: name, class: class, type: type)) do
    "[#{name} #{:dns.class_name(class)} #{:dns.type_name(type)}]"
  end

  @doc """
  Format DNS message answers
  """
  @spec fmt_answers(Conn.t) :: String.t
  def fmt_answers(%Conn{answers: answers}) do
    answers
    |> Enum.map(&fmt_answer/1)
    |> Enum.join(" ")
  end

  @doc """
  Format a DNS answer
  """
  def fmt_answer(dns_rr(name: name, class: class, type: type, ttl: ttl)) do
    "[#{name} #{:dns.class_name(class)} #{:dns.type_name(type)} (ttl: #{ttl})]"
  end
end
