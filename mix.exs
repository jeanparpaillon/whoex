defmodule Whoex.MixProject do
  use Mix.Project

  def project do
    [
      app: :whoex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(Mix.env()),
      dialyzer: [plt_add_deps: :project],
      test_coverage: [tools: ExCoveralls],

      # Docs
      name: "Whoex",
      source_url: "http://github.com/jeanparpaillon/whoex",
      homepage_url: "http://github.com/jeanparpaillon/whoex"
    ]
  end

  def application do
    [
      mod: {Whoex.App, []},
      extra_applications: [:logger]
    ]
  end

  defp aliases(:prod), do: []

  defp aliases(_),
    do: [
      compile: ["format", "compile"]
    ]

  defp deps do
    [
      # Dev and test
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.2", only: [:dev, :test], runtime: false},
      # Dev only
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      # Test only
      {:excoveralls, "~> 0.9", only: :test, runtime: false},
      # All envs
      {:quaff, github: "jeanparpaillon/quaff"},
      {:ranch, "~> 1.3"},
      {:dns, github: "dnsimple/dns_erlang"},
      {:poolboy, "~> 1.5"}
    ]
  end
end
