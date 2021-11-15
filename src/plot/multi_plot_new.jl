using Pkg
using PowerModels, CSV, DataFrames, Dates, JSON
using Plots
using Ipopt
using JuMP
using Statistics
using Plots
using Plots.PlotMeasures
using Combinatorics
using StatsPlots

#include("time_series_opf.jl")

# function to plot the given data files with given plot choice parameters
#
# function parameters
#################################################
# month_st, day_st, period_st, month_en, day_en, period_en: the start and end time for the period of data to plot
# br_arr_raw: the array containg the indexex of subnets to plot (in format of Int64). If using the single for plot_choice, the function only reads in the first index for default.
# folder: the target folder containg the data files for plot
# output_folder: the folder specified to save the output files
# plot_choice::String = "single": default single,
#       "single": optimal result & frequency of a network in a range
#       "compare": compare average value of multiple networks

# all network indexes:
# [1 2 3 4 5 6 8 9 10 11 12 13 14 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42
# 43 44 45 46 47 49 50 51 52 53 54 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82
# 83 84 85 87 88 89 90 91 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117
# 118 119]

# the function of plotting results of multifrequency-opf on different netwoks and in different periods
function multi_plot_new(month_st, day_st, period_st, month_en, day_en, period_en, br_arr_raw, folder, output_folder,
      plot_choice::String = "single")

      # time range
      start_t = DateTime(2020,month_st,day_st,period_st)
      end_t = DateTime(2020,month_en,day_en,period_en)
      range_t = start_t:Hour(1):end_t

      all_range = DateTime(2020,1,1,1):Hour(1):DateTime(2020,12,31,24)
      part_range = DateTime(2020, month_st, day_st, period_st):Hour(1):DateTime(2020,month_en, day_en, period_en)
      # num_br: the number of branches we want to plot
      num_br = max(size(br_arr_raw, 1), size(br_arr_raw, 2))

      # br_result: the optimization result of the subnets (temporary storage)
      # res_summary_dict: the final data structure of optimization results of the subnets
      # br_arr: array of the indexes of all the subnets into string format (for further indexing format)
      br_result = Dict()
      res_summary_dict = Dict()
      br_arr = Array{String, 1}()
      for i = 1:num_br
            push!(br_arr, string(br_arr_raw[i]))
      end

      base_info = JSON.parsefile("D:/github/VariableFrequencyOPF/time_series_out_modified/res_summary_base_(1.1.1__12.31.24).json")
      # base_info_part = Dict()
      # for i = 1:size(part_range, 1)
      #       base_info_part[i] = deepcopy(base_info)
      # end
      for br_ind = 1:num_br
            # input result summary from specified input folder (output folder of the optimization function)
            #dict_info = JSON.parsefile("$(folder)/res_summary_br$(br_arr[br_ind])_(1.1.1__12.31.24).json")
            #dict_info = JSON.parsefile("$(folder)/res_summary_br$(br_arr[br_ind])_(7.15.1_7.15.24).json")
            dict_info = JSON.parsefile("$(folder)/res_summary_br$(br_arr[br_ind])_(1.1.1__12.31.24).json")
            br_result[br_ind] = dict_info
            # the result dictionary can be of different data structure
            res_summary_dict[br_arr[br_ind]] = deepcopy(br_result[br_ind])

            # if (plot_choice == "comp")
            #       # modify all the types of the fields to be Float64
            #       for i in 1:size(all_range, 1)
            #             # convert the optimal value to Float64
            #             if typeof(res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][20][1]) == String
            #                   res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][20][1] =
            #                        parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][20][1])
            #             end
            #
            #             # # convert the optimal frequency to Float64
            #             # if typeof(res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][2][1]) == String
            #             #       res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][2][1] =
            #             #            parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][2][1])
            #             # end
            #       end

            # normalize the data formats
            # loop through the locations of results from the output file of optimization function
            # ( the data format need to be changed for different )
            for i in 1:size(part_range, 1)
            #elseif (plot_choice == "single")

                  # convert the optimal value to Float64
                  # if typeof(res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1]) == String
                  #       res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1] =
                  #            parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])
                  # end

                  # convert the optimal frequency to Float64
                  if typeof(res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1]) == String
                        res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1] =
                             parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1])
                            #FIXME parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["f"][1])
                  end

                  # if typeof(res_summary_dict[br_arr[br_ind]]["$(i)"]["f"][1]) == String
                  #       res_summary_dict[br_arr[br_ind]]["$(i)"]["f"][1] =
                  #            parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["f"][1])
                  #           #FIXME parse(Float64, res_summary_dict[br_arr[br_ind]]["$(i)"]["f"][1])
                  # end
            end

      end

      # change the type of the object for base case

      for i in 1:size(all_range, 1)
            if typeof(base_info["$(i)"]["objective"][1]) == String
                  base_info["$(i)"]["objective"][1] =
                       parse(Float64, base_info["$(i)"]["objective"][1])
            end
      end

      # the dictionaries to store output values (objective value/frequency/size), "_n" represents the array of points
      # where the solver did not find objective values
      objval = Dict()
      objval_n = Dict()
      obj_freq = Dict()
      obj_freq_n = Dict()
      size_obj = Array{DateTime, 1}()
      size_obj_n = Array{DateTime, 1}()
      objval_base = Array{Float64, 1}()

      # this is the single array that store the data for single branch for comparison to base case
      objval_all = Dict()
      size_obj_all = Array{DateTime, 1}()
      #objfreq_base = Array{Float64, 1}()

      #if (plot_choice == "comp")
            for br_ind = 1:num_br
                  objval[br_ind] = Array{Float64, 1}()
                  objval_n[br_ind] = Array{Float64, 1}()
                  obj_freq[br_ind] = Array{Float64, 1}()
                  obj_freq_n[br_ind] = Array{Float64, 1}()
                  objval_all[br_ind] = Array{Float64, 1}()
            end
      #end
      #
      # for i in 1:size(range_t, 1)
      #       if ((res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][22][1] in ["LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"])
      #          && (res_summary_dict[br_arr[br_ind]]["$(i)"]["columns"][22][2] in ["LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]))
      #          push!(size_obj[br_ind], range_t[i])
      #       else
      #          push!(size_obj_n[br_ind], range_t[i])
      #       end
      # end

      # find the starting time for the indexing below based on input time range and the whole year time range
      start_t_ind = findfirst(isequal(start_t), part_range)
      start_all_ind = findfirst(isequal(start_t), all_range)
      println("$(start_t_ind)")
      println("$(start_all_ind)")

      # for plot average value comparison:


      # here divide each time index into feasible array and infeasible array
      # index start from the start time above and loop for the size of the range we want to plot for
      for i in start_t_ind:(start_t_ind + size(range_t, 1) - 1)
            push!(size_obj_all, range_t[i-start_t_ind + 1])
            if ((res_summary_dict[br_arr[1]]["$(i)"]["status"] in ["LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]))
               push!(size_obj, range_t[i-start_t_ind + 1])
            else
               push!(size_obj_n, range_t[i-start_t_ind + 1])
               println("infeasible$(i), $(res_summary_dict[br_arr[1]]["$(i)"]["status"])")
            end
      end

      # store data for base case

      for i in start_t_ind:(start_t_ind + size(range_t, 1) - 1)
            all_ind = start_all_ind + i - 1
            println(all_ind)
            push!(objval_base, base_info["$(all_ind)"]["objective"][1])
      end

      # store the values of objective values
      for br_ind = 1:num_br
            for i in start_t_ind:(start_t_ind + size(range_t, 1) - 1)
                  #println("absd$(i)")
                  push!(objval_all[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])

                  # if ((res_summary_dict[br_arr[br_ind]]["$(i)"]["status"] in ["LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]))
                  #    push!(objval[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])
                  #    push!(obj_freq[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1])
                  #    #push!(size_obj[br_ind], range_t[i])
                  # else
                  #    push!(objval_n[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])
                  #    push!(obj_freq_n[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1])
                  #    #push!(size_obj_n[br_ind], range_t[i])
                  # end

                  if ((res_summary_dict[br_arr[br_ind]]["$(i)"]["status"] in ["LOCALLY_SOLVED", "ALMOST_LOCALLY_SOLVED"]))
                     push!(objval[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])
                     push!(obj_freq[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1])
                     #push!(size_obj[br_ind], range_t[i])
                  else
                     push!(objval_n[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["objective"][1])
                     push!(obj_freq_n[br_ind], res_summary_dict[br_arr[br_ind]]["$(i)"]["frequency (Hz)"][1])
                     #push!(size_obj_n[br_ind], range_t[i])
                  end
            end
      end

      # string = JSON.json(res_summary_dict)
      # open("test.json", "w") do f
      #     write(f, string)
      # end

      #size_obj_n = size(range_t, 1) - size_obj
      # below are the parts of plotting
      #println(range_t)
      #println(objval)

      # plot if the plot choice is "single", which means we plot the average optimal values and frequency
      # versus the branch numbers.
      if (plot_choice == "single")
            gr()

            # plot for the optimal cost

            # p = bar(size_obj, objval[1],  color = :blue,  linecolor = :transparent, title = "optimal result: br$(br_arr[1])",
            #           xlabel = "time/h", ylabel = "optimal cost", titlefontsize=20,
            #           right_margin = 10px)
            #          #xtickfontsize=18,ytickfontsize=18,
            # plot!(size_obj_n, objval_n[1], color = :red, seriestype = :scatter)
            # if ((num_br - 1) > 0)
            #       for br_ind = 2:num_br
            #             plot!(size_obj, objval[br_ind], color = :green, seriestype = :line)
            #             plot!(size_obj_n, objval_n[br_ind], color = :yellow, seriestype = :line)
            #       end
            # end

            # plot for the optimal frequency
            p2 = plot(size_obj, obj_freq[1], color = :blue, seriestype = :line, title = "optimal frequency: br$(br_arr[1])",
                     xlabel = "time/h", ylabel = "optimal frequency", titlefontsize=20,
                     right_margin = 10px, labels = ["feasible" "infeasible"])
            plot!(size_obj_n, obj_freq_n[1], color = :red, seriestype = :scatter,
                  markersize = 2.5)
            if ((num_br - 1) > 0)
                  for br_ind = 2:num_br
                        plot!(size_obj, obj_freq[br_ind], color = :green, seriestype = :line)
                        plot!(size_obj_n, obj_freq_n[br_ind], color = :blue, seriestype = :line)
                  end
            end

            # get the data difference compared to base case and store to array
            base_diff = Array{Float64, 1}()
            base_diff_percent = Array{Float64, 1}()
            objval_all_mod = Array{Float64, 1}()

            number_bins = 30
            total_cost_improve = 0
            total_cost_base = 0

            # FIXME get the max improve rate
            max_improve = 0;

            for i = 1:size(range_t, 1)
                  push!(base_diff, objval_base[i] - objval_all[1][i])
                  push!(objval_all_mod, objval_all[1][i]-25000)
                  push!(base_diff_percent, (objval_base[i] - objval_all[1][i])/objval_base[i])
                  total_cost_improve += (objval_base[i] - objval_all[1][i]);
                  if ((objval_base[i] - objval_all[1][i]) < 0)
                        println("time point $(i) is not right.")
                  end

                  # calculate the total cost of the base case
                  total_cost_base += objval_base[i];
            end

            max_base_diff_percent = maximum(base_diff_percent)
            min_base_diff_percent = minimum(base_diff_percent)
            println("The maximum percent of difference is $(max_base_diff_percent)")

            total_improve_rate = total_cost_improve/total_cost_base
            #bins_use=range(min_base_diff_percent,max_base_diff_percent,length=number_bins)
            bins=range(min_base_diff_percent,max_base_diff_percent,length=number_bins)

            base_comp_data = [base_diff objval_all[1]]
            base1 = JSON.json(base_comp_data)
            open("time_series_out/opt_res_plot_single_10_(1.1.1__1.1.3).json", "w") do f
              write(f, base1)
            end
            # zeros(Float64, size(range_t, 1), 2)
            # for i = 1:size(range_t, 1)
            #       push!(base_diff, objval_base[i] - objval_all[1][i])
            #       base_comp_data[i][1] = objval_all[1][i]
            #       base_comp_data[i][2] = base_diff[i]
            # end

            p1 = groupedbar(base_comp_data, bar_position = :stack, bar_width=0.7, linecolor = :transparent,
                        title = "optimal value VS base: br$(br_arr[1])",
                      xlabel = "time/h", ylabel = "opt val diff", titlefontsize=20,
                      right_margin = 10px)
            # p3 = plot(size_obj_all, base_diff, color = :yellow, seriestype = :bar, title = "optimal value VS base",
            #          xlabel = "time/h", ylabel = "optimal value difference", right_margin = 10px, labels = ["feasible" "infeasible"])

            # combine two plots together on a single figure


            p4 = bar(size_obj_all, base_diff_percent, line_color = :transparent, title = "Rate of improvement: br$(br_arr[1])",
                        linecolor = :transparent, xlabel = "time/h", ylabel = "rate improved", titlefontsize=20,
                        right_margin = 10px)

            p5 = histogram(base_diff_percent, bins = bins, linecolor = :transparent, yaxis=(:log10), title = "Num of hours: br$(br_arr[1])",
                        xlabel = "rate of improvements (cost reduceed/base cost)", ylabel = "amount of hours", titlefontsize=20,
                        right_margin = 10px)

            p_result = plot(p1, p2, layout = (2,1), legend = false)

            savefig(p_result, "$(output_folder)/opt_res_plot_single_$(br_arr[1])_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")

            p_improve = plot(p4, p5, layout = (2,1), legend = false)

            savefig(p_improve, "$(output_folder)/opt_improve_single_$(br_arr[1])_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")

            println("the current total improvement rate is $(total_improve_rate)")
      end

      # plot if the plot choice is "compare", which means we plot the average optimal values and frequency
      # versus the time steps (the comparison between different ).
      if (plot_choice == "compare")
            #objval_ave_dic = Dict()
            objval_ave = Array{Float64, 1}()
            opt_f_ave = Array{Float64, 1}()
            # objval_ave_dic[1] = Array{String, 1}()
            # objval_ave_dic[2] = Array{Float64, 1}()

            # the base value to help make the plot easy to analyze ( show the differences between the different cases)
            base_val_plot = 25000
            for br_ind = 1:num_br
                  # for i in 1:size()
                  # push!(objval_ave_dic[1], br_arr[br_ind])
                  # push!(objval_ave_dic[2], sum(objval[br_ind])/size(objval[br_ind], 1))
                  push!(objval_ave, (sum(objval[br_ind])/size(objval[br_ind], 1)) - base_val_plot)
                  push!(opt_f_ave, (sum(obj_freq[br_ind])/size(obj_freq[br_ind], 1)))
                  #end
            end
            #sort(collect(objval_ave_dic), by=x->x[2])
            ind = sortperm(objval_ave)
            println(ind)

            objval_order = Array{Float64, 1}()
            subnet_order = Array{Int64, 1}()
            for i = 1:num_br
                  push!(subnet_order, br_arr_raw[ind[i]])
                  push!(objval_order, objval_ave[ind[i]])
            end
            println(subnet_order)
            println(objval_order)
            println("result is above")

            net_order = JSON.json(subnet_order)
            val_order = JSON.json(objval_order)
            open("$(output_folder)/opt_data_comp_$(num_br)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
                  write(f, net_order)
                  write(f, "\n")
                  write(f, val_order)
            end
            # string = JSON.json(res_summary_dict)
            # open("test.json", "w") do f
            #     write(f, string)
            # end

            gr()
            # p1 = plot(br_arr[ind], objval_ave[ind],  color = :blue, seriestype = :bar, title = "partial optimal result plot ($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en))",
            #          xlabel = "subnet number", ylabel = "opt_val - $(base_val_plot)", xtickfontsize=18,ytickfontsize=18,titlefontsize=20,right_margin = 10px, legend = false)
            # p2 = plot(br_arr[ind], opt_f_ave[ind], color = :blue, seriestype = :bar, title = "partial optimal frequency plot ($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en))",
            #          xlabel = "subnet number", ylabel = "optimal f", xtickfontsize=18,ytickfontsize=18,titlefontsize=20, right_margin = 10px, legend = false)
            #
            # p_all = plot(p1, p2, layout = (2,1), legend = false)
            # savefig(p_all, "$(output_folder)/opt_res_plot_multi_comp_$(num_br)_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")

            # get the data difference compared to base case and store to array
            base_diff = Dict()
            base_diff_percent = Dict()
            base_diff_percent_posi = Dict()
            base_diff_percent_all = Dict()
            objval_all_mod = Dict()

            for br_ind = 1:num_br
                  base_diff[br_ind] = Array{Float64, 1}()
                  base_diff_percent[br_ind] = Array{Float64, 1}()
                  base_diff_percent_posi[br_ind] = Array{Float64, 1}()
                  base_diff_percent_all[br_ind] = Array{Float64, 1}()
                  objval_all_mod[br_ind] = Array{Float64, 1}()
            end

            number_bins = 30
            total_cost_improve = 0
            total_cost_base = 0

            # FIXME get the max improve rate
            max_improve = 0;
            for br_ind = 1:num_br
                  for i = 1:size(range_t, 1)
                        push!(base_diff[br_ind], objval_base[i] - objval_all[br_ind ][i])
                        push!(objval_all_mod[br_ind], objval_all[br_ind ][i]-25000)
                        push!(base_diff_percent[br_ind], (objval_base[i] - objval_all[br_ind ][i])/objval_base[i])
                        if ((objval_base[i] - objval_all[br_ind ][i])/objval_base[i])>0
                              push!(base_diff_percent_posi[br_ind], (objval_base[i] - objval_all[br_ind ][i])/objval_base[i])
                              push!(base_diff_percent_all[br_ind], (objval_base[i] - objval_all[br_ind ][i])/objval_base[i])
                        else
                              push!(base_diff_percent_all[br_ind], 0.0)
                        end
                        #total_cost_improve += (objval_base[i] - objval_all[br_ind ][i]);
                        if ((objval_base[i] - objval_all[br_ind][i]) < 0)
                              println("br$(br_ind), time point $(i) is not right.")
                        end

                        # calculate the total cost of the base case
                        #total_cost_base += objval_base[i];
                  end
            end


            max_base_diff_percent = 0;
            for br_ind = 1:num_br
                  for i = 1:size(base_diff_percent[br_ind], 1)
                        if max_base_diff_percent < base_diff_percent[br_ind][i]
                              max_base_diff_percent = base_diff_percent[br_ind][i]
                        else
                              #
                        end
                  end
            end
            # min_base_diff_percent = minimum(base_diff_percent)
            println("The maximum percent of difference is $(max_base_diff_percent)")

            #total_improve_rate = total_cost_improve/total_cost_base
            #bins_use=range(min_base_diff_percent,max_base_diff_percent,length=number_bins)
            bins=range(0,max_base_diff_percent,length=number_bins)

            # base_comp_data = Dict()
            # for br_ind = 1:num_br
            #       push!(base_comp_data, [base_diff[br_ind] objval_all[1][br_ind]])
            # end
            # base1 = JSON.json(base_diff_percent)
            # open("opt_res_plot_single_10_(1.1.1__12.31.24).json", "w") do f
            #   write(f, base1)
            # end
            # zeros(Float64, size(range_t, 1), 2)
            # for i = 1:size(range_t, 1)
            #       push!(base_diff, objval_base[i] - objval_all[1][i])
            #       base_comp_data[i][1] = objval_all[1][i]
            #       base_comp_data[i][2] = base_diff[i]
            # end

            p3 = bar(size_obj_all, base_diff_percent_all[1], line_color = :transparent, title = "rate of improvement: br$(br_arr[1])",
                       linecolor = :transparent, xlabel = "time/h", ylabel = "rate improved", titlefontsize=20,
                       right_margin = 10px, )
            p4 = bar(size_obj_all, base_diff_percent_all[2], line_color = :transparent, title = "rate of improvement: br$(br_arr[2])",
                       linecolor = :transparent, xlabel = "time/h", ylabel = "rate improved", titlefontsize=20,
                       right_margin = 10px)
            p5 = bar(size_obj_all, base_diff_percent_all[3], line_color = :transparent, title = "rate of improvement: br$(br_arr[3])",
                       linecolor = :transparent, xlabel = "time/h", ylabel = "rate improved", titlefontsize=20,
                       right_margin = 10px)
            p6 = bar(size_obj_all, base_diff_percent_all[4], line_color = :transparent, title = "rate of improvement: br$(br_arr[4])",
                        linecolor = :transparent, xlabel = "time/h", ylabel = "rate improved", titlefontsize=20,
                        right_margin = 10px)

            p7 = histogram(base_diff_percent_posi[1], bins = bins, linecolor = :transparent, yaxis=(:log10), title = "br$(br_arr[1])",
                       xlabel = "rate of improvements (cost reduceed/base cost)", ylabel = "amount of hours", titlefontsize=20,
                       right_margin = 10px, xlim = max_base_diff_percent)
            p8 = histogram(base_diff_percent_posi[2], bins = bins, linecolor = :transparent, yaxis=(:log10), title = "br$(br_arr[2])",
                       xlabel = "rate of improvements (cost reduceed/base cost)", ylabel = "amount of hours", titlefontsize=20,
                       right_margin = 10px, xlim = max_base_diff_percent)
            p9 = histogram(base_diff_percent_posi[3], bins = bins, linecolor = :transparent, yaxis=(:log10), title = "br$(br_arr[3])",
                       xlabel = "rate of improvements (cost reduceed/base cost)", ylabel = "amount of hours", titlefontsize=20,
                       right_margin = 10px, xlim = max_base_diff_percent)
            p10 = histogram(base_diff_percent_posi[4], bins = bins, linecolor = :transparent, yaxis=(:log10), title = "br$(br_arr[4])",
                       xlabel = "rate of improvements (cost reduceed/base cost)", ylabel = "amount of hours", titlefontsize=20,
                       right_margin = 10px, xlim = max_base_diff_percent)
            #Plots.link_axes!()
            p_first = plot(p3, p4, p5, p6, layout = (4,1), link = :all,legend = false, size = (500, 800))
            savefig(p_first, "$(output_folder)/opt_improve_plot_comp_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")

            # title = "amount of hours with each rate of improvements"
            p_second = plot(p7, p8, p9, p10, layout = (4,1), link = :x,legend = false, size = (500, 800) )
            savefig(p_second, "$(output_folder)/opt_rate_plot_comp_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).pdf")
            #for br_ind = 1:num_br
            #end
      end

      println("The objective value of the current period")
end
