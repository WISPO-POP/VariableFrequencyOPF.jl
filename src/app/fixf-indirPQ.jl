
"""
   run_subnets(
      parent_folder::String,
      objective::String;
      gen_areas::Array=[],
      area_transfer::Array=[],
      gen_zones::Array=[],
      zone_transfer::Array=[],
      enum_branches::Bool=false,
      plot_best_x::Int64=-1,
      scopf::Bool=false,
      ctg_plots::Array{Int64,1}=[0],
      run_fix_f::Bool=false,
      run_indir_PQ::Bool=false,
      print_results::Bool=false
   )

Models and solves an OPF for every network in a directory.

# Arguments
- `parent_folder::String`: a directory containing full network data for one or more networks, each in a folder containing all subnetwork data, *subnetworks.csv*, and *interfaces.csv*
- `obj::String`: the objective function to use, from the following:
   - "mincost": minimize generation cost
   - "areagen": minimize generation in the areas specified in `gen_areas`
   - "zonegen": minimize generation in the zones specified in `gen_zones`
   - "minredispatch": minimize the change in generator dispatch from the initial values defined in the network data
- `gen_areas::Array{Int64,1}`: all areas in which generation should be minimized if `obj=="areagen"`
- `area_transfer::Array{Int64,1}`: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.
- `gen_zones::Array{Int64,1}`: all zones in which generation should be minimized if `obj=="zonegen"`
- `zone_transfer::Array{Int64,1}`: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.
- `enum_branches::Bool`: if true, collect results from each folder for plotting bar graphs. This is used when the possible branch upgrades have been enumerated and a comparison is desired. Default false.
- `plot_best_x::Int64`: number of results to plot, sorted from smallest to largest objective. If `plot_best_x` <= 1, the results of all networks which gave feasible solutions are plotted. Default -1.
- `scopf::Bool`: if true, model and solve the N-1 security constrained OPF for each network. Each network folder must contain a contingency specification file (_*.con_) for each subnetwork. Default false.
- `ctg_plots::Array{Int64,1}`: indices of the contingencies to plot. The base case index is 0. Default [0].
"""
function run_subnets(
   parent_folder::String,
   objective::String;
   gen_areas::Array=[],
   area_transfer::Array=[],
   gen_zones::Array=[],
   zone_transfer::Array=[],
   enum_branches::Bool=false,
   plot_best_x::Int64=-1,
   scopf::Bool=false,
   ctg_plots::Array{Int64,1}=[0],
   run_fix_f::Bool=false,
   run_indir_PQ::Bool=false,
   print_results::Bool=false
   )
   folders = [f for f in readdir(parent_folder) if (isdir("$parent_folder/$f"))]
   if scopf
      results_dict = Dict{Int64, Dict{String, Dict{String, Any}}}()
   else
      results_dict = Dict{String, Dict{String, Any}}()
   end
   summary_df = DataFrame()
   folder_split = split(rstrip(parent_folder,'/'),"/")
   folder_split = folder_split[folder_split .!= ""]
   toplevels = folder_split[1:end-2]
   output_folder = join([("$i/") for i in toplevels])*"results/$(folder_split[end])"
   # output_folder = join([(i=="data" ? "results/" : "$i/") for i in split(parent_folder,"/")])
   println("output location: $output_folder")
   if !isdir(output_folder)
      mkpath(output_folder)
   end
   start_vals = Dict{String, Dict}("nw"=>Dict())
   if scopf
      for i in 1:length(folders)
         println("running $parent_folder/$(folders[i])  |  $i/$(length(folders)) folders")
         # full PQ case
         ctg_f_redispatch=false
         ctg_gen_redispatch=false
         ctg_iface_redispatch=true
         fix_post_ctg_pq=false
         direct_pq=true
         master_subnet=1
         suffix=""
         (result, summary_dict, solution_pm) = run_scopf(
            parent_folder,folders[i],
            objective, gen_areas, area_transfer, start_vals, results_dict,
            ctg_f_redispatch,
            ctg_gen_redispatch,
            ctg_iface_redispatch,
            fix_post_ctg_pq,
            direct_pq,
            master_subnet,
            suffix
         )
         if i==1
            start_vals = Dict("nw"=>Dict("0"=>solution_pm["nw"]["0"]))
         end
         res_summary = summary_dict[0]
         res_summary.network = rstrip(folders[i],'/')*suffix
         if i == 1
            summary_df = res_summary
         else
            summary_df = vcat(summary_df, res_summary)
         end

         # fixed post-contingency PQ
         ctg_f_redispatch=false
         ctg_gen_redispatch=false
         ctg_iface_redispatch=false
         fix_post_ctg_pq=true
         direct_pq=true
         master_subnet=1
         suffix="_fixf"
         (result, summary_dict, solution_pm) = run_scopf(
            parent_folder,folders[i],
            objective, gen_areas, area_transfer, start_vals, results_dict,
            ctg_f_redispatch,
            ctg_gen_redispatch,
            ctg_iface_redispatch,
            fix_post_ctg_pq,
            direct_pq,
            master_subnet,
            suffix
         )
         if i==1
            start_vals = Dict("nw"=>Dict("0"=>solution_pm["nw"]["0"]))
         end
         res_summary = summary_dict[0]
         res_summary.network = rstrip(folders[i],'/')*suffix
         if i == 1
            summary_df = res_summary
         else
            summary_df = vcat(summary_df, res_summary)
         end

         # passive post-contingency PQ
         # ctg_f_redispatch=false
         # ctg_gen_redispatch=false
         # ctg_iface_redispatch=false
         # fix_post_ctg_pq=false
         # direct_pq=true
         # master_subnet=1
         # suffix="_indirPQ"
         # (result, summary_dict, solution_pm) = run_scopf(
         #    parent_folder,folders[i],
         #    objective, gen_areas, area_transfer, start_vals, results_dict,
         #    ctg_f_redispatch,
         #    ctg_gen_redispatch,
         #    ctg_iface_redispatch,
         #    fix_post_ctg_pq,
         #    direct_pq,
         #    master_subnet,
         #    suffix
         # )
         # if i==1
         #    start_vals = Dict("nw"=>Dict("0"=>solution_pm["nw"]["0"]))
         # end
         # res_summary = summary_dict[0]
         # res_summary.network = rstrip(folders[i],'/')*suffix
         # if i == 1
         #    summary_df = res_summary
         # else
         #    summary_df = vcat(summary_df, res_summary)
         # end
      end
   else # if not scopf
      for i in 1:length(folders)
         println("running $parent_folder/$(folders[i])  |  $i/$(length(folders)) folders")
         # standard case
         fix_f_override=false
         direct_pq=true
         master_subnet=1
         suffix=""
         (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
            parent_folder, folders[i],
            objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
            fix_f_override,
            direct_pq, master_subnet,
            suffix, print_results
         )

         if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
            fix_f_init = false
            noloss_override = create_noloss_dict(solution_pm_temp)

            println("Running OPF again without converter losses.")
            # Now run the opf again without converter losses by applying the noloss_override dictionary
            (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
               parent_folder, folders[i],
               objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
               fix_f_override,
               direct_pq, master_subnet,
               suffix, print_results,
               override_param=noloss_override
            )
            if !(res_summary_init.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
               (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
                  parent_folder, folders[i],
                  objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                  true,
                  true, 1,
                  suffix, print_results
               )
               fix_f_init = true
               println("Using fixed frequency solution as initialization, running OPF again.")
            else
               println("Using no-loss solution as initialization, running OPF again with converter losses.")
            end
            # Run the opf again with converter losses and variable frequency, now using the solution from the no-loss or fixed frequency case as initialization

            (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
               parent_folder, folders[i],
               objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
               fix_f_override,
               direct_pq, master_subnet,
               suffix, print_results,
               start_vals=solution_pm_init
            )

            if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]) && !fix_f_init
               println("Running OPF with fixed frequency for initialization.")
               (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
                  parent_folder, folders[i],
                  objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                  true,
                  true, 1,
                  suffix, print_results
               )
               fix_f_init = true
               println("Using fixed frequency solution as initialization, running OPF again.")
               # Run the opf again with converter losses and variable frequency, now using the solution from the no-loss or fixed frequency case as initialization
               (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
                  parent_folder, folders[i],
                  objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                  fix_f_override,
                  direct_pq, master_subnet,
                  suffix, print_results,
                  start_vals=solution_pm_init
               )
               if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]) && (res_summary_init.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
                  # use fixed frequency solution if it is feasible and the variable frequency solution is not
                  result_temp = result_init
                  res_summary_temp = res_summary_init
                  solution_pm_temp = solution_pm_init
                  results_dict_temp = results_dict_init
               end
            end
         end
         result = result_temp
         res_summary = res_summary_temp
         solution_pm = solution_pm_temp
         results_dict = results_dict_temp

         res_summary.network = rstrip(folders[i],'/')*suffix
         if i == 1
            summary_df = res_summary
         else
            summary_df = vcat(summary_df, res_summary)
         end

         if run_fix_f
            # fixed frequency case
            fix_f_override=true
            direct_pq=true
            master_subnet=1
            suffix="_fixf"
            (result, res_summary, solution_pm, results_dict) = run_opf(
               parent_folder, folders[i],
               objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
               fix_f_override,
               direct_pq, master_subnet,
               suffix, print_results
            )
            res_summary.network = rstrip(folders[i],'/')*suffix
            if i == 1
               summary_df = res_summary
            else
               summary_df = vcat(summary_df, res_summary)
            end
         end

         if run_indir_PQ
            # indirect PQ case
            fix_f_override=false
            direct_pq=false
            master_subnet=1
            suffix="_indirPQ"
            (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
               parent_folder, folders[i],
               objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
               fix_f_override,
               direct_pq, master_subnet,
               suffix, print_results
            )

            if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
               fix_f_init = false
               noloss_override = create_noloss_dict(solution_pm_temp)

               println("Running OPF again without converter losses.")
               # Now run the opf again without converter losses by applying the noloss_override dictionary
               (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
                  parent_folder, folders[i],
                  objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                  fix_f_override,
                  direct_pq, master_subnet,
                  suffix, print_results,
                  override_param=noloss_override
               )
               if !(res_summary_init.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
                  (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
                     parent_folder, folders[i],
                     objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                     true,
                     direct_pq, master_subnet,
                     suffix, print_results
                  )
                  fix_f_init = true
                  println("Using fixed frequency solution as initialization, running OPF again.")
               else
                  println("Using no-loss solution as initialization, running OPF again with converter losses.")
               end
               # Run the opf again with converter losses and variable frequency, now using the solution from the no-loss or fixed frequency case as initialization

               (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
                  parent_folder, folders[i],
                  objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                  fix_f_override,
                  direct_pq, master_subnet,
                  suffix, print_results,
                  start_vals=solution_pm_init
               )

               if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]) && !fix_f_init
                  println("Running OPF with fixed frequency for initialization.")
                  (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
                     parent_folder, folders[i],
                     objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                     true,
                     direct_pq, master_subnet,
                     suffix, print_results
                  )
                  fix_f_init = true
                  println("Using fixed frequency solution as initialization, running OPF again.")
                  # Run the opf again with converter losses and variable frequency, now using the solution from the no-loss or fixed frequency case as initialization
                  (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
                     parent_folder, folders[i],
                     objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
                     fix_f_override,
                     direct_pq, master_subnet,
                     suffix, print_results,
                     start_vals=solution_pm_init
                  )
                  if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]) && (res_summary_init.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
                     # use fixed frequency solution if it is feasible and the variable frequency solution is not
                     result_temp = result_init
                     res_summary_temp = res_summary_init
                     solution_pm_temp = solution_pm_init
                     results_dict_temp = results_dict_init
                  end
               end
            end
            result = result_temp
            res_summary = res_summary_temp
            solution_pm = solution_pm_temp
            results_dict = results_dict_temp

            res_summary.network = rstrip(folders[i],'/')*suffix
            if i == 1
               summary_df = res_summary
            else
               summary_df = vcat(summary_df, res_summary)
            end
         end

      end
   end

   println("Saving summary at $(output_folder)/summary.csv")
   CSV.write("$(output_folder)/summary.csv", summary_df)

   if enum_branches
      if scopf
         for (ctg_idx,ctg_result) in results_dict
            if ctg_idx in ctg_plots
               ctg_out_folder = "$output_folder/ctg$ctg_idx/"
               if !isdir(ctg_out_folder)
                  mkpath(ctg_out_folder)
               end
               collect_subnet_results(ctg_result, objective, gen_areas, ctg_out_folder, plot_best_x)
            end
         end
      else
         collect_subnet_results(results_dict, objective, gen_areas, gen_zones, output_folder, plot_best_x)
      end
   end
end
