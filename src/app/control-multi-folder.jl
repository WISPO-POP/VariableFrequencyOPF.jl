
function control_comparison(
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
      output_to_files::Bool=true
   )

   # Run the opf for the base case then all dc configurations
   results_dict_allplots = []
   n_subnets = 0
   subnet_array = []
   idx_sorted = []
   series_labels = ["control X(ω)","control P, Q","control P, Q, X(ω)"]
   if length(results_folders) == 0
      # Base case opf
      (results_dict,n_subnets,subnet_array,idx_sorted,series_output_folder,plot_best_x) = run_series(
         parent_folder,
         objective;
         gen_areas=gen_areas,
         area_transfer=area_transfer,
         gen_zones=gen_zones,
         zone_transfer=zone_transfer,
         enum_branches=enum_branches,
         plot_best_x=plot_best_x,
         print_results=print_results,
         suffix="",
         output_to_files=output_to_files
      )
      push!(results_dict_allplots, results_dict)

      results_dict_string = JSON.json(results_dict)
      println("Saving results at $(series_output_folder)/all_results_dict.json")
      open("$series_output_folder/all_results_dict.json", "w") do f
         write(f, results_dict_string)
      end
      push!(results_folders, series_output_folder)

      # fixed frequency case
      fix_f_override=true
      direct_pq=true
      master_subnet=1
      suffix="_fixf"
      (results_dict,n_subnets_f,subnet_array_f,idx_sorted_f,series_output_folder,plot_best_x) = run_series(
         parent_folder,
         objective;
         gen_areas=gen_areas,
         area_transfer=area_transfer,
         gen_zones=gen_zones,
         zone_transfer=zone_transfer,
         enum_branches=enum_branches,
         plot_best_x=plot_best_x,
         print_results=print_results,
         suffix=suffix,
         fix_f_override=fix_f_override,
         direct_pq=direct_pq,
         master_subnet=master_subnet,
         output_to_files=output_to_files
      )
      push!(results_dict_allplots, results_dict)

      results_dict_string = JSON.json(results_dict)
      println("Saving results at $(series_output_folder)/all_results_dict.json")
      open("$series_output_folder/all_results_dict.json", "w") do f
         write(f, results_dict_string)
      end
      push!(results_folders, series_output_folder)

      # indirect PQ case
      fix_f_override=false
      direct_pq=false
      master_subnet=1
      suffix="_indirPQ"
      (results_dict,n_subnets_pq,subnet_array_pq,idx_sorted_pq,series_output_folder,plot_best_x) = run_series(
         parent_folder,
         objective;
         gen_areas=gen_areas,
         area_transfer=area_transfer,
         gen_zones=gen_zones,
         zone_transfer=zone_transfer,
         enum_branches=enum_branches,
         plot_best_x=plot_best_x,
         print_results=print_results,
         suffix=suffix,
         fix_f_override=fix_f_override,
         direct_pq=direct_pq,
         master_subnet=master_subnet,
         output_to_files=output_to_files
      )
      push!(results_dict_allplots, results_dict)
      push!(results_folders, series_output_folder)

      if output_to_files
         results_dict_string = JSON.json(results_dict)
         println("Saving results at $(series_output_folder)/all_results_dict.json")
         open("$series_output_folder/all_results_dict.json", "w") do f
            write(f, results_dict_string)
         end
      end
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
   if output_to_files
      println("Saving results at results_dict_allplots.json")
      results_dict_string = JSON.json(results_dict_allplots)
      open("$(output_folder)/results_dict_allplots.json", "w") do f
         write(f, results_dict_string)
      end
   end
   plot_results_dicts_bar(results_dict_allplots,n_subnets,subnet_array,idx_sorted,output_folder,plot_best_x,series_labels,color_palette=:Dark2_8)

end
