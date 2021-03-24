```@meta
CurrentModule = VariableFrequencyOPF
```

# VariableFrequencyOPF.jl
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
## Getting Started
This package requires a Julia installation (≥1.5). See the Julia website for downloads and instructions: [https://julialang.org/downloads/](https://julialang.org/downloads/)

From a Julia terminal, this package can be installed through the package manager by providing the link to the repository. The package manager is accessed by typing the right bracket `]` in the Julia terminal.

Add this package with the following command in the Julia terminal:
```
] add https://github.com/WISPO-POP/VariableFrequencyOPF.jl.git
```
Or, if you prefer SSH and have it configured, you can use this:
```
] add git@github.com:WISPO-POP/VariableFrequencyOPF.jl.git
```

Load the package:
```julia
using VariableFrequencyOPF
```

You can also run the package tests:
```julia
] test VariableFrequencyOPF
```

### Parsing Network Data
![Flowchart for parsing](examples/fig/flowchart_parsing.svg)
#### Input data
Each frequency area, or subnetwork, is described by a network data file in a standard format, including PSS&reg;E *.raw* files, Matpower *.m* files, or PowerModels dictionaries saved in formats such as *.json*.

The file *subnetworks.csv* contains the names of the network data files for each subnetwork, in the order in which they are to be parsed, and the subnetwork-wide frequency parameters, including a boolean specification of whether the frequency is variable, the base frequency at which the impedance parameters in the network file are defined, and the range of allowed frequencies. An example *subnetworks.csv* is shown here:

| index | file            | variable_f | f_base | f_min | f_max |
|-------|-----------------|------------|--------|-------|-------|
| 1     | base_subnet.raw | false      | 60     | 60    | 60    |
| 2     | lfac_subnet.raw | true       | 60     | 10    | 50    |

The file *interfaces.csv* specifies all the connections between different subnetworks. Each interface is given a unique integer index, and each row in the file which has this interface index specifies a connection to the interface. The rows specify the subnetwork and bus, along with any additional parameters, including the maximum apparent power in per unit. An example *interfaces.csv* file is shown below.

| index | subnet_index | bus  | s_max |
|-------|--------------|------|-------|
| 1     | 1            | 1011 | 10.0  |
| 2     | 1            | 1013 | 10.0  |
| 1     | 2            | 1    | 10.0  |
| 2     | 2            | 2    | 10.0  |

This example shows two interfaces. The first connects bus 1011 in subnetwork 1 to bus 1 in subnetwork 2, and the second connects bus 1013 in subnetwork 1 to bus 2 in subnetwork 2. The apparent power limit at each interface connection is 10.0 p.u.

### Modeling and Solving the OPF
![Flowchart for OPF](examples/fig/flowchart_opf.svg)
