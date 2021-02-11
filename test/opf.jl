### Tests for each OPF objective ###

@testset "mincost objective" begin
    base_data = "data/case14/base"
    result = VariableFrequencyOPF.multifrequency_opf(base_data, "mincost")
    @test result[1]["status"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(result[1]["cost"][1], 8081.5; atol = 1e0)
    rm("results",recursive=true)
end
