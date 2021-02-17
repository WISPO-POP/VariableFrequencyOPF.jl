```@meta
CurrentModule = VariableFrequencyOPF
```

# VariableFrequencyOPF.jl
AC optimal power flow for networks with multiple frequencies, with each frequency as an optimization variable.

One main goal of this package is a flexible and extensible implementation which can fully accommodate the multiple and variable frequency OPF formulation with power flow control between frequency areas. This package allows additional modifications to the constraints and objective function as the analysis develops.

Another goal is a smooth extension of existing data formats to the case of multiple and variable frequencies. To this end, it is important that the software can import industry standard steady state network modeling formats with the minimum necessary additional specification of the parameters which are new to this framework.
## Getting Started
Add this package with the following command in the Julia REPL:

    ] add git@github.com:WISPO-POP/VariableFrequencyOPF.jl.git

or

    ] add https://github.com/WISPO-POP/VariableFrequencyOPF.jl.git

Load the package:

    using VariableFrequencyOPF

You can also run the package tests:

    ] test VariableFrequencyOPF

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
