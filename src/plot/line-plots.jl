GR.inline("pdf")
# upscale = 2 #upscaling in resolution
# fntsm = font("serif", pointsize=round(8.0*upscale))
# fntlg = font("serif", pointsize=round(12.0*upscale))
# default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
# default(size=(800*upscale,600*upscale)) #Plot canvas size
#
# gr()

function plot_results_dict_line(
      results_dict_allplots,
      subnet_arr,
      x_axis,
      output_folder,
      vert_line,
      horiz_line,
      xlimits,
      ylimits,
      output_plot_label,
      xvals=[],
      points_dict=Dict();
      plot_infeasible_boundaries=true,
      series_labels=[],
      color_palette=:tab10
   )

   GR.inline("pdf")

   upscale = 2 #upscaling in resolution
   fntsm = font("serif", pointsize=round(8.0*upscale))
   fntlg = font("serif", pointsize=round(12.0*upscale))
   default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   default(size=(800*upscale,600*upscale)) #Plot canvas size

   gr()

   # Given each specific key for the x axis values, collect the values into x_arr and the indices into indices array
   # println("axis: $axis")

   if isa(results_dict_allplots, Dict)
      results_dict_allplots = [results_dict_allplots]
   end
   if length(series_labels) == 0
      series_labels = [[] for i in results_dict_allplots]
   end

   function make_x_array(results_dict)
      ax_key = x_axis

      if !(ax_key[1] in keys(results_dict))
         if ax_key[1] == "sn"
            x_label = join(ax_key, " ")
            # x_label = ax_key
            # println("x_label: $x_label")
            x_arr = Array{Float64,1}()
            indices_arr = Array{Int64,1}()
            for (param,res) in results_dict[x_label]
               push!(x_arr, res)
               push!(indices_arr, param)
            end
            # Sort values by index of results dictionary (index is the parameter which was varied)
            perm = sortperm(indices_arr)
            x_sorted = x_arr[perm]
            indices_sorted = indices_arr[perm]
         else # custom x axis
            x_label = ax_key[1]
            x_arr = ax_key[2]
            indices_arr = Array{Int64,1}()
            for (param,res) in results_dict["subnet"]
               push!(indices_arr, param)
            end
            # Sort values by index of results dictionary (index is the parameter which was varied)
            perm = sortperm(indices_arr)
            indices_sorted = indices_arr[perm]
            x_sorted = x_arr[indices_sorted]
         end
      else
         (res_label_x,subnet_x) = ax_key

         x_arr = Array{Float64,1}()
         x_label = ""
         indices_arr = Array{Int64,1}()
         for (param,res) in results_dict[res_label_x]
            if length(res) == 1
               x_result = (res isa Array) ? res[1] : res
               x_label = res_label_x
            elseif subnet_x == 0
               x_result = sum(res)
               x_label = "total $res_label_x"
            else
               x_result = res[findfirst(subnet_arr.==subnet_x)]
               x_label = "subnet $subnet_x $res_label_x"
            end
            push!(x_arr, x_result)
            param_num = (typeof(param) == String) ? parse(Int64, param) : param
            push!(indices_arr, param_num)
         end
         # Sort values by index of results dictionary (index is the parameter which was varied)
         perm = sortperm(indices_arr)
         x_sorted = x_arr[perm]
         indices_sorted = indices_arr[perm]
      end

      # Now do the same for the points dictionary
      pts_x_arr = Array{Float64,1}()
      if length(points_dict) > 0
         ax_key = x_axis
         if !(ax_key[1] in keys(points_dict))
            if ax_key[1] == "sn"
               x_label = join(ax_key, " ")
               # x_label = ax_key
               # println("x_label: $x_label")
               pts_indices_arr = Array{Int64,1}()
               for (param,res) in points_dict[x_label]
                  push!(pts_x_arr, res)
                  push!(pts_indices_arr, param)
               end
            else # custom x axis
               x_label = ax_key[1]
               pts_x_arr = ax_key[2]
               pts_indices_arr = Array{Int64,1}()
               if "subnet" in keys(points_dict)
                  for (param,res) in points_dict["subnet"]
                     push!(pts_indices_arr, param)
                  end
               end
            end
         else
            (res_label_x,subnet_x) = ax_key
            pts_x_arr = Array{Float64,1}()
            x_label = ""
            pts_indices_arr = Array{Int64,1}()
            for (param,res) in points_dict[res_label_x]
               if length(res) == 1
                  x_result = (res isa Array) ? res[1] : res
                  x_label = res_label_x
               elseif subnet_x == 0
                  x_result = sum(res)
                  x_label = "total $res_label_x"
               else
                  x_result = res[findfirst(subnet_arr.==subnet_x)]
                  x_label = "subnet $subnet_x $res_label_x"
               end
               push!(pts_x_arr, x_result)
               push!(pts_indices_arr, param)
            end
         end
      end
      return x_sorted, indices_sorted, pts_x_arr, perm, x_label
   end

   #    if (label == "status") || (label == "subnet")
   #       continue
   #    end
   #    for subnet_i in 0:n_subnets
   #       # println("subnet_i: $subnet_i")
   #       br_results[1] = Array{Float64,1}()
   #       br_indices[1] = Array{String,1}()
   #       base_res = -9999.0
   #       if subnet_i == 0
   #          # Don't plot total for frequency
   #          if label == "frequency (Hz)"
   #             continue
   #          end
   #          plotlabel = "total $label"
   #          plotdir = "total"
   #       else
   #          plotlabel = "subnet $(subnet_array[subnet_i]) $label"
   #          plotdir =  "subnet$(subnet_array[subnet_i])"
   #       end
   #       for (folder,res) in results
   #          if results_dict["status"][folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
   #             if subnet_i == 0
   #                subnet_result = sum(res)
   #             else
   #                try
   #                   subnet_result = res[subnet_i]
   #                catch
   #                   subnet_result = 0
   #                end
   #             end
   #          else
   #             subnet_result = -9999.0
   #             println("Subnet $subnet_i, network $folder: result is -9999.0")
   #          end
   #          if occursin("br", folder)
   #             push!(br_results[1], subnet_result)
   #             push!(br_indices[1], folder[3:end])
   #          # Remove base value to plot separately
   #          elseif occursin("base", folder)
   #             base_res = subnet_result
   #          end
   #       end


   # Collect all values in the dictionary and plot them against the x values
   # Some dictionary entries contain values from multiple subnetworks, while others are specific to a single bus, gen, or branch
   function plot_series!(plots, results_dict, x_sorted, indices_sorted, pts_x_arr, perm, x_label, series_label)
      output_plot = nothing

      for (label,results) in results_dict
         res_vals = collect(values(results))
         if (label == "status") || (label == "subnet") || (length(res_vals) < 1) || (any(res_vals.==nothing))
            continue
         end
         if length(points_dict) > 0
            pts_results = points_dict[label]
         end
         pts_y_arr = Array{Float64,1}()
         pts_labels = Array{Any,1}()
         # println("results: $results")
         n_subnets = length(res_vals[1])
         y_arr = Array{Float64,1}()
         status_pairs = sort(collect(results_dict["status"]), by = x -> x[1])
         statuses = map(x -> x[2], status_pairs)
         solved = indexin(statuses, [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, "LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]) .!= nothing
         if plot_infeasible_boundaries
            # println("solved: $solved")
            infeas_boundary_l = (solved[2:end] - solved[1:end-1]) .< 0
            append!(infeas_boundary_l, [0])
            infeas_boundary_r = zeros(Bool, 1)
            append!(infeas_boundary_r, (solved[2:end] - solved[1:end-1]) .> 0)
            # println("infeas_boundary_l: $(infeas_boundary_l)")
            # println("infeas_boundary_r: $(infeas_boundary_r)")
            infeas_boundary_idx = x_sorted[infeas_boundary_l .| infeas_boundary_r]
         else
            infeas_boundary_idx = []
         end
         # println("infeas_boundary_idx: $infeas_boundary_idx")
         if n_subnets == 1
            plt = plots[label][1]
            plotlabel = label
            dirs = split(label," ")
            if dirs[1] == "sn"
               plotdir = join(dirs[1:end-1],"/")
            else
               plotdir = ""
            end
            for (param,res) in results
               y_result = (res isa Array) ? res[1] : res
               push!(y_arr, y_result)
            end
            # Sort values by index of results dictionary (index is the parameter which was varied)
            y_sorted = y_arr[perm]
            y_sorted[.!solved] .= NaN
            # println("y_sorted: $y_sorted")
            if length(points_dict) > 0
               for (param,res) in pts_results
                  pts_y_result = (res isa Array) ? res[1] : res
                  push!(pts_y_arr, pts_y_result)
                  pts_y_label = (param isa Array) ? param[1] : param
                  push!(pts_labels, string(pts_y_label))
               end
            end
            # println("$label: single subnet: $y_sorted")
            plotdir = "vs "*x_label*"/"*plotdir
            p = plot_line!(plt,x_sorted, y_sorted, x_label, plotlabel, output_folder, plotdir, vert_line, horiz_line, xlimits, ylimits, xvals, infeas_boundary_idx, pts_x_arr=pts_x_arr, pts_y_arr=pts_y_arr, pts_labels=pts_labels, series_label=series_label)
            if (x_label == output_plot_label[1]) && (plotlabel == output_plot_label[2])
               output_plot = p
               # println("= = = = = = = =\noutput_plot: $output_plot\n= = = = = = = =")
            end
         else
            for subnet_i in 0:n_subnets
               # println("subnet_i: $subnet_i")
               plt = plots[label][subnet_i]
               y_arr = Array{Float64,1}()
               pts_y_arr = Array{Float64,1}()
               pts_labels = Array{String,1}()
               # indices = Array{Int64,1}()
               if subnet_i == 0
                  # Don't plot total for frequency
                  if label == "frequency (Hz)"
                     continue
                  end
                  plotlabel = "total $label"
                  plotdir = "total"
               else
                  plotlabel = "subnet $(subnet_arr[subnet_i]) $label"
                  plotdir =  "subnet$(subnet_arr[subnet_i])"
               end
               for (folder,res) in results
                  if subnet_i == 0
                     subnet_result = sum(res)
                  else
                     subnet_result = res[subnet_i]
                  end
                  push!(y_arr, subnet_result)
               end
               # Sort values by index of results dictionary (index is the parameter which was varied)
               y_sorted = y_arr[perm]
               y_sorted[.!solved] .= NaN
               # println("y_sorted: $y_sorted")
               if length(points_dict) > 0
                  for (param,res) in pts_results
                     if subnet_i == 0
                        subnet_result = sum(res)
                     else
                        subnet_result = res[subnet_i]
                     end
                     push!(pts_y_arr, subnet_result)
                     push!(pts_labels, param)
                  end
               end

               plotdir = "vs "*x_label*"/"*plotdir
               p = plot_line!(plt, x_sorted, y_sorted, x_label, plotlabel, output_folder, plotdir, vert_line, horiz_line, xlimits, ylimits, xvals, infeas_boundary_idx, pts_x_arr=pts_x_arr, pts_y_arr=pts_y_arr, pts_labels=pts_labels, series_label=series_label)
               if (x_label == output_plot_label[1]) && (plotlabel == output_plot_label[2])
                  output_plot = p
                  # println("= = = = = = = =\noutput_plot: $output_plot\n= = = = = = = =")
               end
            end
         end
      end
      return output_plot
   end

   x_sorted_allplots = []
   indices_sorted_allplots = []
   pts_x_arr_allplots = []
   perm_allplots = []
   x_label_allplots = []
   for results_dict in results_dict_allplots
      (x_sorted, indices_sorted, pts_x_arr, perm, x_label) = make_x_array(results_dict)
      push!(x_sorted_allplots,x_sorted)
      push!(indices_sorted_allplots,indices_sorted)
      push!(pts_x_arr_allplots,pts_x_arr)
      push!(perm_allplots,perm)
      push!(x_label_allplots,x_label)
   end

   plots_dict = Dict{String,Any}()
   for (dict_idx,results_dict) in enumerate(results_dict_allplots)
      for (label,results) in results_dict
         # println("label: $label")
         if (label in keys(plots_dict))
            continue
         end
         if (label == "status") || (label == "subnet")
            continue
         end
         if any(values(results) .== nothing)
            continue
         end
         plots_dict[label] = Dict{Int64,Any}()
         n_subnets = length(collect(values(results))[1])
         for subnet_i in 0:n_subnets
            if !(subnet_i in keys(plots_dict[label]))
               plots_dict[label][subnet_i] = Plots.plot(palette=color_palette)
            end
         end
      end
   end

   output_plot = Plots.Plot()
   for (i,results_dict) in enumerate(results_dict_allplots)
      output_plot = plot_series!(
      plots_dict,
      results_dict,
      x_sorted_allplots[i],
      indices_sorted_allplots[i],
      pts_x_arr_allplots[i],
      perm_allplots[i],
      x_label_allplots[i],
      series_labels[i]
      )
   end

   # outprint = output_plot != nothing ? output_plot : "nothing"
   # println("\n***IN plot_results_dict_line, output_plot = $outprint")
   return output_plot
end

function plot_line(
      x_sorted,
      y_sorted,
      x_label,
      y_label,
      output_folder,
      plotdir,
      vert_line=([],""),
      horiz_line=([],""),
      xlimits=[],
      ylimits=[],
      xvals=[],
      infeasible_boundaries=[];
      pts_x_arr,
      pts_y_arr,
      pts_labels
   )
   GR.inline("pdf")

   upscale = 2 #upscaling in resolution
   fntsm = font("serif", pointsize=round(8.0*upscale))
   fntlg = font("serif", pointsize=round(12.0*upscale))
   default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   default(size=(800*upscale,600*upscale)) #Plot canvas size

   gr()
   plt = Plots.plot()
   plot_line!(plt,x_sorted, y_sorted, x_label, y_label, output_folder, plotdir, vert_line, horiz_line, xlimits, ylimits, xvals, infeasible_boundaries; pts_x_arr=pts_x_arr, pts_y_arr=pts_y_arr, pts_labels=pts_labels)

   return plt
end

function plot_line!(
      plt::Plots.Plot,
      x_sorted,
      y_sorted,
      x_label,
      y_label,
      output_folder,
      plotdir,
      vert_line=([],""),
      horiz_line=([],""),
      xlimits=[],
      ylimits=[],
      xvals=[],
      infeasible_boundaries=[];
      pts_x_arr,
      pts_y_arr,
      pts_labels,
      series_label=""
   )
   GR.inline("pdf")

   upscale = 2 #upscaling in resolution
   fntsm = font("serif", pointsize=round(8.0*upscale))
   fntlg = font("serif", pointsize=round(12.0*upscale))
   default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   default(size=(800*upscale,600*upscale)) #Plot canvas size

   gr()
   # println("x_sorted: $x_sorted")
   # println("y_sorted: $y_sorted")
   if length(series_label) == 0
      plot!(plt, x_sorted, y_sorted,
         legend=false,
         left_margin=(10*upscale)*mm,
         right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
         linewidth=2*upscale,
         # marker = (:dot, 1.5*upscale, 0.6, :green, stroke(0))
      )
   else
      plot!(plt, x_sorted, y_sorted,
         label=series_label,
         legend=true,
         left_margin=(10*upscale)*mm,
         right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
         linewidth=2*upscale,
         # marker = (:dot, 1.5*upscale, 0.6, :green, stroke(0))
      )
   end

   if length(xvals) > 0
      println("xvals: $xvals")
      println("x_sorted: $x_sorted")
      println("y_sorted: $y_sorted")
      plot!(
         plt, xvals, y_sorted[indexin(xvals, x_sorted)],
         line=:scatter,
         marker=(:dot, 2*upscale, 0.8, :red, stroke(0))
         )
      # println("plotted $xvals, $(y_sorted[indexin(xvals, x_sorted)])")
   end
   if length(infeasible_boundaries) > 0
      for v in infeasible_boundaries
         # println("v: $v")
         vline!([v], line=(0.5*upscale, :dash, :red), label="")
      end
   end
   if (length(pts_x_arr) > 0) && (length(pts_y_arr) > 0)
      plot!(
         plt, pts_x_arr, pts_y_arr,
         # series_annotations=Plots.series_annotations(string.(pts_labels), Plots.font("Sans", 12)),
         # annotation=string.(pts_labels),
         annotations = [(pts_x_arr[i], pts_y_arr[i], text(pts_labels[i], font("Sans", 12), :left, :bottom)) for i in 1:length(pts_y_arr)],
         # annotationguide = :left,
         line=:scatter,
         marker=(:dot, 2*upscale, 0.8, :blue, stroke(0))
         )
      # annotate!(p, pts_x_arr, pts_y_arr, text.(pts_labels, :left), font("Sans", 12))
   end
   if length(vert_line[1]) > 0
      for v in vert_line[1]
         # println("v: $v")
         vline!(plt, [v], line=(2*upscale, :dash), label=vert_line[2])
      end
   end
   if length(horiz_line[1]) > 0
      for h in horiz_line[1]
         # println("h: $h")
         hline!([h], line=(2*upscale, :dash), label=horiz_line[2])
         miny = min(min(y_sorted...), min(horiz_line[1]...), min(pts_y_arr...,Inf))
         maxy = max(max(y_sorted...), max(horiz_line[1]...), max(pts_y_arr...,-Inf))
      end
   else
      miny = min(min(y_sorted...), min(pts_y_arr...,Inf))
      maxy = max(max(y_sorted...), max(pts_y_arr...,-Inf))
   end


   # Set x limits
   if length(xlimits) == 2
      xlims!(plt, min(xlimits...), max(xlimits...))
   end

   # Set y limits
   if length(ylimits) == 2
      ylims!(plt, min(ylimits...), max(ylimits...))
   else
      curr_ylims = ylims(plt)
      # println("Current y limits: $curr_ylims")
      diff = maxy - miny
      if diff > 0
         ylims!(plt, min(miny-0.1*diff, curr_ylims[1]), max(maxy+0.1*diff,curr_ylims[2]))
      else
         ylims!(plt, min(0.9*miny, curr_ylims[1]), max(1.1*maxy,curr_ylims[2]))
      end
   end

   # println("New y limits: $(ylims(plt))")
   xlabel!(plt, x_label)
   ylabel!(plt, y_label)
   # savefig(p,"$(folder)/$(y_label) vs $(x_label).pdf")
   if !isdir("$(output_folder)/plots/$plotdir")
      mkpath("$(output_folder)/plots/$plotdir")
   end
   # println("saving plot at $(output_folder)/plots/$plotdir/$(y_label) vs $(x_label).pdf")
   # display(plt)
   savefig(plt,"$(output_folder)/plots/$plotdir/$(y_label) vs $(x_label).pdf")
end
