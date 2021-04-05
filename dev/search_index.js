var documenterSearchIndex = {"docs":
[{"location":"functions/#Index","page":"Functions","title":"Index","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"","category":"page"},{"location":"functions/#Functions","page":"Functions","title":"Functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"Modules = [VariableFrequencyOPF]","category":"page"},{"location":"functions/#VariableFrequencyOPF.frequency_ranges-Tuple{Any, Any, Int64, String, String, Array, Array}","page":"Functions","title":"VariableFrequencyOPF.frequency_ranges","text":"function frequency_ranges(\n  f_min,\n  f_max,\n  subnet::Int64,\n  directory::String,\n  objective::String,\n  x_axis::Array,\n  y_axis::Array;\n  gen_areas=Int64[],\n  area_transfer=Int64[],\n  gen_zones=[],\n  zone_transfer=[],\n  plot_vert_line::Tuple=([],\"\"),\n  plot_horiz_line::Tuple=([],\"\"),\n  xlimits::Array{Any,1}=[],\n  ylimits::Array{Any,1}=[],\n  output_plot_label::Tuple{String,String}=(\"\",\"\"),\n  scopf::Bool=false,\n  contingency::Int64=0,\n  k_cond=[],\n  k_ins=[],\n  scale_load=1.0,\n  scale_areas=Int64[],\n  no_converter_loss=false,\n  output_location_base=\"\",\n  output_results_folder=\"\"\n)\n\nModels and solves an OPF with frequency in specified ranges between f_min and f_max.\n\nArguments\n\nf_min: lower bounds on frequency, one for each point in the frequency sweep\nf_max: upper bounds on frequency, one for each point in the frequency sweep. Must have the same length as f_min.\nsubnet::Int64: subnetwork for which the frequency bounds are applied\nfolder::String: the directory containing all subnetwork data, subnetworks.csv, and interfaces.csv\nobjective::String: the objective function to use, from the following:\n\"mincost\": minimize generation cost\n\"areagen\": minimize generation in the areas specified in gen_areas\n\"zonegen\": minimize generation in the zones specified in gen_zones\n\"minredispatch\": minimize the change in generator dispatch from the initial values defined in the network data\nx_axis::Array: Array of Tuples identifying the x axis series for which plots should be generated over the points in the frequency sweep. A separate folder of plots is generated for each Tuple in the array. The series can be specified in the Tuple in one of three ways:\nresults dictionary values: A two-element Tuple, where the first element is a String matching a key in the results dictionary output from multifrequency_opf and the second element is an Int specifying a subnetwork. This plots the values of this key and subnetwork entry on the x axis.\nnetwork data values: A Tuple with elements corresponding to keys at each level of the network data dictionary, identifying any network variable value. This plots the values of the specified network variable on the x axis. Any key in the Tuple may be an Array, in which case a separate plot is generated for each key. For example, to generate four plots, the active and reactive power at the origin (\"f\") bus and destination (\"t\") bus for branch 1 in subnetwork 2, use the Tuple (\"sn\",2,\"branch\",1,[\"pt\",\"pf\",\"qt\",\"qf\"])\ncustom values: A two-element Tuple, where the first element is a String not matching any keys in the results dictionary and the second element is an Array. This plots the values in the Array on the x axis with the label in the String.\ny_axis::Array: Array of Tuples identifying the y axis series for which plots should be generated over the points in the frequency sweep. A separate folder of plots is generated for each Tuple in the array. These are specified in the same way as x_axis.\ngen_areas: all areas in which generation should be minimized if obj==\"areagen\"\narea_transfer: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.\ngen_zones: all zones in which generation should be minimized if obj==\"zonegen\"\nzone_transfer: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.\nplot_vert_line::Tuple: x values of vertical lines to overlay on the plot. The first element is a scalar or Array specifying one or more x values to plot, and the second element is a String or Array of Strings specifying the label or labels. Default ([],\"\") does not add any lines to the plot.\nplot_horiz_line::Tuple: y values of horizontal lines to overlay on the plot. The first element is a scalar or Array specifying one or more y values to plot, and the second element is a String or Array of Strings specifying the label or labels. Default ([],\"\") does not add any lines to the plot.\nxlimits::Array{Any,1}: Array of two values specifying the min and max x axis limits to apply to the plots, overriding any other limits. Default [] does not change the plot.\nylimits::Array{Any,1}: Array of two values specifying the min and max y axis limits to apply to the plots, overriding any other limits. Default [] does not change the plot.\noutput_plot_label::Tuple{String,String}: specifies the plot to pass to the output. The first element must match the x axis label, and the second must match the y axis label.\nscopf::Bool: if true, model and solve the N-1 security constrained OPF for each network. Each network folder must contain a contingency specification file (*.con) for each subnetwork. Default false.\ncontingency::Tuple: indices of the contingency to plot. The precontingency index is (0,). Default (0,).\nk_cond: conductor utilization parameter for HVDC. Only used when f==0. Default [].\nk_ins: insulation factor parameter for HVDC. Only used when f==0. Default [].\nscale_load: factor for scaling the load in the frequency sweep. Default 1.0.\nscale_areas: array of integer area indices for which the load scaling factor scale_load should be applied. Applies to all areas if this array is empty. Default Int64[].\nno_converter_loss: override all converter loss parameters specified in the data and replace them with the the lossless converter model.\noutput_location_base: location in which to save the results and plots. If not specified, a folder called results will be created in the folder one level above the data folder.\noutput_results_folder: specific folder in which to save the results, one level below output_location_base, if specified.\n\n\n\n\n\n","category":"method"},{"location":"functions/#VariableFrequencyOPF.make_mn_data-Tuple{Any, Any, Dict}","page":"Functions","title":"VariableFrequencyOPF.make_mn_data","text":"function make_mn_data(\n    subnetworks,\n    interfaces,\n    networks::Dict\n)\n\nBuilds the mn_data dictionary from the specifications of the subnetworks and interfaces DataFrames and the network data in the networks Dict.\n\nArguments\n\nsubnetworks: a DataFrame in the format of subnetworks.csv, and interfaces.csv\ninterfaces: a DataFrame in the format of interfaces.csv\nnetworks::Dict: a Dict of all subnetworks, as PowerModels networks\n\n\n\n\n\n","category":"method"},{"location":"functions/#VariableFrequencyOPF.multifrequency_opf-Tuple{String, String}","page":"Functions","title":"VariableFrequencyOPF.multifrequency_opf","text":"multifrequency_opf(\n    folder::String,\n    obj::String;\n    gen_areas=[],\n    area_interface=[],\n    gen_zones=[],\n    zone_interface=[],\n    print_results::Bool=false,\n    override_param::Dict{Any}=Dict(),\n    fix_f_override::Bool=false,\n    direct_pq::Bool=true,\n    master_subnet::Int64=1,\n    suffix::String=\"\",\n    start_vals=Dict{String, Dict}(\"sn\"=>Dict()),\n    no_converter_loss::Bool=false,\n    uniform_gen_scaling::Bool=false,\n    unbounded_pg::Bool=false\n)\n\nModels and solves the OPF for a single network with data contained in folder.\n\nArguments\n\nfolder::String: the directory containing all subnetwork data, subnetworks.csv, and interfaces.csv\nobj::String: the objective function to use, from the following:\n\"mincost\": minimize generation cost\n\"areagen\": minimize generation in the areas specified in gen_areas\n\"zonegen\": minimize generation in the zones specified in gen_zones\n\"minredispatch\": minimize the change in generator dispatch from the initial values defined in the network data\ngen_areas: integer array of all areas in which generation should be minimized if obj==\"areagen\"\narea_interface: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.\ngen_zones: integer array of all zones in which generation should be minimized if obj==\"zonegen\"\nzone_interface: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.\nprint_results::Bool: if true, print the DataFrames containing the output values for buses, branches, generators, and interfaces. These values are always saved to the output .csv files whether true or false.\noverride_param::Dict{Any}: values to override in the network data defined in folder. Must follow the same structure as the full network data dictionary, beginning with key \"sn\". Default empty Dict.\nfix_f_override::Bool: if true, fix the frequency in every subnetwork to the base value, overriding the variable_f parameter to variable_f=false for every subnetwork. Default false.\ndirect_pq::Bool: If direct_pq is false, then the interface is treated as a single node and power flow respects Kirchoff Laws, by constraining the voltage magnitude and angle on each side to be equal and enforcing reactive power balance. Default true.\nmaster_subnet::Int64: if direct_pq==false, the angle reference must be defined for exactly one subnetwork, since the other subnetwork angles are coupled through the interfaces. Value of master_subnet defines which subnetwork provides this reference. Default 1.\nsuffix::String: suffix to add to the output directory when saving results. Default empty string.\nstart_vals: Nested dictionary populated with values to be used as a starting point in the optimization model. Applies to bus vm and va, gen pg and qg, branch pt, pf, qt and qf and subnet f. Any of these values which are present in the dictionary will be applied; other values will be ignored. A full network data dictionary can be used. Default Dict{String, Dict}(\"sn\"=>Dict()).\n\n\n\n\n\n","category":"method"},{"location":"functions/#VariableFrequencyOPF.read_sn_data-Tuple{String}","page":"Functions","title":"VariableFrequencyOPF.read_sn_data","text":"read_sn_data(folder::String)\n\nReads a network folder and builds the mn_data dictionary.\n\nArguments\n\nfolder::String: the path to the folder containing all the network data\n\n\n\n\n\n","category":"method"},{"location":"functions/#VariableFrequencyOPF.run_subnets-Tuple{String, String}","page":"Functions","title":"VariableFrequencyOPF.run_subnets","text":"runsubnets(       parentfolder::String,       objective::String;       genareas::Array=[],       areatransfer::Array=[],       genzones::Array=[],       zonetransfer::Array=[],       enumbranches::Bool=false,       plotbestx::Int64=-1,       scopf::Bool=false,       ctgplots::Array{Int64,1}=[0],       runfixf::Bool=false,       runindirPQ::Bool=false,       print_results::Bool=false    )\n\nModels and solves an OPF for every network in a directory.\n\nArguments\n\nparent_folder::String: a directory containing full network data for one or more networks, each in a folder containing all subnetwork data, subnetworks.csv, and interfaces.csv\nobj::String: the objective function to use, from the following:\n\"mincost\": minimize generation cost\n\"areagen\": minimize generation in the areas specified in gen_areas\n\"zonegen\": minimize generation in the zones specified in gen_zones\n\"minredispatch\": minimize the change in generator dispatch from the initial values defined in the network data\ngen_areas::Array{Int64,1}: all areas in which generation should be minimized if obj==\"areagen\"\narea_transfer::Array{Int64,1}: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.\ngen_zones::Array{Int64,1}: all zones in which generation should be minimized if obj==\"zonegen\"\nzone_transfer::Array{Int64,1}: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.\nenum_branches::Bool: if true, collect results from each folder for plotting bar graphs. This is used when the possible branch upgrades have been enumerated and a comparison is desired. Default false.\nplot_best_x::Int64: number of results to plot, sorted from smallest to largest objective. If plot_best_x <= 1, the results of all networks which gave feasible solutions are plotted. Default -1.\nscopf::Bool: if true, model and solve the N-1 security constrained OPF for each network. Each network folder must contain a contingency specification file (*.con) for each subnetwork. Default false.\nctg_plots::Array{Int64,1}: indices of the contingencies to plot. The base case index is 0. Default [0].\n\n\n\n\n\n","category":"method"},{"location":"functions/#VariableFrequencyOPF.upgrade_branches-Tuple{String, String, Any}","page":"Functions","title":"VariableFrequencyOPF.upgrade_branches","text":"function upgrade_branches(\n   base_network::String,\n   output_location::String,\n   fbase;\n   indices=[],\n   output_type=\"input\"\n   )\n\nCreates a folder of network data for the network base_network with one line converted to LFAC, one for each index in indices, or if indices is empty, for every non-transformer branch in the network.\n\n\n\n\n\n","category":"method"},{"location":"frequency_examples/#Analyze-the-frequency-dependence-of-performance-under-different-upgrades","page":"Analyzing Frequency Dependence","title":"Analyze the frequency dependence of performance under different upgrades","text":"","category":"section"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"Here we consider multi-terminal upgrades in the Nordic system, consisting of a corridor or meshed collection of lines upgraded to a low frequency AC subnetwork. We consider three such upgrades, represented with the data in the folders multiterminal2, multiterminal4, multiterminal7, and multiterminal10 in test/data/nordic_fault_multiterminal. For each upgrade, we solve the OPF with a fixed LFAC subnetwork frequency and repeat over a range of frequencies, saving the resulting quantities as series versus the LFAC frequency. For this, we use frequency_ranges. The fmin and fmax arguments allow us to specify a range of frequencies for each step if their values are different. Here, we keep the frequency fixed at each step by making them equal, and we use a step size of 1 Hz. The multi-terminal upgrades used in this example are shown as network diagrams below.","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"using VariableFrequencyOPF\n\nbase_folder = \"test/data/nordic_fault_multiterminal\"\nfolders = [\n    \"multiterminal2\",\n    \"multiterminal4\",\n    \"multiterminal7\",\n    \"multiterminal10\"\n]\nfmin = 0:1:50\nfmax = 0:1:50\nlfac_subnet = 2\nresults_dicts = Array{Dict}(undef, length(folders))\noutput_plots = Array{Any}(undef, length(folders))\nfor (i,f) in enumerate(folders)\n    (results_dicts[i], output_plots[i]) = VariableFrequencyOPF.frequency_ranges(\n        fmin,\n        fmax,\n        lfac_subnet,\n        base_folder*\"/$f/\",\n        \"areagen\",\n        [(\"frequency (Hz)\",2)],\n        [];\n        gen_areas=[2,3],\n        area_transfer=[1,2],\n        no_converter_loss=true\n    )\nend","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"This plots the results versus frequency for each upgrade. To plot all upgrades together, we use the results dictionaries we've saved and plot the values with plot_results_dict_line.","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"subnet_arr = results_dicts[1][\"subnet\"][1]\n\nx_axis = (\"frequency (Hz)\", 2)\noutput_folder = \"results/nordic_fault_multiterminal/sweep_comparison/\"\nvert_line = ([],\"\")\nhoriz_line = ([],\"\")\nxlimits = []\nylimits = []\noutput_plot_label = (\"\",\"\")\nseries_labels = folders\n# plot the results\nVariableFrequencyOPF.plot_results_dict_line(\n    results_dicts,\n    subnet_arr,\n    x_axis,\n    output_folder,\n    vert_line,\n    horiz_line,\n    xlimits,\n    ylimits,\n    output_plot_label,\n    series_labels=series_labels,\n    plot_infeasible_boundaries=false,\n    color_palette=:Paired_12\n)","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"One resulting plot shows the objective value, generation in the Central and South areas, versus the LFAC frequency for all four upgrades: (Image: total generation in areas 2 and 3 (p.u.))","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"The multi-terminal upgrades used in this example are the following:","category":"page"},{"location":"frequency_examples/","page":"Analyzing Frequency Dependence","title":"Analyzing Frequency Dependence","text":"(Image: multiterminal2) (Image: multiterminal4) (Image: multiterminal7) (Image: multiterminal10)\nMultiterminal upgrade 2 Multiterminal upgrade 4 Multiterminal upgrade 7 Multiterminal upgrade 10","category":"page"},{"location":"comparison_examples/#Solve-the-OPF-for-a-set-of-upgrades","page":"Comparing Upgrades","title":"Solve the OPF for a set of upgrades","text":"","category":"section"},{"location":"comparison_examples/","page":"Comparing Upgrades","title":"Comparing Upgrades","text":"We want to define a set of upgrades in the Nordic system, each consisting of a single point-to-point upgrade. We use the function enumerate_branches to create the network data for each upgraded case. This generates a folder of network data for the single network file base_network with one line converted to LFAC, once for each index in indices, or if indices is empty, for every non-transformer branch in the network. Once we have created the data for each of these upgrades, we can call run_series to solve the OPF for each upgrade.","category":"page"},{"location":"comparison_examples/","page":"Comparing Upgrades","title":"Comparing Upgrades","text":"using VariableFrequencyOPF\n\noriginal_network = \"test/data/nordic_fault/base/fault_4032_4044.m\"\n# We choose to put the new network data in the same folder because\n# we also want to use some data that is already there. Each upgrade\n# gets its own folder.\nnew_data_directory = \"test/data/nordic_fault/\"\nstandard_frequency = 50.0\nlfac_branch_upgrades = [21,27,28,29,30,31,32,33]\n\nVariableFrequencyOPF.upgrade_branches(\n    original_network,\n    new_data_directory,\n    standard_frequency,\n    indices=lfac_branch_upgrades\n)\n\n# Minimize generation in areas 2 and 3 with plots including\n# the power flow between areas 1 and 2\nobjective = \"areagen\"\ngen_areas = [2,3]\narea_transfer = [1,2]\n# We want to plot the results of all branch upgrades,\n# so we set `enum_branch` to true\nenum_branches = true\n\nsolution =  VariableFrequencyOPF.run_series(\n    new_data_directory,\n    objective;\n    gen_areas=gen_areas,\n    area_transfer=area_transfer,\n    enum_branches=enum_branches\n)\nresults_dict = solution[1]\nn_subnets = solution[2]\nsubnet_array = solution[3]\nidx_sorted = solution[4]\nseries_output_folder = solution[5]\nplot_best_x = solution[6]\n\nprintln(\"Ran the OPF for all folders and saved the outputs in $series_output_folder.\")\n\n# Now we generate plots showing the results across all the upgrades.\n# We could plot multiple series (e.g. with different operating conditions,\n# converter parameters, etc.) on the same x axis by adding them\n# to the following array. Here we only plot one.\nresults_dict_allplots = [results_dict]\n\nplot_output_folder = \"results/nordic_fault/\"\nseries_labels = [\"LFAC upgrades\"]\n\nVariableFrequencyOPF.plot_results_dicts_bar(\n    results_dict_allplots,\n    n_subnets,\n    subnet_array,\n    idx_sorted,\n    plot_output_folder,\n    plot_best_x,\n    series_labels,\n    color_palette=:Dark2_8\n)","category":"page"},{"location":"comparison_examples/","page":"Comparing Upgrades","title":"Comparing Upgrades","text":"The function run_series solves the OPF for each upgrade and generates results in .csv files. The next function, plot_results_dicts_bar, generates and saves plots of certain variables. For example, we can look at the plot of the objective value, total generation in areas 2 and 3 (p.u.): (Image: total generation in areas 2 and 3 (p.u.))","category":"page"},{"location":"opf_examples/#Example-workflow-for-a-low-frequency-AC-upgrade","page":"Variable Frequency OPF","title":"Example workflow for a low frequency AC upgrade","text":"","category":"section"},{"location":"opf_examples/#Solving-the-OPF-without-upgrades","page":"Variable Frequency OPF","title":"Solving the OPF without upgrades","text":"","category":"section"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"We begin by solving the optimal power flow for a network with a single, fixed frequency. Consider the 5 bus network shown here:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"(Image: 5 bus network)","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"It is represented in a MATPOWER case file: case5.m","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"For this example, we put this file in a folder called base inside a parent folder case5 for all the cases we'll consider here. This will be the base network without any upgrades.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Because the functions in this package expect networks which may have variable frequency portions, we need to specify some details about frequency. This is done by creating a file in the same folder, called subnetworks.csv. This file must specify the name of the network data file, whether it is a variable frequency network, and at what frequency all the parameters in the network data file are defined. If the frequency is variable, it also must specify the upper and lower limits of the frequency.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"index file variable_f f_base f_min f_max\n1 case5.m false 60  ","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Now we can solve the standard AC OPF for this network, with the objective of minimizing cost:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"using VariableFrequencyOPF\n\ndata_folder = \"test/data/case5/base/\"\nobjective = \"mincost\"\n\nsolution = VariableFrequencyOPF.multifrequency_opf(data_folder, objective)\n\n# The first element in the solution output is a dictionary containing several important results.\nresults_dict = solution[1]\nprintln(results_dict)","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"The output looks like this. The result values are in arrays, where each element corresponds to a subnetwork. We only have one subnetwork here.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Dict{String,Any} with 11 entries:\n  \"frequency (Hz)\" => [60.0]\n  \"total loss\"     => [0.0519209]\n  \"converter loss\" => [0.0]\n  \"status\"         => LOCALLY_SOLVED\n  \"CPU time (s)\"   => 0.826\n  \"iterations\"     => 28\n  \"total time (s)\" => 0.860499\n  \"subnet\"         => [1]\n  \"cost\"           => [17551.9]\n  \"generation\"     => [10.0519]\n  \"line loss\"      => [0.051921]","category":"page"},{"location":"opf_examples/#Upgrading-a-line-to-low-frequency-AC","page":"Variable Frequency OPF","title":"Upgrading a line to low frequency AC","text":"","category":"section"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Now we would like to upgrade one line to low frequency AC (LFAC) and solve the OPF with frequency as a variable. An upgrade of line 2 will make this line into its own variable frequency subnetwork, like this:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"(Image: 5 bus network)","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"To present this data to VariableFrequencyOPF, we need to create a new network file for the subnetwork, modify the original, add a line to subnetworks.csv and specify some details about how the subnetworks connect through another file, interfaces.csv.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"The function upgrade_branches takes care of all of these steps for us.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"base_network = \"test/data/case5/base/case5.m\"\noutput_location = \"test/data/case5/\"\nbase_frequency = 60.0\nbranches_to_upgrade = [2]\n# We neglect converter losses in this example\nnoloss = true\n\nVariableFrequencyOPF.upgrade_branches(\n    base_network,\n    output_location,\n    base_frequency\n    indices=branches_to_upgrade,\n    noloss=noloss\n)","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"This creates a new folder inside case5 called br2. In this folder, we have case5.m with line 2 removed and a new network file, lfac_case5.m, which has two LFAC buses and the line which was formerly line 2 between them. We also have subnetworks.csv with a new row:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"index file variable_f f_base f_min f_max\n1 case5.m false 60  \n2 lfac_case5.m true 60 0.1 100","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"This allows the frequency to vary between 0.1 and 100 Hz in the LFAC subnetwork.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"We also have a new file, interaces.csv, specifying some details of the connections between the subnetworks. We set the converter losses to zero in this example, but we could specify any of these parameter values to model our converters and any filter or transformer branches connected to it. We can also specify the operating limits on current and voltage, respectively, of the converters with imax and vmax.","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"index subnet_index bus imax vmax c1 c2 c3 sw1 sw2 sw3 M smax R X G B transformer tap shift\n1 1 1 40 1.1 0 0 0 0 0 0 0.9 50 1.00E-05 0.001 0 0.0001 FALSE 1 0\n2 1 4 40 1.1 0 0 0 0 0 0 0.9 50 1.00E-05 0.001 0 0.0001 FALSE 1 0\n1 2 1 40 1.1 0 0 0 0 0 0 0.9 50 1.00E-05 0.001 0 0.0001 FALSE 1 0\n2 2 2 40 1.1 0 0 0 0 0 0 0.9 50 1.00E-05 0.001 0 0.0001 FALSE 1 0","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Now we can solve the OPF for this network:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"data_folder = \"test/data/case5/br2/\"\nobjective = \"mincost\"\n\nsolution = VariableFrequencyOPF.multifrequency_opf(data_folder, objective)\n\n# The first element in the solution output is a dictionary containing several important results.\nresults_dict = solution[1]\nprintln(results_dict)","category":"page"},{"location":"opf_examples/#Solve-the-OPF-for-a-network-with-a-variable-frequency-(low-frequency-AC)-portion","page":"Variable Frequency OPF","title":"Solve the OPF for a network with a variable frequency (low frequency AC) portion","text":"","category":"section"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Consider a power system which is divided into two areas connected by AC-AC converters: one operates at a fixed frequency of 60 Hz, and the other is a multi-terminal low frequency AC network, whose frequency can be chosen. In the directory test/data/case14_twoarea is data for a modified IEEE 14 bus network which fits this paradigm, as drawn here, with the variable frequency portion in blue:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"(Image: 14 bus network with LFAC)","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"In this example, we solve the OPF for this case, and we print the termination status, generation cost and optimal frequencies (The frequency of the standard part of the network is fixed at 60 Hz, and the frequency of the other part is allowed to vary between 1.0 and 100.0 Hz).","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"using VariableFrequencyOPF\n\ndata_folder = \"test/data/case14_twoarea/two_area/\"\nobjective = \"mincost\"\n\nsolution = VariableFrequencyOPF.multifrequency_opf(data_folder, objective)\n\nresults_dict = solution[1]\n\n# Print results\nprintln(\"Status:\")\nprintln(results_dict[\"status\"])\nprintln(\"\\nCost:\\n==============================\")\nprintln(\"Variable frequency subnetwork:\")\nprintln(results_dict[\"cost\"][1])\nprintln(\"Fixed frequency subnetwork:\")\nprintln(results_dict[\"cost\"][2])\nprintln(\"\\nFrequency:\\n==============================\")\nprintln(\"Variable frequency subnetwork:\")\nprintln(results_dict[\"frequency (Hz)\"][1])\nprintln(\"Fixed frequency subnetwork:\")\nprintln(results_dict[\"frequency (Hz)\"][2])","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"output:","category":"page"},{"location":"opf_examples/","page":"Variable Frequency OPF","title":"Variable Frequency OPF","text":"Status:\nLOCALLY_SOLVED\n\nCost:\n==============================\nVariable frequency subnetwork:\n7565.237470495639\nFixed frequency subnetwork:\n553.6125608844086\n\nFrequency:\n==============================\nVariable frequency subnetwork:\n1.0\nFixed frequency subnetwork:\n60.0","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = VariableFrequencyOPF","category":"page"},{"location":"#VariableFrequencyOPF.jl","page":"Home","title":"VariableFrequencyOPF.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package models and solves the AC optimal power flow (OPF) problem for networks with multiple frequencies, with each frequency as an optimization variable. This is useful for analyzing the system-level impacts of point-to-point and multi-terminal low frequency AC (LFAC) and high voltage DC (HVDC) upgrades.","category":"page"},{"location":"","page":"Home","title":"Home","text":"One main goal of this package is a flexible and extensible implementation which can fully accommodate the multi-frequency OPF formulation, in addition to power flow control between frequency areas. The power conversion devices which link these areas can be modeled with or without internal losses, filters, and transformers.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Another goal is a smooth extension of existing data formats to multi-frequency studies. The software supports industry standard steady state network modeling formats (PSS®E, Matpower, and PowerModels). Minimal additional parameter specifications are required: the frequency or allowable range of frequencies of each area, the connections between them, and the optional converter parameters.","category":"page"},{"location":"","page":"Home","title":"Home","text":"We hope that this package is useful to you. If you use it in published work, we ask that you would kindly include a mention of it and cite this publication:","category":"page"},{"location":"","page":"Home","title":"Home","text":"@misc{sehloff2021low,\n      title={Low Frequency AC Transmission Upgrades with Optimal Frequency Selection},\n      author={David Sehloff and Line Roald},\n      year={2021},\n      eprint={2103.06996},\n      archivePrefix={arXiv},\n      primaryClass={eess.SY}\n}","category":"page"},{"location":"#Getting-Started","page":"Home","title":"Getting Started","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package requires a Julia installation (≥1.5). See the Julia website for downloads and instructions: https://julialang.org/downloads/","category":"page"},{"location":"","page":"Home","title":"Home","text":"From a Julia terminal, this package can be installed through the package manager by providing the link to the repository. The package manager is accessed by typing the right bracket ] in the Julia terminal.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Add this package with the following command in the Julia terminal:","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add https://github.com/WISPO-POP/VariableFrequencyOPF.jl.git","category":"page"},{"location":"","page":"Home","title":"Home","text":"Or, if you prefer SSH and have it configured, you can use this:","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add git@github.com:WISPO-POP/VariableFrequencyOPF.jl.git","category":"page"},{"location":"","page":"Home","title":"Home","text":"Load the package:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using VariableFrequencyOPF","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can also run the package tests:","category":"page"},{"location":"","page":"Home","title":"Home","text":"] test VariableFrequencyOPF","category":"page"},{"location":"#Parsing-Network-Data","page":"Home","title":"Parsing Network Data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(Image: Flowchart for parsing)","category":"page"},{"location":"#Input-data","page":"Home","title":"Input data","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Each frequency area, or subnetwork, is described by a network data file in a standard format, including PSS&reg;E .raw files, Matpower .m files, or PowerModels dictionaries saved in formats such as .json.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The file subnetworks.csv contains the names of the network data files for each subnetwork, in the order in which they are to be parsed, and the subnetwork-wide frequency parameters, including a boolean specification of whether the frequency is variable, the base frequency at which the impedance parameters in the network file are defined, and the range of allowed frequencies. An example subnetworks.csv is shown here:","category":"page"},{"location":"","page":"Home","title":"Home","text":"index file variable_f f_base f_min f_max\n1 base_subnet.raw false 60 60 60\n2 lfac_subnet.raw true 60 10 50","category":"page"},{"location":"","page":"Home","title":"Home","text":"The file interfaces.csv specifies all the connections between different subnetworks. Each interface is given a unique integer index, and each row in the file which has this interface index specifies a connection to the interface. The rows specify the subnetwork and bus, along with any additional parameters, including the maximum apparent power in per unit. An example interfaces.csv file is shown below.","category":"page"},{"location":"","page":"Home","title":"Home","text":"index subnet_index bus s_max\n1 1 1011 10.0\n2 1 1013 10.0\n1 2 1 10.0\n2 2 2 10.0","category":"page"},{"location":"","page":"Home","title":"Home","text":"This example shows two interfaces. The first connects bus 1011 in subnetwork 1 to bus 1 in subnetwork 2, and the second connects bus 1013 in subnetwork 1 to bus 2 in subnetwork 2. The apparent power limit at each interface connection is 10.0 p.u.","category":"page"},{"location":"#Modeling-and-Solving-the-OPF","page":"Home","title":"Modeling and Solving the OPF","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(Image: Flowchart for OPF)","category":"page"}]
}
