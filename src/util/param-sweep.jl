function run_multiple_params(
      folder::String,
      objective::String,
      x_axis::Array,
      y_axis::Array,
      params,
      gen_areas=Int64[],
      area_transfer=Int64[],
      gen_zones=Int64[],
      zone_transfer=Int64[],
      vert_line=([],""),
      horiz_line=([],""),
      xlimits=[],
      ylimits=[],
      output_plot_label=("",""),
      scopf=false,
      ctg=0,
      points_params=(),
      suffix="";
      no_converter_loss::Bool=false,
      output_location_base="",
      output_results_folder=""
   )

   mn_data = read_sn_data(folder, no_converter_loss=no_converter_loss)

   folder = abspath(folder)
   if length(output_location_base) > 0
      output_folder = output_location_base
   else
      folder_split = splitpath(folder)
      toplevels = folder_split[1:end-3]
      output_folder = joinpath(toplevels...,"results/$(folder_split[end-1])/$(folder_split[end])$suffix")
   end
   output_folder = joinpath(output_folder, output_results_folder)
   if !isdir(output_folder)
      mkpath(output_folder)
   end
   println("output location: $output_folder")

   (results_dict, output_plot) = run_multiple_params(
         mn_data,
         output_folder,
         objective,
         x_axis,
         y_axis,
         params,
         gen_areas,
         area_transfer,
         gen_zones,
         zone_transfer,
         vert_line,
         horiz_line,
         xlimits,
         ylimits,
         output_plot_label,
         scopf,
         ctg,
         points_params;
         output_results_folder
      )

   return results_dict, output_plot
end

function run_multiple_params(
      mn_data::Dict{String,Any},
      output_folder::String,
      objective::String,
      x_axis::Array,
      y_axis::Array,
      params,
      gen_areas=Int64[],
      area_transfer=Int64[],
      gen_zones=Int64[],
      zone_transfer=Int64[],
      vert_line=([],""),
      horiz_line=([],""),
      xlimits=[],
      ylimits=[],
      output_plot_label=("",""),
      scopf=false,
      ctg=0,
      points_params=();
      output_results_folder=""
   )

   output_folder = joinpath(output_folder, output_results_folder)

   (results_dict, subnet_arr,
   summary_df,
   binding_cnstr_fulldict,
   constraintlog,
   x_label_arr,
   constraint_transitions) = apply_params(
      mn_data,
      output_folder,
      objective,
      x_axis,
      y_axis,
      params,
      gen_areas,
      area_transfer,
      gen_zones,
      zone_transfer,
      vert_line,
      horiz_line,
      xlimits,
      ylimits,
      output_plot_label,
      scopf,
      ctg,
      false
   )
   if length(points_params) > 0
      (points_dict, _,
      pts_summary_df,
      _,_,_,_
      ) = apply_params(
         mn_data,
         output_folder,
         objective,
         x_axis,
         y_axis,
         points_params,
         gen_areas,
         area_transfer,
         gen_zones,
         zone_transfer,
         vert_line,
         horiz_line,
         xlimits,
         ylimits,
         output_plot_label,
         scopf,
         ctg,
         true
      )
      # concatenate summary dataframes
      summary_df = vcat(summary_df, pts_summary_df)
   end


   # println("final results_dict: $results_dict")
   results_dict_string = JSON.json(results_dict)
   println("Saving results at $(output_folder)/all_results_dict.json")
   open("$output_folder/all_results_dict.json", "w") do f
      write(f, results_dict_string)
   end

   println("Saving summary at $(output_folder)/all_param_summary.csv")
   CSV.write("$(output_folder)/all_param_summary.csv", summary_df)

   binding_cnstr_dict_string = JSON.json(binding_cnstr_fulldict)
   open("$output_folder/all_binding_constraints.json", "w") do f
      write(f, binding_cnstr_dict_string)
   end

   open("$output_folder/constraint_log.txt", "w") do f
      write(f, lstrip(constraintlog, '\n'))
   end

   x_label_arr=unique(x_label_arr)
   # println("x_label_arr: $x_label_arr")
   output_plot = nothing
   for x_label in x_label_arr
      # println("x_label: $x_label")
      xvals = []
      println("x_label: $x_label")
      if x_label[1] == "frequency (Hz)"
         xvals = constraint_transitions
         # println("xvals: $xvals")
      end
      if !(length(points_params) > 0)
         output_tmp = plot_results_dict_line(
            results_dict,
            subnet_arr,
            x_label,
            output_folder,
            vert_line,
            horiz_line,
            xlimits,
            ylimits,
            output_plot_label,
            xvals,
            plot_infeasible_boundaries=true
         )
      else
         output_tmp = plot_results_dict_line(
            results_dict,
            subnet_arr,
            x_label,
            output_folder,
            vert_line,
            horiz_line,
            xlimits,
            ylimits,
            output_plot_label,
            xvals,
            points_dict,
            plot_infeasible_boundaries=true
         )
      end

      if output_tmp != nothing
         output_plot = deepcopy(output_tmp)
      end
   end
   return results_dict, output_plot
