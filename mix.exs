defmodule ExLink.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_link,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:websockex, "~> 0.4.2"},
      {:poison, ">= 0.0.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
