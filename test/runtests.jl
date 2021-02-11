using VariableFrequencyOPF
using Test

import JuMP
import MathOptInterface

@testset "VariableFrequencyOPF.jl" begin
    include("opf.jl")
end
