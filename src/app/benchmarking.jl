

function compare_power_flows(first_network, second_network, plot_dir)
    if split(lowercase(split(first_network, "/")[end]), '.')[end] == "json"
        first_mn_data = JSON.parsefile(first_network)
    else
        first_mn_data = PowerModels.parse_file(first_network)
    end
    # println("Finished parsing the first network")
    if split(lowercase(split(second_network, "/")[end]), '.')[end] == "json"
        second_mn_data = JSON.parsefile(second_network)
    else
        second_mn_data = PowerModels.parse_file(second_network)
    end
    # println("Finished parsing the second network")

    first_ref = PowerModels.build_ref(first_mn_data)[:nw]
    # println("Finished building ref for the first network")
    second_ref = PowerModels.build_ref(second_mn_data)[:nw]
    # println("Finished building ref for the second network")

    table_string = ""
    for (subnet_idx, ref_subnet) in first_ref
        println("subnet_idx: $subnet_idx")
        if (subnet_idx) == 0 && !(subnet_idx in keys(second_ref))
            subnet_idx = 1
        end
        if (subnet_idx) == 1 && !(subnet_idx in keys(second_ref))
            subnet_idx = 0
        end
        # total, max, min, plot all
        gen_compared_idx = Array{Number}(undef, length(ref_subnet[:gen]))
        gen_pg1 = Array{Float64}(undef, length(ref_subnet[:gen]))
        gen_qg1 = Array{Float64}(undef, length(ref_subnet[:gen]))
        gen_vm1 = Array{Float64}(undef, length(ref_subnet[:gen]))
        gen_pg2 = Array{Float64}(undef, length(ref_subnet[:gen]))
        gen_qg2 = Array{Float64}(undef, length(ref_subnet[:gen]))
        gen_vm2 = Array{Float64}(undef, length(ref_subnet[:gen]))
        for (i,(gen_i,gen)) in enumerate(ref_subnet[:gen])
            if ref_subnet[:gen][gen_i]["gen_status"] == 0
                gen_pg1[i] = NaN
                gen_qg1[i] = NaN
                gen_vm1[i] = NaN
                gen_pg2[i] = NaN
                gen_qg2[i] = NaN
                gen_vm2[i] = NaN
                gen_compared_idx[i] = NaN
            else
                gen_pg1[i] = ref_subnet[:gen][gen_i]["pg"]
                gen_qg1[i] = ref_subnet[:gen][gen_i]["qg"]
                gen_vm1[i] = ref_subnet[:gen][gen_i]["vg"]
                gen_pg2[i] = second_ref[subnet_idx][:gen][gen_i]["pg"]
                gen_qg2[i] = second_ref[subnet_idx][:gen][gen_i]["qg"]
                gen_vm2[i] = second_ref[subnet_idx][:gen][gen_i]["vg"]
                gen_compared_idx[i] = gen_i
            end
        end
        filter!(e->e≠NaN,gen_pg1)
        filter!(e->e≠NaN,gen_qg1)
        filter!(e->e≠NaN,gen_vm1)
        filter!(e->e≠NaN,gen_pg2)
        filter!(e->e≠NaN,gen_qg2)
        filter!(e->e≠NaN,gen_vm2)
        filter!(e->e≠NaN,gen_compared_idx)
        gen_pg_compared = gen_pg2 - gen_pg1
        gen_qg_compared = gen_qg2 - gen_qg1
        gen_vm_compared = gen_vm2 - gen_vm1

        # bus_vm_compared = Array{Float64}(undef, length(ref_subnet[:bus]))
        # bus_va_compared = Array{Float64}(undef, length(ref_subnet[:bus]))
        bus_compared_idx = Array{Number}(undef, length(ref_subnet[:bus]))
        bus_vm1 = Array{Float64}(undef, length(ref_subnet[:bus]))
        bus_va1 = Array{Float64}(undef, length(ref_subnet[:bus]))
        bus_vm2 = Array{Float64}(undef, length(ref_subnet[:bus]))
        bus_va2 = Array{Float64}(undef, length(ref_subnet[:bus]))
        for (i,(bus_i,bus)) in enumerate(ref_subnet[:bus])
            if bus["bus_type"] ∉ [1,2,3]
                bus_vm1[i] = NaN
                bus_va1[i] = NaN
                bus_vm2[i] = NaN
                bus_va2[i] = NaN
                bus_compared_idx[i] = NaN
            else
                bus_vm1[i] = ref_subnet[:bus][bus_i]["vm"]
                bus_va1[i] = ref_subnet[:bus][bus_i]["va"]
                bus_vm2[i] = second_ref[subnet_idx][:bus][bus_i]["vm"]
                bus_va2[i] = second_ref[subnet_idx][:bus][bus_i]["va"]
                bus_compared_idx[i] = bus_i
            end
        end
        filter!(e->e≠NaN,bus_vm1)
        filter!(e->e≠NaN,bus_va1)
        filter!(e->e≠NaN,bus_vm2)
        filter!(e->e≠NaN,bus_va2)
        filter!(e->e≠NaN,bus_compared_idx)
        bus_vm_compared = bus_vm2 - bus_vm1
        bus_va_compared = bus_va2 - bus_va1


        branch_compared_idx = Array{Number}(undef, length(ref_subnet[:branch]))
        branch_pt1 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_pf1 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_qt1 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_qf1 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_pt2 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_pf2 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_qt2 = Array{Float64}(undef, length(ref_subnet[:branch]))
        branch_qf2 = Array{Float64}(undef, length(ref_subnet[:branch]))
        for (i,(branch_i,branch)) in enumerate(ref_subnet[:branch])
            if ("pt" ∉ keys(branch)) || ("pt" ∉ keys(second_ref[subnet_idx][:branch][branch_i]))
                branch_pt1[i] = NaN
                branch_pf1[i] = NaN
                branch_qt1[i] = NaN
                branch_qf1[i] = NaN
                branch_pt2[i] = NaN
                branch_pf2[i] = NaN
                branch_qt2[i] = NaN
                branch_qf2[i] = NaN
                branch_compared_idx[i] = NaN
            else
                branch_pt1[i] = ref_subnet[:branch][branch_i]["pt"]
                branch_pf1[i] = ref_subnet[:branch][branch_i]["pf"]
                branch_qt1[i] = ref_subnet[:branch][branch_i]["qt"]
                branch_qf1[i] = ref_subnet[:branch][branch_i]["qf"]
                branch_pt2[i] = second_ref[subnet_idx][:branch][branch_i]["pt"]
                branch_pf2[i] = second_ref[subnet_idx][:branch][branch_i]["pf"]
                branch_qt2[i] = second_ref[subnet_idx][:branch][branch_i]["qt"]
                branch_qf2[i] = second_ref[subnet_idx][:branch][branch_i]["qf"]
                branch_compared_idx[i] = branch_i
            end
        end
        filter!(e->e≠NaN,branch_pt1)
        filter!(e->e≠NaN,branch_pf1)
        filter!(e->e≠NaN,branch_qt1)
        filter!(e->e≠NaN,branch_qf1)
        filter!(e->e≠NaN,branch_pt2)
        filter!(e->e≠NaN,branch_pf2)
        filter!(e->e≠NaN,branch_qt2)
        filter!(e->e≠NaN,branch_qf2)
        filter!(e->e≠NaN,branch_compared_idx)
        branch_pt_compared = branch_pt2 - branch_pt1
        branch_pf_compared = branch_pf2 - branch_pf1
        branch_qt_compared = branch_qt2 - branch_qt1
        branch_qf_compared = branch_qf2 - branch_qf1


        GR.inline("pdf")

        output_dir = "$(plot_dir)/subnet$(subnet_idx)"
        if !isdir(output_dir)
            mkpath(output_dir)
        end
        upscale = 2 #upscaling in resolution
        fntsm = font("serif", pointsize=round(8.0*upscale))
        fntlg = font("serif", pointsize=round(12.0*upscale))
        default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
        default(size=(800*upscale,600*upscale)) #Plot canvas size

        gr()

        plot_data = [gen_pg_compared, gen_qg_compared,
                     bus_vm_compared, bus_va_compared,
                     branch_pt_compared, branch_pf_compared, branch_qt_compared, branch_qf_compared
                     ]
        raw_data = [gen_pg1,
                    gen_qg1,
                    bus_vm1,
                    bus_va1,
                    branch_pt1,
                    branch_pf1,
                    branch_qt1,
                    branch_qf1
                    ]
        plot_idx = [gen_compared_idx, gen_compared_idx,
                    bus_compared_idx, bus_compared_idx,
                    branch_compared_idx, branch_compared_idx, branch_compared_idx, branch_compared_idx
                    ]
        plot_labels = ["gen_pg", "gen_qg",
                       "bus_vm", "bus_va",
                       "branch_pt", "branch_pf", "branch_qt", "branch_qt"
                       ]

        for (i,series) in enumerate(plot_data)


            series_idx = plot_idx[i]

            (max_val, max_i) = findmax(series)
            (min_val, min_i) = findmin(series)
            idx_max = series_idx[max_i]
            idx_min = series_idx[min_i]

            # tol = 1e-3
            # worst = series[abs.(series).>tol]
            # idx_worst = series_idx[abs.(series).>tol]
            perm_worst = sortperm(abs.(series), rev=true)
            ten_worst = series[perm_worst][1:10]
            idx_ten_worst = series_idx[perm_worst][1:10]
            percent = ten_worst ./ raw_data[i][perm_worst][1:10]

            result_string = "$(plot_labels[i])\n==========\nMaximum difference: $(maximum(series))\nMinimum difference: $(minimum(series))\nMean absolute difference: $(mean(abs.(series)))\n"*
                            "biggest differences: $ten_worst\nat indices: $idx_ten_worst\npercent difference = $percent\n"

            println(result_string)

            open("$output_dir/comparison_log.txt", "a") do f
                write(f, result_string)
            end

            table_string = "$table_string,$(max_val),$(min_val),$(mean(abs.(series)))"

            perm = sortperm(series_idx)
            x_sorted = series_idx[perm]
            y_sorted = series[perm]
            series_label = plot_labels[i]
            plt = plot(1:length(x_sorted), y_sorted,
                label=series_label,
                legend=true,
                left_margin=(10*upscale)*mm,
                right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
                linetype=:scatter,
                marker = (:dot, 1.5*upscale, 0.6, :green, stroke(0))
            )
            xlabel!(plt, "index")
            ylabel!(plt, series_label)

            savefig(plt,"$(output_dir)/$(series_label).pdf")

            bar_plot = false
            if bar_plot
                plt = bar(x_sorted, y_sorted,
                    label=series_label,
                    legend=false,
                    left_margin=(10*upscale)*mm,
                    right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm
                )
                xlabel!(plt, "index")
                ylabel!(plt, series_label)
                # savefig(p,"$(folder)/$(y_label) vs $(x_label).pdf")
                if !isdir(output_dir)
                    mkpath(output_dir)
                end
                # println("saving plot at $(output_folder)/plots/$plotdir/$(y_label) vs $(x_label).pdf")
                # display(plt)
                savefig(plt,"$(output_dir)/$(series_label)_bar.pdf")
            end
        end

        plot_raw_data = [[gen_pg1, gen_pg2],
                         [gen_qg1, gen_qg1],
                         [bus_vm1, bus_vm2],
                         [bus_va1, bus_va2]
                         ]
        plot_idx = [gen_compared_idx,
                    gen_compared_idx,
                    bus_compared_idx,
                    bus_compared_idx
                    ]
        plot_labels = ["gen_pg values",
                       "gen_qg values",
                       "bus_vm values",
                       "bus_va values"
                       ]
        for (i,series) in enumerate(plot_raw_data)
            series_idx = plot_idx[i]
            perm = sortperm(series_idx)
            x_sorted = series_idx[perm]
            series_label = plot_labels[i]
            y1_sorted = series[1][perm]
            plt = plot(1:length(x_sorted), y1_sorted,
                label="solution 1",
                legend=true,
                left_margin=(10*upscale)*mm,
                right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
                linetype=:scatter,
                marker = (:dot, 1.5*upscale, 0.6, :blue, stroke(0))
            )
            y2_sorted = series[2][perm]
            plt = plot!(plt,1:length(x_sorted), y2_sorted,
                label="solution 2",
                legend=true,
                left_margin=(10*upscale)*mm,
                right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
                linetype=:scatter,
                marker = (:dot, 1.5*upscale, 0.6, :red, stroke(0))
            )
            xlabel!(plt, "index")
            ylabel!(plt, series_label)

            savefig(plt,"$(output_dir)/$(series_label).pdf")
        end
    end
    return table_string
end
