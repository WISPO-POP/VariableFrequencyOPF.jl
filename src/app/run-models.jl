
function run_opf(
      parent_folder,
      folder,
      objective,
      gen_areas,
      area_transfer,
      gen_zones,
      zone_transfer,
      results_dict,
      fix_f_override,
      direct_pq,
      master_subnet,
      suffix,
      print_results;
      override_param::Dict=Dict(),
      start_vals=Dict("sn"=>Dict()),
      no_converter_loss::Bool=false,
      regularize_f::Float64=0.0,
      ipopt_max_iter::Int64=10000,
      output_to_files=output_to_files
   )
   (result, res_summary, solution_pm, binding_cnstr) = multifrequency_opf(
      "$parent_folder/$(folder)", objective,
      gen_areas=gen_areas, area_interface=area_transfer,
      gen_zones=gen_zones, zone_interface=zone_transfer,
      print_results=print_results,
      fix_f_override=fix_f_override, direct_pq=direct_pq,
      master_subnet=1, suffix=suffix, override_param=override_param,
      start_vals=start_vals, no_converter_loss=no_converter_loss,
      output_to_files=output_to_files,
      regularize_f=regularize_f,
      ipopt_max_iter=ipopt_max_iter
      )
   results_dict_out = deepcopy(results_dict)
   for (label, value) in result
      # println("label: $label")
      if !(label in keys(results_dict_out))
         results_dict_out[label] = Dict{String, Any}()
      end
      # Comment '|| true' to prevent saving outputs when not solved to optimum
      if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED] || true
         # results_dict_out[label][rstrip(folder,'/')*suffix] = value
         results_dict_out[label][rstrip(folder,'/')] = value
      end
   end
   return (result, res_summary, solution_pm, results_dict_out)
end
