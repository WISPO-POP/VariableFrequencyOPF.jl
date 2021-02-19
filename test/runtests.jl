using VariableFrequencyOPF
using Test

using JuMP
using MathOptInterface
using JSON

@testset "VariableFrequencyOPF.jl" begin
    include("opf.jl")
end
