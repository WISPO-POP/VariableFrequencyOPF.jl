# include("time_parse.jl")
# include("multifrequency-opf.jl")
# include("utilities.jl")

# function to run multifrequency_opf on one case within the given time range.
#
# parameters:
# month_st, day_st, period_st, month_en, day_en, period_en: the parameters specifying the period to plot
# folder: the directory containing all subnetwork data, subnetworks.csv, interfaces.csv
# subne_folder: the number of subnet that is to be optimized (which directs to the sub-folder containing its data)
# output_folder: the folder specified to save the output files
# plot_results: choice of plot the optimization result (optimal value vs time points) directly after optimization, default false Below are the similar arguments as multifrequency-opf:
# obj::String: the objective function to use, from the following:
# "mincost": minimize generation cost
# "areagen": minimize generation in the areas specified in gen_areas
# "minredispatch": minimize the change in generator dispatch from the initial values defined in the network data
# gen_areas: integer array of all areas in which generation should be minimized if obj=="mincost"
# area_transfer: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.
# print_results: if true, print the optimization results
###########################################################################################
# month_st, day_st, period_st, month_en, day_en, period_en: the
# folder::String:: the directory containing all subnetwork data, subnetworks.csv, interfaces.csv
# subne_folder: the number of subnet that is to be optimized (which directs to the sub-folder containing its data)
# output_folder: the folder specified to save the output files
# plot_results::Bool = true: choice of plot the optimization result (optimal value vs time points) directly after optimization, default false Below are the similar arguments as multifrequency-opf:
# obj::String: the objective function to use, from the following:
#     "mincost": minimize generation cost
#     "areagen": minimize generation in the areas specified in gen_areas
#     "minredispatch": minimize the change in generator dispatch from the initial values defined in the network data
# gen_areas: integer array of all areas in which generation should be minimized if obj=="mincost"
# area_transfer: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.
# print_results::Bool: if true, print the optimization results
# function to run multifrequency-opf on the specified case with the specified range of time
function hour_opf(month_st, day_st, period_st, month_en, day_en, period_en,
      folder:: String,
      subnet_folder:: String,
      output_folder::String,
      obj::String,
      gen_areas = [],
      area_transfer = [],
      plot_results::Bool = true,
      print_results::Bool = false)
      # override_param::Dict{Any}=Dict(),
      # fix_f_override::Bool=false,
      # direct_pq::Bool=true,
      # master_subnet::Int64=1,
      # suffix::String=""
      dir = "$(folder)/"
      #file_name = "$(dir)/RTS_GMLC.m"

      # hour_data: store the data
      hour_data = Dict{Int64, Any}

      # time range
      start_t = DateTime(2020,month_st,day_st,period_st)
      end_t = DateTime(2020,month_en,day_en,period_en)
      range_t = start_t:Hour(1):end_t

      # input the corresponding data of the specific subnetwork
      sub_folder = "$(folder)/enum_net/$(subnet_folder)"
      println("reading the file $(sub_folder)")
      hour_data = hour_parse(month_st, day_st, period_st, month_en, day_en, period_en, sub_folder)

      # s = JSON.json(hour_data)
      # open("test_hour_cost.json", "w") do f
      # write(f, s)
      # end

      # dictionaries store the output of the optimization for each period.
      opt_net = Dict()
      res_summary_dict = Dict()
      solution_pm_dict = Dict()
      hour_mn_data = Dict()
      objective_val = Dict()

      # output binding constraints
      binding_constraints = Dict()

      # manually used enumerate_branch to make data of subnetworks from RTS_GMLC.m before
      # running the make_mn_data function
      for i in 1:size(range_t, 1)
            #for j in 1:119
                  #subnetwork_file = "$(dir)/enum_nets/br$(j)/subnetworks.csv"
                  #interface_file = "$(dir)/enum_nets/br$(j)/interfaces.csv"
                  subnetwork_file = "$(dir)/enum_net/$(subnet_folder)/subnetworks.csv"
                  interface_file = "$(dir)/enum_net/$(subnet_folder)/interfaces.csv"
                  subnetworks = DataFrame(index=Int64[], file=String[], variable_f=Bool[],
                                          f_base=Float64[], f_min=Float64[], f_max=Float64[])
                  interfaces = DataFrame(index=Int64[], subnet_index=Int64[], bus=Int64[],
                                         s_max=Float64[], p_max=Float64[], q_max=Float64[],
                                         loss_param=Float64[])

                  # files ready for input to make_mn_data
                  subnetworks = CSV.read(subnetwork_file, DataFrame)
                  interfaces = CSV.read(interface_file, DataFrame)
                  hour_mn_data[i] = VariableFrequencyOPF.make_mn_data(subnetworks, interfaces, hour_data[i])

                  (opt_net[i], res_summary_dict[i], solution_pm_dict[i]) =
                  VariableFrequencyOPF.multifrequency_opf(hour_mn_data[i], output_folder, obj, gen_areas, area_transfer, print_results)
                  # open("test_mn_cost_$(i).json", "w") do f
                  #  write(f, s1)
                  # end

                  # write the binding constriants to a new file (save binding constraints of each case individually)
                  binding_constraints_part = Dict()
                  open("$(output_folder)/binding_constraints.json", "r") do f
                        global binding_constraints_part
                        #bind = read(f, String)
                        binding_constraints_part = JSON.parse(f)
                        binding_constraints[i] = binding_constraints_part
                  end
                  #binding_constraints_json = JSON.json(binding_constraints)


            #end
      end

      # save files of outputs
      binding_constraints_json = JSON.json(binding_constraints)
      open("$(output_folder)/binding_constraints$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f1
            write(f1, binding_constraints_json)
      end

      opt_net_string = JSON.json(opt_net)
      open("$(output_folder)/opt_net_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, opt_net_string)
      end

      res_summary_string = JSON.json(res_summary_dict)
      open("$(output_folder)/res_summary_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, res_summary_string)
      end

      # solution_pm_string = JSON.json(solution_pm_dict)
      # open("$(output_folder)/solution_pm_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
      #   write(f, solution_pm_string)
      # end

      # plot of the results (optional, now we mostly use the function of multi_plot)
      # if plot_results == true
      #       objval = Array{Float64, 1}()
      #       objval_n = Array{Float64, 1}()
      #       size_obj = Array{DateTime, 1}()
      #       size_obj_n = Array{DateTime, 1}()
      #       for i in 1:size(range_t, 1)
      #             if res_summary_dict[i].status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
      #                   push!(objval, res_summary_dict[i]["objective"][1])
      #                   push!(size_obj, range_t[i])
      #             else
      #                   push!(objval_n, res_summary_dict[i]["objective"][1])
      #                   push!(size_obj_n, range_t[i])
      #             end
      #       end
      #       #size_obj_n = size(range_t, 1) - size_obj
      #       # below are the parts of plotting
      #       println(range_t)
      #       println(objval)
      #       gr()
      #       p = plot(size_obj, objval,  color = :blue, seriestype = :line, title = "optimal result plot",
      #                xlabel = "time/h", ylabel = "optimal $(obj)", right_margin = 10px)
      #       plot!(size_obj_n, objval_n, color = :red, seriestype = :scatter)
      #       # seriestype = :histogram
      #       #savefig(fn)
      #       #savefig(p, )
      #
      #       # save output plot file
      #       savefig(p, "$(output_folder)/opt_res_plot_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")
      # end

      return opt_net, res_summary_dict, solution_pm_dict
end

function hour_opf_regularized(month_st, day_st, period_st, month_en, day_en, period_en,
      folder:: String,
      subnet_folder:: String,
      output_folder::String,
      obj::String;
      gen_areas = [],
      area_transfer = [],
      gen_zones = [],
      zone_transfer = [],
      plot_results::Bool = true,
      print_results::Bool = false,
      regularize_f::Float64=0.0,
      ipopt_max_iter::Int64=20000
      )
      # override_param::Dict{Any}=Dict(),
      # fix_f_override::Bool=false,
      # direct_pq::Bool=true,
      # master_subnet::Int64=1,
      # suffix::String=""
      dir = "$(folder)/"
      #file_name = "$(dir)/RTS_GMLC.m"

      # hour_data: store the data
      hour_data = Dict{Int64, Any}

      if !isdir(output_folder)
            mkpath(output_folder)
      end
      # time range
      start_t = DateTime(2020,month_st,day_st,period_st)
      end_t = DateTime(2020,month_en,day_en,period_en)
      range_t = start_t:Hour(1):end_t

      # input the corresponding data of the specific subnetwork
      # sub_folder = "$(folder)/enum_net_new/$(subnet_folder)"
      sub_folder = subnet_folder
      println("reading the file $(sub_folder)")
      hour_data = hour_parse(month_st, day_st, period_st, month_en, day_en, period_en, sub_folder)

      # s = JSON.json(hour_data)
      # open("test_hour_cost.json", "w") do f
      # write(f, s)
      # end

      # dictionaries store the output of the optimization for each period.
      opt_net = Dict()
      res_summary_dict = Dict()
      solution_pm_dict = Dict()
      hour_mn_data = Dict()
      objective_val = Dict()

      # output binding constraints
      binding_constraints = Dict()

      # manually used enumerate_branch to make data of subnetworks from RTS_GMLC.m before
      # running the make_mn_data function
      for i in 1:size(range_t, 1)
            #for j in 1:119
                  #subnetwork_file = "$(dir)/enum_nets/br$(j)/subnetworks.csv"
                  #interface_file = "$(dir)/enum_nets/br$(j)/interfaces.csv"
                  # subnetwork_file = "$(dir)/enum_net_new/$(subnet_folder)/subnetworks.csv"
                  # interface_file = "$(dir)/enum_net_new/$(subnet_folder)/interfaces.csv"
                  subnetwork_file = "$(subnet_folder)/subnetworks.csv"
                  interface_file = "$(subnet_folder)/interfaces.csv"
                  subnetworks = DataFrame(index=Int64[], file=String[], variable_f=Bool[],
                                          f_base=Float64[], f_min=Float64[], f_max=Float64[])
                  interfaces = DataFrame(index=Int64[], subnet_index=Int64[], bus=Int64[],
                                         s_max=Float64[], p_max=Float64[], q_max=Float64[],
                                         loss_param=Float64[])

                  # files ready for input to make_mn_data
                  subnetworks = CSV.read(subnetwork_file, DataFrame)
                  interfaces = CSV.read(interface_file, DataFrame)
                  hour_mn_data[i] = VariableFrequencyOPF.make_mn_data(subnetworks, interfaces, hour_data[i])

                  override_param=Dict()
                  fix_f_override=false
                  direct_pq=true
                  master_subnet=1
                  start_vals=Dict{String, Dict}("sn"=>Dict())
                  uniform_gen_scaling=false
                  unbounded_pg=false
                  output_to_files=true
                  # regularize_f=regularize_f
                  # ipopt_max_iter = ipopt_max_iter

                  (opt_net[i], res_summary_dict[i], solution_pm_dict[i]) =
                  VariableFrequencyOPF.multifrequency_opf(
                        hour_mn_data[i],
                        output_folder,
                        obj,
                        gen_areas,
                        area_transfer,
                        gen_zones,
                        zone_transfer,
                        print_results,
                        override_param,
                        fix_f_override,
                        direct_pq,
                        master_subnet,
                        start_vals,
                        uniform_gen_scaling,
                        unbounded_pg,
                        output_to_files,
                        regularize_f = regularize_f,
                        ipopt_max_iter = ipopt_max_iter
                        )
                  # open("test_mn_cost_$(i).json", "w") do f
                  #  write(f, s1)
                  # end

                  # write the binding constriants to a new file (save binding constraints of each case individually)
                  binding_constraints_part = Dict()
                  open("$(output_folder)/binding_constraints.json", "r") do f
                        global binding_constraints_part
                        #bind = read(f, String)
                        binding_constraints_part = JSON.parse(f)
                        binding_constraints[i] = binding_constraints_part
                  end
                  #binding_constraints_json = JSON.json(binding_constraints)


            #end
      end

      # save files of outputs
      if !isdir("$(output_folder)/binding_constraints/$(subnet_folder)")
            mkpath("$(output_folder)/binding_constraints/$(subnet_folder)")
      end
      binding_constraints_json = JSON.json(binding_constraints)
      open("$(output_folder)/binding_constraints/$(subnet_folder)/($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f1
            write(f1, binding_constraints_json)
      end
      if !isdir("$(output_folder)/opt_net/$(subnet_folder)")
            mkpath("$(output_folder)/opt_net/$(subnet_folder)")
      end
      opt_net_string = JSON.json(opt_net)
      open("$(output_folder)/opt_net/$(subnet_folder)/($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, opt_net_string)
      end
      if !isdir("$(output_folder)/res_summary/$(subnet_folder)")
            mkpath("$(output_folder)/res_summary/$(subnet_folder)")
      end
      res_summary_string = JSON.json(res_summary_dict)
      open("$(output_folder)/res_summary/$(subnet_folder)/($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, res_summary_string)
      end

      return opt_net, res_summary_dict, solution_pm_dict
end

function hour_opf_modified(month_st, day_st, period_st, month_en, day_en, period_en,
      folder:: String,
      subnet_folder:: String,
      output_folder::String,
      obj::String,
      gen_areas = [],
      area_transfer = [],
      plot_results::Bool = true,
      print_results::Bool = false)
      # override_param::Dict{Any}=Dict(),
      # fix_f_override::Bool=false,
      # direct_pq::Bool=true,
      # master_subnet::Int64=1,
      # suffix::String=""
      dir = "$(folder)/"
      #file_name = "$(dir)/RTS_GMLC.m"

      # hour_data: store the data
      hour_data = Dict{Int64, Any}

      # time range
      start_t = DateTime(2020,month_st,day_st,period_st)
      end_t = DateTime(2020,month_en,day_en,period_en)
      range_t = start_t:Hour(1):end_t

      # input the corresponding data of the specific subnetwork
      sub_folder = "$(folder)/enum_net_new/$(subnet_folder)"
      println("reading the file $(sub_folder)")
      hour_data = hour_parse(month_st, day_st, period_st, month_en, day_en, period_en, sub_folder)

      # s = JSON.json(hour_data)
      # open("test_hour_cost.json", "w") do f
      # write(f, s)
      # end

      # dictionaries store the output of the optimization for each period.
      opt_net = Dict()
      res_summary_dict = Dict()
      solution_pm_dict = Dict()
      hour_mn_data = Dict()
      objective_val = Dict()

      # output binding constraints
      binding_constraints = Dict()

      # manually used enumerate_branch to make data of subnetworks from RTS_GMLC.m before
      # running the make_mn_data function
      for i in 1:size(range_t, 1)
            #for j in 1:119
                  #subnetwork_file = "$(dir)/enum_nets/br$(j)/subnetworks.csv"
                  #interface_file = "$(dir)/enum_nets/br$(j)/interfaces.csv"
                  subnetwork_file = "$(dir)/enum_net_new/$(subnet_folder)/subnetworks.csv"
                  interface_file = "$(dir)/enum_net_new/$(subnet_folder)/interfaces.csv"
                  subnetworks = DataFrame(index=Int64[], file=String[], variable_f=Bool[],
                                          f_base=Float64[], f_min=Float64[], f_max=Float64[])
                  interfaces = DataFrame(index=Int64[], subnet_index=Int64[], bus=Int64[],
                                         s_max=Float64[], p_max=Float64[], q_max=Float64[],
                                         loss_param=Float64[])

                  # files ready for input to make_mn_data
                  subnetworks = CSV.read(subnetwork_file, DataFrame)
                  interfaces = CSV.read(interface_file, DataFrame)
                  hour_mn_data[i] = VariableFrequencyOPF.make_mn_data(subnetworks, interfaces, hour_data[i])

                  (opt_net[i], res_summary_dict[i], solution_pm_dict[i]) =
                  VariableFrequencyOPF.multifrequency_opf(hour_mn_data[i], output_folder, obj, gen_areas, area_transfer, print_results)
                  # open("test_mn_cost_$(i).json", "w") do f
                  #  write(f, s1)
                  # end

                  # write the binding constriants to a new file (save binding constraints of each case individually)
                  binding_constraints_part = Dict()
                  open("$(output_folder)/binding_constraints.json", "r") do f
                        global binding_constraints_part
                        #bind = read(f, String)
                        binding_constraints_part = JSON.parse(f)
                        binding_constraints[i] = binding_constraints_part
                  end
                  #binding_constraints_json = JSON.json(binding_constraints)


            #end
      end

      # save files of outputs
      binding_constraints_json = JSON.json(binding_constraints)
      open("$(output_folder)/binding_constraints$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f1
            write(f1, binding_constraints_json)
      end

      opt_net_string = JSON.json(opt_net)
      open("$(output_folder)/opt_net_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, opt_net_string)
      end

      res_summary_string = JSON.json(res_summary_dict)
      open("$(output_folder)/res_summary_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, res_summary_string)
      end

      # solution_pm_string = JSON.json(solution_pm_dict)
      # open("$(output_folder)/solution_pm_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
      #   write(f, solution_pm_string)
      # end

      # plot of the results (optional, now we mostly use the function of multi_plot)
      # if plot_results == true
      #       objval = Array{Float64, 1}()
      #       objval_n = Array{Float64, 1}()
      #       size_obj = Array{DateTime, 1}()
      #       size_obj_n = Array{DateTime, 1}()
      #       for i in 1:size(range_t, 1)
      #             if res_summary_dict[i].status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
      #                   push!(objval, res_summary_dict[i]["objective"][1])
      #                   push!(size_obj, range_t[i])
      #             else
      #                   push!(objval_n, res_summary_dict[i]["objective"][1])
      #                   push!(size_obj_n, range_t[i])
      #             end
      #       end
      #       #size_obj_n = size(range_t, 1) - size_obj
      #       # below are the parts of plotting
      #       println(range_t)
      #       println(objval)
      #       gr()
      #       p = plot(size_obj, objval,  color = :blue, seriestype = :line, title = "optimal result plot",
      #                xlabel = "time/h", ylabel = "optimal $(obj)", right_margin = 10px)
      #       plot!(size_obj_n, objval_n, color = :red, seriestype = :scatter)
      #       # seriestype = :histogram
      #       #savefig(fn)
      #       #savefig(p, )
      #
      #       # save output plot file
      #       savefig(p, "$(output_folder)/opt_res_plot_$(subnet_folder)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")
      # end

      return opt_net, res_summary_dict, solution_pm_dict
end
