defmodule Lzf.MixProject do
  use Mix.Project

  def project do
    [
      app: :lzf,
      version: "0.1.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0"}
    ]
  end

  defp description do
    """
    LZF decompression algorithm in pure Elixir
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      source_url: "https://github.com/joshuawscott/lzf_elixir",
      maintainers: ["Joshua Scott"],
      links: %{"GitHub" => "https://github.com/joshuawscott/lzf_elixir"}
    ]
  end
end
