function collect_subnet_results(results_dict, objective, gen_areas, gen_zones, output_folder, plot_best_x)
   # upscale = 8 #upscaling in resolution
   # fntsm = font("serif", pointsize=round(8.0*upscale))
   # fntlg = font("serif", pointsize=round(12.0*upscale))
   # default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
   # default(size=(800*upscale,600*upscale)) #Plot canvas size
   # default(left_margin = 15mm, right_margin = 15mm)
   # default(dpi=300) #Only for PyPlot - presently broken

   # pyplot(guidefont=font, xtickfont=font, ytickfont=font, legendfont=font)
   # plotlyjs()

   # gr(titlefont=font("serif", pointsize=round(10.0*upscale)), guidefont=font("serif", pointsize=round(10.0*upscale)), tickfont=font("serif", pointsize=round(10.0*upscale)), legendfont=font("serif", pointsize=round(10.0*upscale)4))
   # pyplot()
   # gr()
   # Plot the primary label first
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
   # Remove base value to plot separately
   br_results = Array{Float64,1}()
   br_indices = Array{String,1}()
   br_results_fixf = Array{Float64,1}()
   br_indices_fixf = Array{String,1}()
   br_results_indirPQ = Array{Float64,1}()
   br_indices_indirPQ = Array{String,1}()
   base_res = -9999.0
   subnet_array = []
   n_subnets = 0
   for (folder,res) in results
      println("folder: $folder")
      if results_dict["status"][folder] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED]
         subnet_array = union(subnet_array, results_dict["subnet"][folder]) # Get maximal set with subnets represented in any folders
         # n_subnets = max(n_subnets,length(res))
         # if subnet_array == nothing
         #    subnet_array = results_dict["subnet"][folder]
         #    println("subnet_array: $subnet_array")
         # else
         #    @assert (subnet_array == results_dict["subnet"][folder]) "Subnet order does not match in results files: $subnet_array vs. $(results_dict["subnet"][folder])"
         # end
         if occursin("br", folder)
            if occursin("_fixf", folder)
               push!(br_results_fixf, sum(res))
               push!(br_indices_fixf, folder[3:(end-5)])
            elseif occursin("_indirPQ", folder)
               push!(br_results_indirPQ, sum(res))
               push!(br_indices_indirPQ, folder[3:(end-8)])
            else
               push!(br_results, sum(res))
               push!(br_indices, folder[3:end])
            end
         # elseif folder == "base"
         #    base_res = res
         elseif folder == "base_unconstrPS"
            base_res = res
         end
      else
         subnet_array = union(subnet_array, results_dict["subnet"][folder]) # Get maximal set with subnets represented in any folders
         if occursin("br", folder)
            if occursin("_fixf", folder)
               push!(br_results_fixf, -9999.0)
               push!(br_indices_fixf, folder[3:(end-5)])
            elseif occursin("_indirPQ", folder)
               push!(br_results_indirPQ, -9999.0)
               push!(br_indices_indirPQ, folder[3:(end-8)])
            else
               push!(br_results, -9999.0)
               push!(br_indices, folder[3:end])
            end
         # elseif folder == "base"
         #    base_res = -9999.0
         elseif folder == "base_unconstrPS"
            base_res = -9999.0
         end
      end
      n_subnets = length(subnet_array)
   end
   # println("br_results: $br_results")
   # Sort values
   br_results_tosort = copy(br_results)
   br_results_tosort[br_results_tosort.==-9999.0] .= Inf
   perm = sortperm(br_results_tosort)
   idx_sorted = br_indices[perm]
   # println("perm: $perm")
   # println("idx_sorted: $idx_sorted")


   # plot all results
   plot_results_dict_bar(results_dict,n_subnets,subnet_array,idx_sorted,output_folder,plot_best_x)

end
