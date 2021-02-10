
function mt_net_comparison(
      parent_folder::String,
      output_folder::String,
      objective::String;
      gen_areas::Array=[],
      area_transfer::Array=[],
      gen_zones::Array=[],
      zone_transfer::Array=[],
      enum_branches::Bool=false,
      plot_best_x::Int64=-1,
      print_results::Bool=false,
      results_folders::Array=[],
      scopf::Bool=false,
      no_converter_loss::Bool=false
   )

   # Run the opf for the base case then all dc configurations
   results_dict_allplots = []
   n_subnets = 0
   subnet_array = []
   idx_sorted = []
   series_labels = ["control P, Q, X(ω)"]
   if length(results_folders) == 0
      # Base case opf
      (results_dict,n_subnets,subnet_array,idx_sorted,series_output_folder,plot_best_x) = run_series(
         parent_folder,
         objective;
         gen_areas,
         area_transfer,
         gen_zones,
         zone_transfer,
         enum_branches,
         plot_best_x,
         print_results,
         suffix="",
         no_converter_loss=no_converter_loss
      )
      push!(results_dict_allplots, results_dict)

      results_dict_string = JSON.json(results_dict)
      println("Saving results at $(series_output_folder)/all_results_dict.json")
      open("$series_output_folder/all_results_dict.json", "w") do f
         write(f, results_dict_string)
      end
      push!(results_folders, series_output_folder)
   else
      # Use results data that has already been saved
      results_dict_allplots = []
      for (i,output_folder) in enumerate(results_folders)

         results_dict_parsed = JSON.parsefile("$(output_folder)/all_results_dict.json")
         if i == 1
            (n_subnets, subnet_array, idx_sorted) = get_sort_indices(results_dict_parsed, objective, gen_areas, area_transfer, gen_zones, zone_transfer)
         end

         push!(results_dict_allplots, results_dict_parsed)
      end
   end
   results_dict_string = JSON.json(results_dict_allplots)
   println("Saving results at results_dict_allplots.json")
   open("results_dict_allplots.json", "w") do f
      write(f, results_dict_string)
   end
   plot_results_dicts_bar(results_dict_allplots,n_subnets,subnet_array,idx_sorted,output_folder,plot_best_x,series_labels)

end

function multi_folder(
      parent_folders::Array,
      output_folder::String,
      objective::String;
      gen_areas::Array=[],
      area_transfer::Array=[],
      gen_zones::Array=[],
      zone_transfer::Array=[],
      enum_branches::Bool=false,
      plot_best_x::Int64=-1,
      print_results::Bool=false,
      series_labels::Array=[]
   )

   results_dict_allplots = []
   n_subnets = 0
   subnet_array = []
   idx_sorted = []
   for (i,parent_folder) in enumerate(parent_folders)
      (results_dict,n_subnets,subnet_array,idx_sorted,series_output_folder,plot_best_x) = run_series(
         parent_folder,
         objective;
         gen_areas,
         area_transfer,
         gen_zones,
         zone_transfer,
         enum_branches,
         plot_best_x,
         print_results
      )
      push!(results_dict_allplots, results_dict)

      results_dict_string = JSON.json(results_dict)
      println("Saving results at $(series_output_folder)/all_results_dict.json")
      open("$series_output_folder/all_results_dict.json", "w") do f
         write(f, results_dict_string)
      end
   end

   results_dict_allplots = []
   for (i,parent_folder) in enumerate(parent_folders)
      folder_split = split(rstrip(parent_folder,'/'),"/")
      folder_split = folder_split[folder_split .!= ""]
      toplevels = folder_split[1:end-2]
      output_folder = join([("$i/") for i in toplevels])*"results/$(folder_split[end])"

      results_dict_parsed = JSON.parsefile("$(output_folder)/all_results_dict.json")

      if i==1
         (n_subnets, subnet_array, idx_sorted) = get_sort_indices(results_dict_parsed, objective, gen_areas, area_transfer, gen_zones, zone_transfer)
      end

      push!(results_dict_allplots, results_dict_parsed)
   end

   plot_results_dicts_bar(results_dict_allplots,n_subnets,subnet_array,idx_sorted,output_folder,plot_best_x,series_labels)
end

