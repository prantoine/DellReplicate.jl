push!(LOAD_PATH, "../src/")

using DellReplicate
using Documenter

DocMeta.setdocmeta!(DellReplicate, :DocTestSetup, :(using DellReplicate); recursive=true)

makedocs(;
    modules=[DellReplicate],
    authors="prantoine <pol.antoine@sciencespo.fr> and contributors",
    repo="https://github.com/prantoine/DellReplicate.jl/blob/{commit}{path}#{line}",
    sitename="DellReplicate.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://prantoine.github.io/DellReplicate.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "General functions" => "generalfunctions.md",
        "Figure 1" => "figure1.md",
        "Figure 2" => "figure2.md",
        "Table 1" => "table1.md",
        "Table 2" => "table2.md"
    ],
)

deploydocs(;
    repo="github.com/prantoine/DellReplicate.jl",
    devbranch="main",
)
