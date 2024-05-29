using Documenter
using DataFrames

makedocs(
    # options
    modules = [DataFrames],
    doctest = false,
    clean = true,
    sitename = "DataFrames.jl",
    format = Documenter.HTML(
        canonical = "https://juliadata.github.io/DataFrames.jl/stable/",
        assets = ["assets/favicon.ico"],
        edit_link = "main",
        size_threshold_ignore = ["man/basics.md", "lib/functions.md"],
    ),
    pages = Any[
        "Introduction" => "index.md",
        "First Steps with DataFrames.jl" => "man/basics.md",
    ],
)