function run_series(
      parent_folder::String,
      objective::String;
      gen_areas::Array=[],
      area_transfer::Array=[],
      gen_zones::Array=[],
      zone_transfer::Array=[],
      enum_branches::Bool=false,
      plot_best_x::Int64=-1,
      print_results::Bool=false,
      override_param::Dict=Dict(),
      suffix::String="",
      fix_f_override::Bool=false,
      direct_pq::Bool=true,
      master_subnet::Int64=1,
      no_converter_loss::Bool=false
   )
   folders = [f for f in readdir(parent_folder) if (isdir("$parent_folder/$f"))]

   results_dict = Dict{String, Dict{String, Any}}()

   summary_df = DataFrame()
   folder_split = split(rstrip(parent_folder,'/'),"/")
   folder_split = folder_split[folder_split .!= ""]
   toplevels = folder_split[1:end-2]
   output_folder = join([("$i/") for i in toplevels])*"results/$(folder_split[end])$suffix"
   # output_folder = join([(i=="data" ? "results/" : "$i/") for i in split(parent_folder,"/")])
   println("output location: $output_folder")
   if !isdir(output_folder)
      mkpath(output_folder)
   end
   start_vals = Dict{String, Dict}("nw"=>Dict())
   subnet_array = []
   n_subnets = 0

   # Choose which label to use for sorting all the results
   if objective == "mincost"
      first_label = "cost (USD)"
   elseif objective == "areagen"
      n_areas = length(gen_areas)
      if n_areas > 1
         gen_areas_sorted = sort(gen_areas)
         first_label = "generation in areas"
         for i in 1:(n_areas-2)
            first_label *= " $(gen_areas_sorted[i]),"
         end
         first_label *=  " $(gen_areas_sorted[end-1]) and $(gen_areas_sorted[end]) (p.u.)"
      else
         first_label = "generation in areas $(gen_areas[1]) (p.u.)"
      end
   elseif objective == "zonegen"
      n_zones = length(gen_zones)
      if n_zones > 1
         gen_zones_sorted = sort(gen_zones)
         first_label = "generation in zones"
         for i in 1:(n_zones-2)
            first_label *= " $(gen_zones_sorted[i]),"
         end
         first_label *=  " $(gen_zones_sorted[end-1]) and $(gen_zones_sorted[end]) (p.u.)"
      else
         first_label = "generation in zones $(gen_zones[1]) (p.u.)"
      end
   end

   for (i,folder) in enumerate(folders)
      println("running $parent_folder/$(folders[i])  |  $i/$(length(folders)) folders")
      override_param_tmp = deepcopy(override_param)
      (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
         parent_folder, folders[i],
         objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
         fix_f_override,
         direct_pq, master_subnet,
         suffix, print_results,
         override_param=override_param_tmp,
         no_converter_loss=no_converter_loss
      )

      # println("STATUS: $(res_summary_temp.status[1])")
      if !(res_summary_temp.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
         fix_f_init = false

         println("Running OPF again without converter losses.")
         # Now run the opf again without converter losses by applying the noloss_override dictionary
         (result_init, res_summary_init, solution_pm_init, results_dict_init) = run_opf(
            parent_folder, folders[i],
            objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
            fix_f_override,
            direct_pq, master_subnet,
            suffix, print_results,
            override_param=override_param_tmp,
            no_converter_loss=no_converter_loss
         )
         if (res_summary_init.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED])
            println("Using no-loss solution as initialization, running OPF again with converter losses.")
            # Run the opf again with converter losses and variable frequency, now using the solution from the no-loss case as initialization
            (result_temp, res_summary_temp, solution_pm_temp, results_dict_temp) = run_opf(
               parent_folder, folders[i],
               objective, gen_areas, area_transfer, gen_zones, zone_transfer, results_dict,
               fix_f_override,
               direct_pq, master_subnet,
               suffix, print_results,
               override_param=override_param_tmp,
               start_vals=solution_pm_init,
               no_converter_loss=no_converter_loss
            )
         end
      end
      result = result_temp
      res_summary = res_summary_temp
      solution_pm = solution_pm_temp
      results_dict = results_dict_temp

      res_summary[:,:network] .= rstrip(folders[i],'/')*suffix
      if i == 1
         summary_df = res_summary
      else
         summary_df = vcat(summary_df, res_summary)
      end

   end
   label = first_label
   results = results_dict[label]

   br_results = Array{Float64,1}()
   br_indices = Array{String,1}()
   base_res = NaN

   for (folder,res) in results
      # if results_dict["status"][folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
         subnet_array = union(subnet_array, results_dict["subnet"][folder]) # Get maximal set with subnets represented in any folders
         if occursin("br", folder)
            push!(br_results, sum(res))
            push!(br_indices, folder)
         elseif occursin("base", folder)
            base_res = res
            println("set base_res to $base_res")
         end
      # else
      #    subnet_array = union(subnet_array, results_dict["subnet"][folder]) # Get maximal set with subnets represented in any folders
      #    if occursin("br", folder)
      #       if occursin("_fixf", folder)
      #          push!(br_results_fixf, -9999.0)
      #          push!(br_indices_fixf, folder[3:(end-5)])
      #       elseif occursin("_indirPQ", folder)
      #          push!(br_results_indirPQ, -9999.0)
      #          push!(br_indices_indirPQ, folder[3:(end-8)])
      #       else
      #          push!(br_results, -9999.0)
      #          push!(br_indices, folder[3:end])
      #       end
      #    # elseif folder == "base"
      #    #    base_res = -9999.0
      #    elseif folder == "base_unconstrPS"
      #       base_res = -9999.0
      #    end
      # end
   end

   br_results_tosort = copy(br_results)
   br_results_tosort[isnan.(br_results_tosort) .& (br_results_tosort.==-9999.0)] .= Inf
   perm = sortperm(br_results_tosort)
   idx_sorted = br_indices[perm]

   results_dict_string = JSON.json(results_dict)
   println("Saving results at $(output_folder)/all_results_dict.json")
   open("$output_folder/all_results_dict.json", "w") do f
      write(f, results_dict_string)
   end

   println("Saving summary at $(output_folder)/summary.csv")
   CSV.write("$(output_folder)/summary.csv", summary_df)

   n_subnets = length(subnet_array)

   return results_dict, n_subnets, subnet_array, idx_sorted, output_folder, plot_best_x


