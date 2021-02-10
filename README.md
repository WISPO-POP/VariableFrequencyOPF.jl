# VariableFrequencyOPF

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://WISPO-POP.github.io/VariableFrequencyOPF.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://WISPO-POP.github.io/VariableFrequencyOPF.jl/dev)
[![Build Status](https://github.com/WISPO-POP/VariableFrequencyOPF.jl/workflows/CI/badge.svg)](https://github.com/WISPO-POP/VariableFrequencyOPF.jl/actions)
[![Coverage](https://codecov.io/gh/WISPO-POP/VariableFrequencyOPF.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/WISPO-POP/VariableFrequencyOPF.jl)

## Description
AC optimal power flow for networks with multiple frequencies, with each frequency as an optimization variable.

One main goal of this package is a flexible and extensible implementation which can fully accommodate the multiple and variable frequency OPF formulation with power flow control between frequency areas. This package allows additional modifications to the constraints and objective function as the analysis develops.

Another goal is a smooth extension of existing data formats to the case of multiple and variable frequencies. To this end, it is important that the software can import industry standard steady state network modeling formats with the minimum necessary additional specification of the parameters which are new to this framework.
## Usage
Add this package with the following command in the Julia REPL:

    ] add git@github.com:WISPO-POP/VariableFrequencyOPF.jl.git

Load the package with

    using VariableFrequencyOPF
