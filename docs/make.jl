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
        "Examples" => [
            "Variable Frequency OPF" => "opf_examples.md",
            "Comparing Upgrades" => "comparison_examples.md",
            "Analyzing Frequency Dependence" => "frequency_examples.md",
            "Analyzing LFAC Upgrades Across Multiple Time Points" => "timeseries.md"
            ],
        "Functions" => "functions.md"
    ],
)

deploydocs(;
    repo="github.com/WISPO-POP/VariableFrequencyOPF.jl.git",
)