end

function apply_params(
   folder::String,
   output_folder::String,
   objective::String,
   x_axis::Array,
   y_axis::Array,
   params,
   gen_areas,
   area_transfer,
   gen_zones,
   zone_transfer,
   vert_line,
   horiz_line,
   xlimits,
   ylimits,
   output_plot_label,
   scopf,
   ctg,
   pts_param=false;
   no_converter_loss::Bool=false
)

   mn_data = read_sn_data(folder, no_converter_loss=no_converter_loss)

   (
   results_dict,
   subnet_arr,
   summary_df,
   binding_cnstr_fulldict,
   constraintlog,
   x_label_arr,
   constraint_transitions
   ) = apply_params(
      mn_data,
      output_folder,
      objective,
      x_axis,
      y_axis,
      params,
      gen_areas,
      area_transfer,
      gen_zones,
      zone_transfer,
      vert_line,
      horiz_line,
      xlimits,
      ylimits,
      output_plot_label,
      scopf,
      ctg,
      pts_param
   )
   return results_dict, subnet_arr, summary_df, binding_cnstr_fulldict, constraintlog, x_label_arr, constraint_transitions
end

function apply_params(
   mn_data::Dict{String,Any},
   output_folder::String,
   objective::String,
   x_axis::Array,
   y_axis::Array,
   params,
   gen_areas,
   area_transfer,
   gen_zones,
   zone_transfer,
   vert_line,
   horiz_line,
   xlimits,
   ylimits,
   output_plot_label,
   scopf,
   ctg,
   pts_param=false
)
   (p_keys,p_values)=params
   override_param = Dict{Any, Any}()
   results_dict = Dict{String, Dict{Any, Any}}()
   summary_df = DataFrame()
   subnet_arr = Array{Int64,1}()
   x_label_arr = []
   binding_cnstr_fulldict = Dict{String,Any}()
   prev_keystring = ""
   constraintlog = ""
   constraint_transitions = []
   for i in 1:length(p_values[1])
      # println("i=$i")
      for (val_idx,value) in enumerate(p_values)
         # println(val_idx)
         # println("keys: $(string.(p_keys[val_idx]))")
         # println("val: $(value[i])")
         set_nested!(override_param, string.(p_keys[val_idx]), value[i])
      end
      # println("running $(folder)")
      # println("override_param: $override_param")
      print_results = false
      fix_f_override = false
      direct_pq = true
      master_subnet = 1
      start_vals=Dict{String, Dict}("sn"=>Dict())
      uniform_gen_scaling = false
      unbounded_pg = false
      output_to_files = true
      (result, res_summary, solution_pm, binding_cnstr) = multifrequency_opf(
         mn_data,
         output_folder,
         objective,
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
         output_to_files
      )

      if (length(binding_cnstr_fulldict) == 0)
         # keystring = rstrip(join([p_keys[val_idx][end]*"=$(value[i]); " for (val_idx,value) in enumerate(p_values)]), ';')
         keystring = p_keys[1][end]*"=$(p_values[1][i])"
         binding_cnstr_fulldict[keystring] = binding_cnstr
         prev_keystring = keystring
      else
         if (res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]) && (binding_cnstr_fulldict[prev_keystring] != binding_cnstr)
            println("Active constraint set has changed. Saving set.")
            # keystring = rstrip(join([p_keys[val_idx][end]*"=$(value[i]); " for (val_idx,value) in enumerate(p_values)]), ';')
            keystring = p_keys[1][end]*"=$(p_values[1][i])"
            binding_cnstr_fulldict[keystring] = binding_cnstr
            constraintlog *= "\n$keystring\n"
            for (idx, class) in binding_cnstr
               for (subnet, constr_set) in class
                  prev_set = []
                  try
                     prev_set = binding_cnstr_fulldict[prev_keystring][idx][subnet]
                  catch KeyError
                     prev_set = []
                  end
                  constr_added = setdiff(constr_set, prev_set)
                  if length(constr_added) > 0
                     println("Added constraints in $subnet:")
                     println(constr_added)
                     constraintlog *= "Added constraints in $subnet:\n$constr_added\n"
                  end
               end
            end
            for (idx, class) in binding_cnstr_fulldict[prev_keystring]
               for (subnet, constr_set) in class
                  new_set = []
                  try
                     new_set = binding_cnstr[idx][subnet]
                  catch KeyError
                     new_set = []
                  end
                  constr_removed = setdiff(constr_set, new_set)
                  if length(constr_removed) > 0
                     println("Removed constraints in $subnet:")
                     println(constr_removed)
                     constraintlog *= "Removed constraints in $subnet:\n$constr_removed\n"
                  end
               end
            end
            # Add to contraint transition points if this is a frequency sweep
            key_idx = indexin(["f_min", "f_max"], [p_keys[val_idx][end] for (val_idx,value) in enumerate(p_values)])
            if sum(key_idx .!= nothing) == 2
               if abs(p_values[key_idx[1]][i] - p_values[key_idx[2]][i]) <= 1e-6
                  append!(constraint_transitions, p_values[key_idx[1]][i])
               end
            end
            if !pts_param
               # println("constraint_transitions: $constraint_transitions")
               open("$output_folder/constraint_log.txt", "w") do f
                  write(f, lstrip(constraintlog, '\n'))
               end
            end
            prev_keystring = keystring
         end
      end
      # println("Result keys: $(keys(result))")
      if i == 1
         subnet_arr = result["subnet"]
      end
      # println(override_param[:network_wide][:f_max][subnet])
      println("trial $i of $(length(p_values[1]))")
      # println(res_summary)
      res_summary[:,:network] .= "trial $i"
      # res_summary.network = "trial $i"
      for (ax_idx,axis) in enumerate([x_axis, y_axis])
         # ax_res_key = []
         # println("axis: $axis")
         for ax_key in axis
            if !(ax_key[1] in keys(result))
               if ax_key[1] == "sn"
                  for sn_key in ax_key[2]
                     elem = ax_key[3]
                     for elem_key in ax_key[4]
                        if isa(ax_key[5], Array)
                           for quantity in ax_key[5]
                              new_key = ("sn", "$sn_key", elem, "$elem_key", quantity)
                              label = join(new_key, " ")
                              if (ax_idx == 1) && !(new_key in x_label_arr)
                                 push!(x_label_arr,new_key)
                              end
                              value = get_nested(solution_pm, new_key)
                              if value == nothing
                                 # println(new_key)
                                 # println(keys(solution_pm))
                                 # println(solution_pm["sn"])
                                 # throw(KeyError("The value $new_key for axis $ax_idx is not found."))
                                 # println("The value $new_key for axis $ax_idx is not found.")
                                 value = NaN
                              end
                              if !(label in keys(results_dict))
                                 results_dict[label] = Dict{Any, Any}()
                              end
                              # Comment the '|| true' to prevent saving outputs when not solved to optimum
                              if !pts_param
                                 if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED] || true
                                    results_dict[label][i] = value
                                 end
                              else
                                 if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
                                    lbl = join(["$(p_keys[j][end])=$(round(p_values[j][i],digits=3)), " for j in 1:length(p_keys)])
                                    lbl = rstrip(lbl, ' ')
                                    lbl = rstrip(lbl, ',')
                                    println("lbl=$lbl")
                                    results_dict[label][lbl] = value
                                 end
                              end
                           end
                        else
                           quantity = ax_key[5]
                           new_key = ("sn", "$sn_key", elem, "$elem_key", quantity)
                           label = join(new_key, " ")
                           if (ax_idx == 1) && !(new_key in x_label_arr)
                              push!(x_label_arr,new_key)
                           end
                           value = get_nested(solution_pm, new_key)
                           if value == nothing
                              # println(new_key)
                              # println(keys(solution_pm))
                              throw(KeyError("The value $new_key for axis $ax_idx is not found."))
                           end
                           if !(label in keys(results_dict))
                              results_dict[label] = Dict{Float64, Any}()
                           end
                           # Comment '|| true' to prevent saving outputs when not solved to optimum
                           if !pts_param
                              if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED] || true
                                 results_dict[label][i] = value
                              end
                           else
                              if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
                                 lbl = join(["$(p_keys[j][end])=$(round(p_values[j][i],digits=3)), " for j in 1:length(p_keys)])
                                 lbl = rstrip(lbl, ' ')
                                 lbl = rstrip(lbl, ',')
                                 println("lbl=$lbl")
                                 results_dict[label][lbl] = value
                              end
                           end
                        end
                     end
                  end
               elseif (ax_idx == 1) && !(ax_key in x_label_arr) # ax_key[1] is not "sn": custom axis values and label
                  push!(x_label_arr,ax_key)
               end
            elseif (ax_idx == 1) && !(ax_key in x_label_arr) # ax_key is in the results dict and should be in the x axis array
               push!(x_label_arr,ax_key)
            end
         end
      end
      for (label,value) in result
         if !(label in keys(results_dict))
            results_dict[label] = Dict{Float64, Any}()
         end
         if !pts_param
            if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED] || true
               results_dict[label][i] = value
            end
         else
            if res_summary.status[1] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
               lbl = join(["$(p_keys[j][end])=$(round(p_values[j][i],digits=3)), " for j in 1:length(p_keys)])
               lbl = rstrip(lbl, ' ')
               lbl = rstrip(lbl, ',')
               println("lbl=$lbl")
               results_dict[label][lbl] = value
            end
         end
      end

      if size(summary_df,1) > 0
         summary_df = vcat(summary_df, res_summary)
      else
         summary_df = res_summary
      end
   end
   return results_dict, subnet_arr, summary_df, binding_cnstr_fulldict, constraintlog, x_label_arr, constraint_transitions
end
