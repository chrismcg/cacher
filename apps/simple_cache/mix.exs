defmodule SimpleCache.Mixfile do
  use Mix.Project

  def project do
    [app: :simple_cache,
     version: "0.0.1",
     deps_path: "../../deps",
     lock_file: "../../mix.lock",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      applications: [:logger, :resource_discovery],
      included_applications: [:amnesia],
      mod: {SimpleCache, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:amnesia, github: "meh/amnesia"},
      {:resource_discovery, in_umbrella: true},
      {:exrm, "~> 0.14.11"}
    ]
  end
end
