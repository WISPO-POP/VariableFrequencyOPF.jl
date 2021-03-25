GR.inline("pdf")
function plot_results_dict_bar(
      results_dict,
      n_subnets,
      subnet_array,
      idx_sorted,
      output_folder,
      plot_best_x
   )
   upscale = 2 #upscaling in resolution
   fntsm = font("serif", pointsize=round(8.0*upscale))
   fntlg = font("serif", pointsize=round(12.0*upscale))
   default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   default(size=(800*upscale,600*upscale)) #Plot canvas size

   gr()

   # plot all results
   # println("results_dict: $results_dict")
   for (label,results) in results_dict
      if (label == "status") || (label == "subnet")
         continue
      end
      for subnet_i in 0:n_subnets
         # println("subnet_i: $subnet_i")
         br_results = Array{Float64,1}()
         br_indices = Array{String,1}()
         br_results_fixf = Array{Float64,1}()
         br_indices_fixf = Array{String,1}()
         br_results_indirPQ = Array{Float64,1}()
         br_indices_indirPQ = Array{String,1}()
         base_res = -9999.0
         if subnet_i == 0
            # Don't plot total for frequency
            if label == "frequency (Hz)"
               continue
            end
            plotlabel = "total $label"
            plotdir = "total"
         else
            plotlabel = "subnet $(subnet_array[subnet_i]) $label"
            plotdir =  "subnet$(subnet_array[subnet_i])"
         end
         for (folder,res) in results
            if results_dict["status"][folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
               if subnet_i == 0
                  subnet_result = sum(res)
               else
                  try
                     subnet_result = res[subnet_i]
                  catch
                     subnet_result = 0
                  end
               end
            else
               subnet_result = -9999.0
               println("Subnet $subnet_i, network $folder: result is -9999.0")
            end
            if occursin("br", folder)
               if occursin("_fixf", folder)
                  push!(br_results_fixf, subnet_result)
                  push!(br_indices_fixf, folder[3:(end-5)])
               elseif occursin("_indirPQ", folder)
                  push!(br_results_indirPQ, subnet_result)
                  push!(br_indices_indirPQ, folder[3:(end-8)])
               else
                  push!(br_results, subnet_result)
                  push!(br_indices, folder[3:end])
               end
            # Remove base value to plot separately
            elseif occursin("base", folder)
               base_res = subnet_result
            end
         end
         # Sort values
         # sort all by primary result instead of sorting each individually
         println("label: $label")
         perm = sortperm(br_indices)[sortperm(sortperm(idx_sorted))]
         println("perm: $perm")
         println("br_results: $br_results")
         println("br_indices: $br_indices")
         br_results_sorted = br_results[perm]
         br_indices_sorted = br_indices[perm]
         println("br_results_sorted: $br_results_sorted")
         println("br_indices_sorted: $br_indices_sorted")
         if plot_best_x > 1
            br_results_sorted = br_results_sorted[1:plot_best_x]
            br_indices_sorted = br_indices_sorted[1:plot_best_x]
         end

         # If fixed f folders are present for comparison, also sort these
         if length(br_indices_fixf) > 0
            if length(br_indices_fixf) < length(br_indices_sorted)
               println("Adding results to br_indices_fixf:")
               # println("~br_indices_fixf: $br_indices_fixf")
               # println("~br_indices_sorted: $br_indices_sorted")
               # println("~br_results_fixf: $br_results_fixf")
               # println("~br_results_sorted: $br_results_sorted")
               append!(br_indices_fixf, setdiff(br_indices_sorted, br_indices_fixf))
               # println("appending $(zeros(length(br_indices_sorted)-length(br_indices_fixf)))")
               append!(br_results_fixf, -9999.0*ones(Float64, length(br_results_sorted)-length(br_results_fixf)))

            elseif length(br_indices_fixf) > length(br_indices_sorted)
               println("Adding results to br_indices_sorted:")
               # println("br_indices_fixf: $br_indices_fixf")
               # println("br_indices_sorted: $br_indices_sorted")
               # println("setdiff(br_indices_fixf, br_indices_sorted): $(setdiff(br_indices_fixf, br_indices_sorted))")
               append!(br_indices_sorted, setdiff(br_indices_fixf, br_indices_sorted))
               append!(br_results_sorted, -9999.0*ones(Float64, length(br_results_fixf)-length(br_results_sorted)))
            end
            # println("br_indices_fixf: $br_indices_fixf")
            # println("br_indices_sorted: $br_indices_sorted")
            # println("br_results_fixf: $br_results_fixf")
            # println("br_results_sorted: $br_results_sorted")
            perm_fixf = sortperm(br_indices_fixf)[sortperm(sortperm(br_indices_sorted))]
            # println("perm_fixf: $perm_fixf")
            br_indices_fixf_sorted = br_indices_fixf[perm_fixf]
            br_results_fixf_sorted = br_results_fixf[perm_fixf]
            if plot_best_x > 1
               br_indices_fixf_sorted = br_indices_fixf_sorted[1:plot_best_x]
               br_results_fixf_sorted = br_results_fixf_sorted[1:plot_best_x]
            end
         else
            br_indices_fixf = []
            br_indices_fixf_sorted = []
            br_results_fixf_sorted = []
         end

         # If indirPQ folders are present for comparison, also sort these
         if length(br_indices_indirPQ) > 0
            if length(br_indices_indirPQ) < length(br_indices_sorted)
               append!(br_indices_indirPQ, setdiff(br_indices_sorted, br_indices_indirPQ))
               append!(br_results_indirPQ, -9999.0*ones(Float64, length(br_results_sorted)-length(br_results_indirPQ)))

            elseif length(br_indices_indirPQ) > length(br_indices_sorted)
               append!(br_indices_sorted, setdiff(br_indices_indirPQ, br_indices_sorted))
               append!(br_results_sorted, -9999.0*ones(Float64, length(br_results_indirPQ)-length(br_results_sorted)))
            end
            perm_indirPQ = sortperm(br_indices_indirPQ)[sortperm(sortperm(br_indices_sorted))]
            # println("perm_fixf: $perm_fixf")
            br_indices_indirPQ_sorted = br_indices_indirPQ[perm_indirPQ]
            br_results_indirPQ_sorted = br_results_indirPQ[perm_indirPQ]
            if plot_best_x > 1
               br_indices_indirPQ_sorted = br_indices_indirPQ_sorted[1:plot_best_x]
               br_results_indirPQ_sorted = br_results_indirPQ_sorted[1:plot_best_x]
            end
         else
            br_indices_indirPQ = []
            br_indices_indirPQ_sorted = []
            br_results_indirPQ_sorted = []
         end

         # Plot subnet values
         if br_indices_fixf_sorted == br_indices_sorted == br_indices_indirPQ_sorted
            if length(br_indices_sorted) == 0
               println("No feasible solutions were found for any of the cases. No plots will be generated.")
               return
            end
            println("Plotting variable and fixed frequency and indirect PQ values.")
            println("variable f: $br_results_sorted")
            println("fixed f: $br_results_fixf_sorted")
            println("passive PQ: $br_results_indirPQ_sorted")
            grouplabels = CategoricalArray(repeat(["passive PQ", "fixed \\omega", "variable \\omega"], inner = length(br_results)), ordered=true)
            levels!(grouplabels, ["passive PQ", "fixed \\omega", "variable \\omega"])
            nam = CategoricalArray(repeat(string.(br_indices_fixf_sorted), outer = 3), ordered=true)
            levels!(nam, string.(br_indices_fixf_sorted))
            vals = vcat(br_results_indirPQ_sorted,br_results_fixf_sorted,br_results_sorted)
            p = groupedbar(
               nam,
               vals,
               xticks=(0:(length(br_indices_sorted)-1), br_indices_sorted),
               group = grouplabels,
               bar_edges=true,
               linewidth=0, left_margin=(10*upscale)*mm,
               right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
               legend=:bottomright,
               xrotation=90
            )
            if base_res != -9999.0
               hline!([base_res], line=(2*upscale, :dash), label="base network")
               miny = min(
                  min(br_results_sorted[br_results_sorted.>-9999.0]...),
                  min(br_results_fixf_sorted[br_results_fixf_sorted.>-9999.0]...),
                  min(br_results_indirPQ_sorted[br_results_indirPQ_sorted.>-9999.0]...),
                  base_res
               )
               maxy = max(
                  max(br_results_sorted...),
                  max(br_results_fixf_sorted...),
                  max(br_results_indirPQ_sorted...),
                  base_res
               )
            else
               miny = min(
                  min(br_results_sorted[br_results_sorted.>-9999.0]...),
                  min(br_results_fixf_sorted[br_results_fixf_sorted.>-9999.0]...),
                  min(br_results_indirPQ_sorted[br_results_indirPQ_sorted.>-9999.0]...)
               )
               maxy = max(
                  max(br_results_sorted...),
                  max(br_results_fixf_sorted...),
                  max(br_results_indirPQ_sorted...)
                  )
            end
         elseif br_indices_fixf_sorted == br_indices_sorted
            if length(br_indices_sorted) == 0
               println("No feasible solutions were found for any of the cases. No plots will be generated.")
               return
            end
            println("Plotting variable and fixed frequency values.")
            grouplabels = CategoricalArray(repeat(["variable \\omega", "fixed \\omega"], inner = length(br_results)), ordered=true)
            levels!(grouplabels, ["variable \\omega", "fixed \\omega"])
            nam = CategoricalArray(repeat(string.(br_indices_fixf_sorted), outer = 2), ordered=true)
            levels!(nam, string.(br_indices_fixf_sorted))
            vals = vcat(br_results_sorted,br_results_fixf_sorted)
            p = groupedbar(
               nam,
               vals,
               xticks=(0:(length(br_indices_sorted)-1), br_indices_sorted),
               group = grouplabels,
               bar_edges=true,
               linewidth=0, left_margin=(10*upscale)*mm,
               right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
               legend=:bottomright,
               xrotation=90
            )
            if base_res != -9999.0
               hline!([base_res], line=(2*upscale, :dash), label="base network")
               miny = min(
                  min(br_results_sorted[br_results_sorted.>-9999.0]...),
                  min(br_results_fixf_sorted[br_results_fixf_sorted.>-9999.0]...),
                  base_res
               )
               maxy = max(
                  max(br_results_sorted...),
                  max(br_results_fixf_sorted...),
                  base_res
               )
            else
               miny = min(
                  min(br_results_sorted[br_results_sorted.>-9999.0]...),
                  min(br_results_fixf_sorted[br_results_fixf_sorted.>-9999.0]...)
               )
               maxy = max(
                  max(br_results_sorted...),
                  max(br_results_fixf_sorted...)
                  )
            end
         else
            # println("br_indices_fixf_sorted: $br_indices_fixf_sorted")
            # println("br_indices_sorted: $br_indices_sorted")
            # println("br_results_fixf: $br_results_fixf")
            # println("br_results_sorted: $br_results_sorted")
            println("Plotting only variable frequency values.")
            nam = string.(br_indices_sorted)
            vals = br_results_sorted
            p = bar(
               nam,
               vals,
               xticks=(0:(length(br_indices_sorted)-1), br_indices_sorted),
               bar_edges=true,
               linewidth=0, left_margin=(10*upscale)*mm,
               right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
               legend=:bottomright,
               xrotation=90
            )

            if base_res != -9999.0
               hline!([base_res], line=(2*upscale, :dash), label="base network")
               # println("br_results_sorted: $br_results_sorted")
               # println("br_results_sorted[br_results_sorted.>-9999.0]: $(br_results_sorted[br_results_sorted.>-9999.0])")
               miny = min(min(br_results_sorted[br_results_sorted.>-9999.0]...), base_res)
               maxy = max(max(br_results_sorted...), base_res)
            else
               # println("br_results_sorted: $br_results_sorted")
               # println("br_results_sorted[br_results_sorted.>-9999.0]: $(br_results_sorted[br_results_sorted.>-9999.0])")
               miny = min(br_results_sorted[br_results_sorted.>-9999.0]...)
               maxy = max(br_results_sorted...)
            end
         end
         # Set y limits
         diff = maxy - miny
         if diff > 0
            ylims!(miny-0.1*diff, maxy+0.1*diff)
         end
         xlabel!("branch index")
         ylabel!(plotlabel)
         if !isdir("$(output_folder)/plots/$plotdir")
            mkpath("$(output_folder)/plots/$plotdir")
         end
         # println("saving plot at $(output_folder)/plots/$plotdir/$plotlabel.pdf")
         savefig(p,"$(output_folder)/plots/$plotdir/$plotlabel.pdf")
      end
   end
end

function plot_results_dicts_bar(
      results_dict_allplots,
      n_subnets,
      subnet_array,
      idx_sorted,
      output_folder,
      plot_best_x,
      series_labels=[];
      color_palette=:tab10
   )
   upscale = 2 #upscaling in resolution
   fntsm = font("serif", pointsize=round(8.0*upscale))
   fntlg = font("serif", pointsize=round(12.0*upscale))
   default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   default(size=(800*upscale,600*upscale)) #Plot canvas size

   gr()

   if isa(results_dict_allplots, Dict)
      results_dict_allplots = [results_dict_allplots]
   end
   if length(series_labels) == 0
      series_labels = [[] for i in results_dict_allplots]
   end

   n_series = length(results_dict_allplots)

   function make_result_arrays!(br_results, base_results, br_results_sorted, results_dict, series_s, plotlabels, plotdirs)
      for (label,results) in results_dict
         if (label == "status") || (label == "subnet")
            continue
         end
         if !(label in keys(br_results_all))
            br_results[label] = Dict{Int64,Any}()
            br_results_sorted[label] = Dict{Int64,Any}()
            base_results[label] = Dict{Int64,Any}()
            plotlabels[label] = Dict{Int64,Any}()
            plotdirs[label] = Dict{Int64,Any}()
         end

         for subnet_i in 0:n_subnets
            if subnet_i == 0
               # Don't plot total for frequency
               if label == "frequency (Hz)"
                  continue
               end
            end
            if series_s == 1
               base_results[label][subnet_i] = NaN
            end

            if !(subnet_i in keys(br_results_all[label]))
               br_results[label][subnet_i] = Dict{Int64,Any}()
               br_results_sorted[label][subnet_i] = Dict{Int64,Any}()
            end

            if !(series_s in keys(br_results_all[label][subnet_i]))
               br_results[label][subnet_i][series_s] = Dict{String,Any}()
               br_results_sorted[label][subnet_i][series_s] = Array{Float64,1}()
            end

            for (folder,res) in results
               if !(folder in keys(br_results_all[label][subnet_i][series_s]))
                  br_results[label][subnet_i][series_s][folder] = NaN
               end
            end
         end

         for subnet_i in 0:n_subnets
            statuses = results_dict["status"]

            if subnet_i == 0
               # Don't plot total for frequency
               if label == "frequency (Hz)"
                  continue
               end
               plotlabels[label][0] = "total $label"
               plotdirs[label][0] = "total"
            # else
            #    plotlabels[label][subnet_i] = "subnet $(subnet_array[subnet_i]) $label"
            #    plotdirs[label][subnet_i] =  "subnet$(subnet_array[subnet_i])"
            end

            for (folder,res) in results
               subnet_number = 0
               if statuses[folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, "LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]
                  if subnet_i == 0
                     # println("$folder series $series_s")
                     # println("$label res: $res")
                     subnet_result = sum(res)
                     br_results[label][0][series_s][folder] = subnet_result
                     if occursin("base", folder) && (series_s == 1)
                        base_results[label][subnet_number] = subnet_result
                        # println("set base_results[$label][$subnet_number] to $subnet_result")
                     end
                  else
                     try
                        subnet_number = results_dict["subnet"][folder][subnet_i]
                        subnet_result = res[subnet_i]
                        plotlabels[label][subnet_number] = "subnet $(subnet_number) $label"
                        plotdirs[label][subnet_number] =  "subnet$(subnet_number)"
                        if occursin("br", folder)
                           # push!(br_results[label][subnet_number][series_s][folder], subnet_result)
                           # push!(br_indices[label][subnet_number][series_s][folder], folder)
                           br_results[label][subnet_number][series_s][folder] = subnet_result
                           # println("Subnet $subnet_number, network $folder: result is $(br_results[label][subnet_number][series_s][folder])")
                           # println("Subnet_i: $subnet_i")
                           # println("results_dict[\"subnet\"][folder]=$(results_dict["subnet"][folder])")
                        # Remove base value to plot separately
                        elseif occursin("base", folder)
                           # if series_s == 1
                              base_results[label][subnet_number] = subnet_result
                              # println("set base_results[$label][$subnet_number] to $subnet_result")
                           # end
                        end
                     catch BoundsError
                        # println("BoundsError attempting to access subnet $subnet_i")
                        # println("results_dict[\"subnet\"][$folder] = $(results_dict["subnet"][folder])")
                        # println("res = $(res)")
                        # subnet_number = length(results_dict["subnet"][folder]) + 1
                        # subnet_result = -9999.0
                     end
                  end
               end
            end
         end
      end
   end


   br_results_all = Dict{String,Any}()
   base_results = Dict{String,Any}()
   br_results_all_sorted = Dict{String,Any}()
   plotlabels = Dict{String,Any}()
   plotdirs = Dict{String,Any}()
   # series_s = 1
   # Make arrays and add values from the first series
   # make_result_arrays!(br_results_all, br_indices_all, br_results_all_sorted, br_indices_all_sorted, results_dict_allplots[series_s], series_s)
   # results_string = JSON.json(br_results_all)
   # open("./br_results_temp.json", "w") do f
   #    write(f, results_string)
   # end

   # Sort values
   # Save permutation vector to sort all by primary result instead of sorting each individually
   for (series_s,results_dict) in enumerate(results_dict_allplots)
      make_result_arrays!(br_results_all, base_results, br_results_all_sorted, results_dict_allplots[series_s], series_s, plotlabels, plotdirs)
      # println("base_results: $base_results")
      for (label,results) in results_dict
         if (label == "status") || (label == "subnet")
            continue
         end
         # println("\n$label")
         # println("=================")
         for subnet_i in 0:n_subnets
            if subnet_i == 0
               # Don't plot total for frequency
               if label == "frequency (Hz)"
                  continue
               end
            end
            # Sort values
            # println("subnet $subnet_i")
            # println("series $series_s")
            # println([v for (i,v) in br_results_all[label][subnet_i][series_s]])
            # println("idx_sorted: $idx_sorted")
            # println([br_results_all[label][subnet_i][series_s][idx] for idx in idx_sorted])
            # println("br_results_all[$label][$subnet_i]: $(br_results_all[label][subnet_i])")
            # println("idx_sorted: $(idx_sorted)")
            # println("series_s: $series_s")
            br_results_all_sorted[label][subnet_i][series_s] = [br_results_all[label][subnet_i][series_s][idx] for idx in idx_sorted]

            if plot_best_x > 1
               br_results_all_sorted[label][subnet_i][series_s] = br_results_sorted[label][subnet_i][series_s][1:plot_best_x]
            end
      #       # println("br_results_all[label][subnet_i][series_s]: $(br_results_all[label][subnet_i][series_s])")
      #       # println("idx_sorted: $(idx_sorted)")
      #       # println([br_results_all[label][subnet_i][series_s][idx] for idx in idx_sorted])
      #
      #       br_results_all_sorted[label][subnet_i][series_s] = [br_results_all[label][subnet_i][series_s][idx] for idx in idx_sorted]
      #
      #       if plot_best_x > 1
      #          br_results_all_sorted[label][subnet_i][series_s] = br_results_sorted[label][subnet_i][series_s][1:plot_best_x]
      #       end
         end
      end
   end

   for (label,results) in results_dict_allplots[1]
      if (label == "status") || (label == "subnet")
         continue
      end
      # println("Plotting $label")
      for subnet_i in 0:n_subnets
         # println("Plotting subnet $subnet_i")
         if subnet_i == 0
            # Don't plot total for frequency
            if label == "frequency (Hz)"
               continue
            end
         end
         nam = CategoricalArray(repeat(string.(idx_sorted), outer = length(results_dict_allplots)), ordered=true)
         levels!(nam, string.(idx_sorted))
         # nam = repeat(string.(idx_sorted), outer = length(results_dict_allplots))
         # println("size(nam) $(size(nam))")
         vals = vcat(Any[br_results_all_sorted[label][subnet_i][series_s] for series_s in 1:length(results_dict_allplots)]...)

         if (all(vals.<=-9999.0) || all(isnan.(vals)))
            println("All values are missing. Skipping")
            continue
         end

         # println("nam: $nam")
         # println("size(vals) $(size(vals))")
         # println("vals: $vals")
         grouplabels = CategoricalArray(repeat(series_labels, inner = length(idx_sorted)), ordered=true)
         levels!(grouplabels, series_labels)
         # grouplabels = repeat(series_labels, inner = size(vals)[2])
         # println("size(grouplabels) $(size(grouplabels))")
         # println("grouplabels: $grouplabels")

         p = groupedbar(
            nam,
            vals,
            group = grouplabels,
            xticks=(0:(length(idx_sorted)-1), idx_sorted),
            bar_edges=true,
            linewidth=0, left_margin=(10*upscale)*mm,
            right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
            legend=:bottomright,
            xrotation=90,
            palette=color_palette
         )
         base_res = base_results[label][subnet_i]
         # println("base_results[$label][$subnet_i] = $base_res")
         if !isnan(base_res) && (base_res != -9999.0)
            println("plotting base = $base_res")
            hline!([base_res], line=(2*upscale, :dash), label="base network")
            miny = min(
               min(vals[.!isnan.(vals) .& (vals.>-9999.0)]...),
               base_res
            )
            maxy = max(
               max(vals[.!isnan.(vals)]...),
               base_res
            )
         else
            println("not plotting base = $base_res")
            miny = min(vals[.!isnan.(vals) .& (vals.>-9999.0)]...)
            maxy = max(vals[.!isnan.(vals)]...)
         end

         # Set y limits
         diff = maxy - miny
         if diff > 0
            ylims!(miny-0.1*diff, maxy+0.1*diff)
         end

         plotlabel = plotlabels[label][subnet_i]
         plotdir = plotdirs[label][subnet_i]
         xlabel!("branch index")
         ylabel!(plotlabel)
         if !isdir("$(output_folder)/plots/$plotdir")
            mkpath("$(output_folder)/plots/$plotdir")
         end
         println("saving plot at $(output_folder)/plots/$plotdir/$plotlabel.pdf")
         savefig(p,"$(output_folder)/plots/$plotdir/$plotlabel.pdf")
      end
   end

   # # Now repeat for all other results dictionaries, but sort according to the first dictionary
   # for (series_s,results_dict) in enumerate(results_dict_allplots[2:end])
   #    make_result_arrays!(br_results_all, br_indices_all, results_dict, series_s)
   # end
   #
   #
   # for (label,results) in results_dict_allplots[1]
   #    if (label == "status") || (label == "subnet")
   #       continue
   #    end
   #    for subnet_i in results_dict_allplots[series_s]["subnet"]
   #       br_results_s = br_results_all[label][subnet_i][series_s]
   #       br_indices_s = br_indices_all[label][subnet_i][series_s]
   #
   #       perm_s = sortperm(br_indices_i)[sortperm(sortperm(br_indices_sorted))]
   #
   #       br_indices_s_sorted = br_indices_s[perm_fixf]
   #       br_results_s_sorted = br_results_s[perm_fixf]
   #
   #       if plot_best_x > 1
   #          br_indices_s_sorted = br_indices_s_sorted[1:plot_best_x]
   #          br_results_s_sorted = br_results_s_sorted[1:plot_best_x]
   #       end
   #
   #
   #       # Plot subnet values
   #       if length(br_indices_sorted) == 0
   #          println("No feasible solutions were found for any of the cases. No plots will be generated.")
   #          return
   #       end

   #

end
