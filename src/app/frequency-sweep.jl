
"""
    function frequency_ranges(
      f_min,
      f_max,
      subnet::Int64,
      directory::String,
      objective::String,
      x_axis::Array,
      y_axis::Array;
      gen_areas=Int64[],
      area_transfer=Int64[],
      gen_zones=[],
      zone_transfer=[],
      plot_vert_line::Tuple=([],""),
      plot_horiz_line::Tuple=([],""),
      xlimits::Array{Any,1}=[],
      ylimits::Array{Any,1}=[],
      output_plot_label::Tuple{String,String}=("",""),
      scopf::Bool=false,
      contingency::Int64=0,
      k_cond=[],
      k_ins=[],
      scale_load=1.0,
      scale_areas=Int64[],
      no_converter_loss=false,
      output_location_base="",
      output_results_folder=""
    )

Models and solves an OPF with frequency in specified ranges between `f_min` and `f_max`.

# Arguments
- `f_min`: lower bounds on frequency, one for each point in the frequency sweep
- `f_max`: upper bounds on frequency, one for each point in the frequency sweep. Must have the same length as `f_min`.
- `subnet::Int64`: subnetwork for which the frequency bounds are applied
- `folder::String`: the directory containing all subnetwork data, *subnetworks.csv*, and *interfaces.csv*
- `objective::String`: the objective function to use, from the following:
   - "mincost": minimize generation cost
   - "areagen": minimize generation in the areas specified in `gen_areas`
   - "zonegen": minimize generation in the zones specified in `gen_zones`
   - "minredispatch": minimize the change in generator dispatch from the initial values defined in the network data
- `x_axis::Array`: Array of Tuples identifying the x axis series for which plots should be generated over the points in the frequency sweep. A separate folder of plots is generated for each Tuple in the array. The series can be specified in the Tuple in one of three ways:
   - **results dictionary values:** A two-element Tuple, where the first element is a String matching a key in the results dictionary output from `multifrequency_opf` and the second element is an Int specifying a subnetwork. This plots the values of this key and subnetwork entry on the x axis.
   - **network data values:** A Tuple with elements corresponding to keys at each level of the network data dictionary, identifying any network variable value. This plots the values of the specified network variable on the x axis. Any key in the Tuple may be an Array, in which case a separate plot is generated for each key. For example, to generate four plots, the active and reactive power at the origin ("f") bus and destination ("t") bus for branch 1 in subnetwork 2, use the Tuple `("sn",2,"branch",1,["pt","pf","qt","qf"])`
   - **custom values:** A two-element Tuple, where the first element is a String not matching any keys in the results dictionary and the second element is an Array. This plots the values in the Array on the x axis with the label in the String.
- `y_axis::Array`: Array of Tuples identifying the y axis series for which plots should be generated over the points in the frequency sweep. A separate folder of plots is generated for each Tuple in the array. These are specified in the same way as `x_axis`.
- `gen_areas`: all areas in which generation should be minimized if `obj=="areagen"`
- `area_transfer`: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.
- `gen_zones`: all zones in which generation should be minimized if `obj=="zonegen"`
- `zone_transfer`: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.
- `plot_vert_line::Tuple`: x values of vertical lines to overlay on the plot. The first element is a scalar or Array specifying one or more x values to plot, and the second element is a String or Array of Strings specifying the label or labels. Default ([],"") does not add any lines to the plot.
- `plot_horiz_line::Tuple`: y values of horizontal lines to overlay on the plot. The first element is a scalar or Array specifying one or more y values to plot, and the second element is a String or Array of Strings specifying the label or labels. Default ([],"") does not add any lines to the plot.
- `xlimits::Array{Any,1}`: Array of two values specifying the min and max x axis limits to apply to the plots, overriding any other limits. Default [] does not change the plot.
- `ylimits::Array{Any,1}`: Array of two values specifying the min and max y axis limits to apply to the plots, overriding any other limits. Default [] does not change the plot.
- `output_plot_label::Tuple{String,String}`: specifies the plot to pass to the output. The first element must match the x axis label, and the second must match the y axis label.
- `scopf::Bool`: if true, model and solve the N-1 security constrained OPF for each network. Each network folder must contain a contingency specification file (_*.con_) for each subnetwork. Default false.
- `contingency::Tuple`: indices of the contingency to plot. The precontingency index is (0,). Default (0,).
- `k_cond`: conductor utilization parameter for HVDC. Only used when f==0. Default [].
- `k_ins`: insulation factor parameter for HVDC. Only used when f==0. Default [].
- `scale_load`: factor for scaling the load in the frequency sweep. Default 1.0.
- `scale_areas`: array of integer area indices for which the load scaling factor `scale_load` should be applied. Applies to all areas if this array is empty. Default Int64[].
- `no_converter_loss`: override all converter loss parameters specified in the data and replace them with the the lossless converter model.
- `output_location_base`: location in which to save the results and plots. If not specified, a folder called `results` will be created in the folder one level above the data folder.
- `output_results_folder`: specific folder in which to save the results, one level below `output_location_base`, if specified.
"""
function frequency_ranges(
      f_min,
      f_max,
      subnet::Int64,
      folder::String,
      objective::String,
      x_axis::Array,
      y_axis::Array;
      gen_areas=Int64[],
      area_transfer=Int64[],
      gen_zones=[],
      zone_transfer=[],
      plot_vert_line::Tuple=([],""),
      plot_horiz_line::Tuple=([],""),
      xlimits::Array{Any,1}=[],
      ylimits::Array{Any,1}=[],
      output_plot_label::Tuple{String,String}=("",""),
      scopf::Bool=false,
      contingency::Int64=0,
      k_cond=[],
      k_ins=[],
      scale_load=1.0,
      scale_areas=Int64[],
      no_converter_loss=false,
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
      output_folder = joinpath(toplevels...,"results/$(folder_split[end-1])/$(folder_split[end])")
   end
   output_folder = joinpath(output_folder, output_results_folder)
   if !isdir(output_folder)
      mkpath(output_folder)
   end
   println("output location: $output_folder")

   (results_dict, output_plot) = frequency_ranges(
      f_min,
      f_max,
      subnet,
      mn_data,
      output_folder,
      objective,
      x_axis,
      y_axis;
      gen_areas=gen_areas,
      area_transfer=area_transfer,
      gen_zones=gen_zones,
      zone_transfer=zone_transfer,
      plot_vert_line=plot_vert_line,
      plot_horiz_line=plot_horiz_line,
      xlimits=xlimits,
      ylimits=ylimits,
      output_plot_label=output_plot_label,
      scopf=scopf,
      contingency=contingency,
      k_cond=k_cond,
      k_ins=k_ins,
      scale_load=scale_load,
      scale_areas=scale_areas,
      no_converter_loss=no_converter_loss,
      output_results_folder=""
   )
   return (results_dict, output_plot)
end

function frequency_ranges(
      f_min,
      f_max,
      subnet::Int64,
      mn_data::Dict,
      output_folder::String,
      objective::String,
      x_axis::Array,
      y_axis::Array;
      gen_areas=Int64[],
      area_transfer=Int64[],
      gen_zones=[],
      zone_transfer=[],
      plot_vert_line::Tuple=([],""),
      plot_horiz_line::Tuple=([],""),
      xlimits::Array{Any,1}=[],
      ylimits::Array{Any,1}=[],
      output_plot_label::Tuple{String,String}=("",""),
      scopf::Bool=false,
      contingency::Int64=0,
      k_cond=[],
      k_ins=[],
      scale_load=1.0,
      scale_areas=Int64[],
      no_converter_loss=false,
      output_results_folder=""
   )


   suffix=""
   if scopf
      params = ([["sn",contingency,"sn",subnet,"f_min"],["sn",contingency,"sn",subnet,"f_max"]],[f_min, f_max])
   elseif scale_load==1
      params = ([["sn",subnet,"f_min"],["sn",subnet,"f_max"]],[f_min, f_max])
   else
      println("Scaling load by $scale_load.")
      suffix = "_scaled_x$(string(scale_load))"
      scale_all_areas = false
      if length(scale_areas) == 0
         scale_all_areas = true
      end
      # get load pd and qd from areas of interest and put them in dict_filt
      sn_data = read_sn_data(directory)
      dict_filt = Dict()
      for (subnet_idx,sn_subnet) in sn_data["sn"]
         for (load_idx,load) in sn_subnet["load"]
            if (sn_subnet["bus"]["$(load["load_bus"])"]["area"] in scale_areas) || (scale_all_areas)
               pd_keys = ["sn",subnet_idx,"load",load_idx,"pd"]
               pd = load["pd"]
               set_nested!(dict_filt, pd_keys, pd)
               qd_keys = ["sn",subnet_idx,"load",load_idx,"qd"]
               qd = load["qd"]
               set_nested!(dict_filt, qd_keys, qd)
            end
         end
      end

      # get the nested keys values
      (load_keys,load_values) = traverse_nested(dict_filt)

      # apply scaling
      # println("load_keys: $load_keys")
      # println("load_values: $load_values")
      # values_scaled = collect(eachrow(load_values .* scale_load'))
      values_scaled = Array{Any}(undef, length(load_values))
      for (idx,val) in enumerate(load_values)
         values_scaled[idx] = val * ones(length(f_min)) * scale_load
      end

      params = (append!([["sn",subnet,"f_min"],["sn",subnet,"f_max"]],load_keys),append!(Any[f_min, f_max], values_scaled))
   end

   if (length(k_cond)) > 0 && (length(k_ins) > 0)
      if scopf
         dc_params = ([["sn",contingency,"sn",subnet,"k_ins"],["sn",contingency,"sn",subnet,"k_cond"],["sn",contingency,"sn",subnet,"f_max"]],[k_ins, k_cond, zeros(length(k_ins))])
      else
         dc_params = ([["sn",subnet,"k_ins"],["sn",subnet,"k_cond"],["sn",subnet,"f_max"]],[k_ins, k_cond, zeros(length(k_ins))])
      end
   else
      dc_params = ()
   end

   output_folder = joinpath(output_folder*suffix, output_results_folder)

   # println("params:")
   # println(params)

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
         plot_vert_line,
         plot_horiz_line,
         xlimits,
         ylimits,
         output_plot_label,
         scopf,
         contingency,
         dc_params;
         output_results_folder=output_results_folder
      )
   # for config in hvdc_config
   #
   # end
   # outprint = output_plot != nothing ? output_plot : "nothing"
   # println("\n***IN frequency_ranges, output_plot = $outprint")
   return (results_dict, output_plot)
end
