defmodule CraftChat.MixProject do
  use Mix.Project

  def project do
    [
      app: :craft_chat,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CraftChat.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.16"},
      {:bandit, "~> 1.5"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:dotenvy, "~> 1.1"},
      {:mime, "~> 2.0"}
    ]
  end
end
