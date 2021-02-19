### Tests for each OPF objective ###

@testset "mincost objective" begin
    base_data = "data/case14/base"
    result = VariableFrequencyOPF.multifrequency_opf(base_data, "mincost", output_to_files=false)
    @test result[1]["status"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(result[1]["cost"][1], 8081.5; atol = 1e0)

    variablef_data = "data/case14_twoarea/two_area/"
    result = VariableFrequencyOPF.multifrequency_opf(variablef_data, "mincost", output_to_files=false)
    @test result[1]["status"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(result[1]["cost"][1], 7565.2; atol = 1e0)
    @test isapprox(result[1]["cost"][2], 553.6; atol = 1e0)
    @test isapprox(result[1]["frequency (Hz)"][1], 1.0; atol = 1e0)
    @test isapprox(result[1]["frequency (Hz)"][2], 60.0; atol = 1e0)

    base_data = "data/case14/base"
    result = VariableFrequencyOPF.multifrequency_opf(base_data, "mincost", output_to_files=true)
    result_output_dict = JSON.parsefile("results/case14/base/output_values.json")
    @test result_output_dict["status"] == "LOCALLY_SOLVED"
    @test isapprox(result_output_dict["cost"][1], 8081.5; atol = 1e0)
    try
        rm("results",force=true,recursive=true)
    catch IOError
        println("Unable to delete the results files generated by this test.")
    end
end

@testset "areagen objective" begin
    original_network = "data/nordic_fault/base/fault_4032_4044.m"
    # We choose to put the new network data in the same folder because
    # we also want to use some data that is already there. Each upgrade
    # gets its own folder.
    new_data_directory = "results/inputs/nordic_fault/"
    standard_frequency = 50.0
    lfac_branch_upgrades = [27,33]

    VariableFrequencyOPF.upgrade_branches(
        original_network,
        new_data_directory,
        standard_frequency,
        indices=lfac_branch_upgrades
    )

    # Minimize generation in areas 2 and 3 with plots including
    # the power flow between areas 1 and 2
    objective = "areagen"
    gen_areas = [2,3]
    area_transfer = [1,2]
    # We want to plot the results of all branch upgrades,
    # so we set `enum_branch` to true
    enum_branches = true

    solution =  VariableFrequencyOPF.run_series(
        new_data_directory,
        objective;
        gen_areas=gen_areas,
        area_transfer=area_transfer,
        enum_branches=enum_branches
    )
    results_dict = solution[1]

    subnet1 = findall(results_dict["subnet"]["br27"].==1)[1]
    subnet2 = 3-subnet1

    @test results_dict["status"]["br27"] == MathOptInterface.LOCALLY_SOLVED
    @test results_dict["status"]["br33"] == MathOptInterface.LOCALLY_SOLVED
    @test isapprox(results_dict["cost"]["br27"][subnet1], 4.40154e6; rtol = 1e-2)
    @test isapprox(results_dict["cost"]["br27"][subnet2], 0.0; rtol = 1e-2)
    @test isapprox(results_dict["frequency (Hz)"]["br27"][subnet1], 50.0; atol = 1e0)
    @test isapprox(results_dict["frequency (Hz)"]["br27"][subnet2], 20.92; atol = 1e0)
    @test isapprox(results_dict["cost"]["br33"][subnet1], 4.36446e6; rtol = 1e-2)
    @test isapprox(results_dict["cost"]["br33"][subnet2], 0.0; rtol = 1e-2)
    @test isapprox(results_dict["frequency (Hz)"]["br33"][subnet1], 50.0; atol = 1e0)
    @test isapprox(results_dict["frequency (Hz)"]["br33"][subnet2], 22.43; atol = 1e0)
    try
        rm("results",force=true,recursive=true)
    catch IOError
        println("Unable to delete the results files generated by this test.")
    end
end
