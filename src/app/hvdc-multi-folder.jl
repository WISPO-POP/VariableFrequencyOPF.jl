
function hvdc_comparison(
      parent_folder::String,
      output_folder::String,
      objective::String;
      k_cond=[],
      k_ins=[],
      dc_subnet::Int64=-1,
      gen_areas::Array=[],
      area_transfer::Array=[],
      gen_zones::Array=[],
      zone_transfer::Array=[],
      enum_branches::Bool=false,
      plot_best_x::Int64=-1,
      print_results::Bool=false,
      series_labels::Array=[],
      results_folders::Array=[],
      scopf::Bool=false,
      no_converter_loss::Bool=false,
      output_to_files::Bool=true
   )
   if (length(k_cond)) > 0 && (length(k_ins) > 0)
      if scopf
         dc_params = ([["sn",contingency,"sn",dc_subnet,"k_ins"],["sn",contingency,"sn",dc_subnet,"k_cond"],["sn",contingency,"sn",dc_subnet,"f_max"]],[k_ins, k_cond, zeros(length(k_ins))])
      else
         dc_params = ([["sn",dc_subnet,"k_ins"],["sn",dc_subnet,"k_cond"],["sn",dc_subnet,"f_max"]],[k_ins, k_cond, zeros(length(k_ins))])
      end
   else
      dc_params = ()
   end
   num_series = 0
   if length(dc_params) > 0
      if length(dc_params[1]) > 0
         num_series = length(dc_params[2][1])
      end
   end
   println("num_series: $num_series")
   println("dc_params: $dc_params")
   # Run the opf for the base case then all dc configurations
   results_dict_allplots = []
   n_subnets = 0
   subnet_array = []
   idx_sorted = []
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
         suffix=series_labels[1],
         no_converter_loss=no_converter_loss,
         output_to_files=output_to_files
      )
      push!(results_dict_allplots, results_dict)

      results_dict_string = JSON.json(results_dict)
      println("Saving results at $(series_output_folder)/all_results_dict.json")
      open("$series_output_folder/all_results_dict.json", "w") do f
         write(f, results_dict_string)
      end
      push!(results_folders, series_output_folder)

      # Iterate through the parameter collections in order
      for param_i in 1:num_series
         override_param = Dict{Any, Any}()
         for (val_idx,value) in enumerate(dc_params[2])
            set_nested!(override_param, string.(dc_params[1][val_idx]), value[param_i])
         end
         (results_dict,n_subnets_dc,subnet_array_dc,idx_sorted_dc,series_output_folder,plot_best_x) = run_series(
            parent_folder,
            objective;
            gen_areas,
            area_transfer,
            gen_zones,
            zone_transfer,
            enum_branches,
            plot_best_x,
            print_results,
            override_param=override_param,
            suffix=series_labels[1+param_i],
            no_converter_loss=no_converter_loss,
            output_to_files=output_to_files
         )
         push!(results_dict_allplots, results_dict)

         results_dict_string = JSON.json(results_dict)
         println("Saving results at $(series_output_folder)/all_results_dict.json")
         open("$series_output_folder/all_results_dict.json", "w") do f
            write(f, results_dict_string)
         end
         push!(results_folders, series_output_folder)
      end
      println("results_folders: $results_folders")
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
      println("Saving results at $(output_folder)/results_dict_allplots.json")
      results_dict_string = JSON.json(results_dict_allplots)
      if !isdir(output_folder)
         mkpath(output_folder)
      end
      open("$(output_folder)/results_dict_allplots.json", "w") do f
         write(f, results_dict_string)
      end
   end
   plot_results_dicts_bar(results_dict_allplots,n_subnets,subnet_array,idx_sorted,output_folder,plot_best_x,series_labels)

end