end


function get_sort_indices(results_dict, objective, gen_areas::Array, area_transfer::Array, gen_zones::Array, zone_transfer::Array)
   # Choose which label to use for sorting all the results
   if objective == "mincost"
      first_label = "cost (USD)"
   elseif objective == "areagen"
      n_areas = length(gen_areas)
      if n_areas > 1
         gen_areas_sorted = sort(gen_areas)
         first_label = "generation in areas"
         for i in 1:(n_areas-2)
            first_label *= " $(gen_areas_sorted[i]),"
         end
         first_label *=  " $(gen_areas_sorted[end-1]) and $(gen_areas_sorted[end]) (p.u.)"
      else
         first_label = "generation in areas $(gen_areas[1]) (p.u.)"
      end
   elseif objective == "zonegen"
      n_zones = length(gen_zones)
      if n_zones > 1
         gen_zones_sorted = sort(gen_zones)
         first_label = "generation in zones"
         for i in 1:(n_zones-2)
            first_label *= " $(gen_zones_sorted[i]),"
         end
         first_label *=  " $(gen_zones_sorted[end-1]) and $(gen_zones_sorted[end]) (p.u.)"
      else
         first_label = "generation in zones $(gen_zones[1]) (p.u.)"
      end
   end

   label = first_label
   results = results_dict[label]

   br_results = Array{Float64,1}()
   br_indices = Array{String,1}()
   base_res = NaN

   subnet_array = []
   for (folder,res) in results
      # if results_dict["status"][folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
         subnet_array = union(subnet_array, results_dict["subnet"][folder]) # Get maximal set with subnets represented in any folders
         if occursin("br", folder)
            push!(br_results, sum(res))
            push!(br_indices, folder)
         elseif occursin("base", folder)
            base_res = res
            println("set base_res to $base_res")
         end
      # end
   end

   br_results_tosort = copy(br_results)
   br_results_tosort[br_results_tosort.==-9999.0] .= Inf
   perm = sortperm(br_results_tosort)
   idx_sorted = br_indices[perm]

   n_subnets = length(subnet_array)

   return n_subnets, subnet_array, idx_sorted
end
