using Documenter
using DataFrames
using CategoricalArrays

DocMeta.setdocmeta!(DataFrames, :DocTestSetup, :(using DataFrames); recursive=true)

# Build documentation.
# ====================

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

# Deploy built documentation.
# ===========================

deploydocs(
    # options
    repo = "github.com/JuliaData/DataFrames.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    devbranch = "main"
)
