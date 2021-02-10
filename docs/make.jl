using VariableFrequencyOPF
using Documenter

makedocs(;
    modules=[VariableFrequencyOPF],
    authors="David Sehloff",
    repo="https://github.com/WISPO-POP/VariableFrequencyOPF.jl/blob/{commit}{path}#L{line}",
    sitename="VariableFrequencyOPF.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://WISPO-POP.github.io/VariableFrequencyOPF.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/WISPO-POP/VariableFrequencyOPF.jl",
)
