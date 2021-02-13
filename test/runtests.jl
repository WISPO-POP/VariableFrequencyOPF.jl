using VariableFrequencyOPF
using Test

import JuMP
import MathOptInterface

@testset "VariableFrequencyOPF.jl" begin
    include("opf.jl")

    rm("results",force=true,recursive=true)
end
