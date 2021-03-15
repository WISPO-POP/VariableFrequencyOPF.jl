# VariableFrequencyOPF.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://WISPO-POP.github.io/VariableFrequencyOPF.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://WISPO-POP.github.io/VariableFrequencyOPF.jl/dev)
[![Build Status](https://github.com/WISPO-POP/VariableFrequencyOPF.jl/workflows/CI/badge.svg)](https://github.com/WISPO-POP/VariableFrequencyOPF.jl/actions)
[![Coverage](https://codecov.io/gh/WISPO-POP/VariableFrequencyOPF.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/WISPO-POP/VariableFrequencyOPF.jl)

## Description
This package models and solves the AC optimal power flow (OPF) problem for networks with multiple frequencies, with each frequency as an optimization variable. This is useful for analyzing the system-level impacts of point-to-point and multi-terminal low frequency AC (LFAC) and high voltage DC (HVDC) upgrades.

One main goal of this package is a flexible and extensible implementation which can fully accommodate the multi-frequency OPF formulation, in addition to power flow control between frequency areas. The power conversion devices which link these areas can be modeled with or without internal losses, filters, and transformers.

Another goal is a smooth extension of existing data formats to multi-frequency studies. The software supports industry standard steady state network modeling formats (PSS®E, Matpower, and PowerModels). Minimal additional parameter specifications are required: the frequency or allowable range of frequencies of each area, the connections between them, and the optional converter parameters.

We hope that this package is useful to you. If you use it in published work, we ask that you would kindly include a mention of it and cite this [publication](https://arxiv.org/abs/2103.06996):
```
@misc{sehloff2021low,
      title={Low Frequency AC Transmission Upgrades with Optimal Frequency Selection},
      author={David Sehloff and Line Roald},
      year={2021},
      eprint={2103.06996},
      archivePrefix={arXiv},
      primaryClass={eess.SY}
}
```
## Usage
Add this package with the following command in the Julia REPL:
```julia
] add https://github.com/WISPO-POP/VariableFrequencyOPF.jl.git
```
Or, if you prefer SSH and have it configured, you can use this:
```julia
] add git@github.com:WISPO-POP/VariableFrequencyOPF.jl.git
```

Load the package:

    using VariableFrequencyOPF

You can also run the package tests:

    ] test VariableFrequencyOPF

See the [documentation](https://WISPO-POP.github.io/VariableFrequencyOPF.jl/stable) for a guide to using the functions in this package.
