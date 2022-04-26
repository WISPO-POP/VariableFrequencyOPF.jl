module VariableFrequencyOPF

#### Variable Frequency AC Optimal Power Flow ####

# Developed by David Sehloff (@dsehloff) and Line Roald (@lroald)

using PowerModels
using PowerModelsSecurityConstrained: parse_con_file
using Ipopt
using JuMP
using CSV
using DataFrames
using Statistics
using JSON
using Combinatorics
using CategoricalArrays
using Plots
using Plots.PlotMeasures
using StatsPlots
using Logging
# using AmplNLWriter
import Unicode
# import GR
import MathOptInterface

debuglogger = ConsoleLogger(stderr, Logging.Debug)
global_logger(debuglogger)

include("plot/bar-plots.jl")
include("plot/line-plots.jl")
include("plot/multi_plot_new.jl")

include("core/multifrequency-opf.jl")
include("core/variables.jl")
include("core/constraints.jl")
include("core/data-import.jl")
include("core/start-vals.jl")

include("app/control-multi-folder.jl")
include("app/fixf-indirPQ.jl")
include("app/frequency-sweep.jl")
include("app/hvdc-multi-folder.jl")
include("app/modify-network.jl")
include("app/run-models.jl")
include("app/benchmarking.jl")

include("util/collect-results.jl")
include("util/dict-util.jl")
include("util/multi-folder.jl")
include("util/no-loss-override.jl")
include("util/param-sweep.jl")
include("util/time_series_opf.jl")
include("util/time_parse.jl")


end
