### Tests for each OPF objective ###

@testset "mincost objective" begin
    base_data = "data/case14/base"
    result = VariableFrequencyOPF.multifrequency_opf(base_data, "mincost")
    @test result[1]["status"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(result[1]["cost"][1], 8081.5; atol = 1e0)

    variablef_data = "data/case14_twoarea/two_area/"
    result = VariableFrequencyOPF.multifrequency_opf(variablef_data, "mincost")
    @test result[1]["status"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(result[1]["cost"][1], 7565.2; atol = 1e0)
    @test isapprox(result[1]["cost"][2], 553.6; atol = 1e0)
    @test isapprox(result[1]["frequency (Hz)"][1], 1.0; atol = 1e0)
    @test isapprox(result[1]["frequency (Hz)"][2], 60.0; atol = 1e0)
end
