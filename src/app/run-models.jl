
function run_scopf(
      parent_folder, folder, objective, gen_areas, area_transfer,
      start_vals, results_dict,
      ctg_f_redispatch,
      ctg_gen_redispatch,
      ctg_iface_redispatch,
      fix_post_ctg_pq,
      direct_pq,
      master_subnet,
      suffix
   )
   (result, summary_dict, solution_pm) = multifrequency_scopf(
      "$parent_folder/$(folder)", objective, gen_areas, area_transfer,
      false, Dict(), start_vals,
      ctg_f_redispatch,
      ctg_gen_redispatch,
      ctg_iface_redispatch,
      fix_post_ctg_pq,
      direct_pq,
      master_subnet,
      suffix
   )
   res_summary = summary_dict[0]
   for (ctg_idx,ctg_result) in result
      if !(ctg_idx in keys(results_dict))
         results_dict[ctg_idx] = Dict{String, Any}()
      end
      for (label, value) in ctg_result
         # println("label: $label")
         if !(label in keys(results_dict[ctg_idx]))
            results_dict[ctg_idx][label] = Dict{String, Any}()
         end
         # Comment '|| true' to prevent saving outputs when not solved to optimum
         if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED] || true
            results_dict[ctg_idx][label][rstrip(folder,'/')*suffix] = value
         end
      end
   end
   return (result, summary_dict, solution_pm)
end


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
      override_param=Dict(),
      start_vals=Dict("sn"=>Dict()),
      no_converter_loss::Bool=false
   )
   (result, res_summary, solution_pm, binding_cnstr) = multifrequency_opf(
      "$parent_folder/$(folder)", objective,
      gen_areas=gen_areas, area_interface=area_transfer, gen_zones=gen_zones, zone_interface=zone_transfer, print_results=print_results,
      fix_f_override=fix_f_override, direct_pq=direct_pq,
      master_subnet=1, suffix=suffix, override_param=override_param, start_vals=start_vals, no_converter_loss=no_converter_loss
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
