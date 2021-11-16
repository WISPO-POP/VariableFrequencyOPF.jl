# function to parse the time-series data from the given folder and output a dictionary
# implementing the data into the  original RTS_GMLC network.
#
# function parameters:
######################################################################################
# month_st: the month to start
# day_st: the day to start
# period_st: the hour to start
# month_en: the month that ends parsing
# day_en: the month that ends parsing
# period_en: the month that ends parsing (here the periods need to be chosen corresponding to the data set use in the future)
# folder: the folder containing the time-sereis data and subnetworks.csv(For example I set it to be time_series)

function hour_parse(month_st, day_st, period_st, month_en, day_en, period_en, folder)

    # set the time range
    start_t = DateTime(2020,month_st,day_st,period_st)
    end_t = DateTime(2020,month_en,day_en,period_en)
    range_t = start_t:Hour(1):end_t

    # direct to the current directory
    # println("$(@__DIR__)")
    cur_dir_split = split(rstrip(folder, '/'), "/")
    cur_dir_split = cur_dir_split[cur_dir_split .!= ""]
    cur_dir_new = cur_dir_split[1:end-3]
    # cur_dir = join([("$i/") for i in cur_dir_new])
    cur_dir = pwd()

    # for the base structure of network, parse all the subnetwork files
    subnet_file = CSV.read("$(folder)/subnetworks.csv", DataFrame)
    subnet_file_1 = subnet_file[!, "file"][1]
    case = Dict()
    for subnet in eachrow(subnet_file)
        case[subnet.file] = parse_file("$(folder)/$(subnet.file)")
    end


    # Set the generator minimum active power limits to zero for surrent stage (release the constraints)
    for (subnet_file, subnet) in case
       for (gen_idx, gen) in subnet["gen"]
          gen["pmin"] = 0
       end
    end

    # read the time-series data from the folder
    hour_csp_ori = CSV.read("$(cur_dir)/time_series/CSP/DAY_AHEAD_Natural_Inflow.csv", DataFrame)
    hour_hydro_ori = CSV.read("$(cur_dir)/time_series/Hydro/DAY_AHEAD_hydro.csv", DataFrame)
    hour_load_ori = CSV.read("$(cur_dir)/time_series/Load/DAY_AHEAD_regional_Load.csv", DataFrame)
    hour_pv_ori = CSV.read("$(cur_dir)/time_series/PV/DAY_AHEAD_pv.csv", DataFrame)

    # here didn't include reserve data for now (now optimizations on different time steps are independent)
    hour_rtpv_ori = CSV.read("$(cur_dir)/time_series/RTPV/DAY_AHEAD_rtpv.csv", DataFrame)
    hour_wind_ori = CSV.read("$(cur_dir)/time_series/WIND/DAY_AHEAD_wind.csv", DataFrame)

    hour_wind = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_wind_ori)
    hour_pv = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_pv_ori)
    hour_csp = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_csp_ori)
    hour_rtpv = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_rtpv_ori)
    hour_load = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_load_ori)
    hour_hydro = filter(row -> DateTime(row.Year, row.Month, row.Day, row.Period) in range_t, hour_hydro_ori)

    wind_names = names(hour_wind)[5:end]
    pv_names = names(hour_pv)[5:end]
    csp_names = names(hour_csp)[5:end]
    rtpv_names = names(hour_rtpv)[5:end]
    #load_names = names(hour_load)[5:end]
    hydro_names = names(hour_hydro)[5:end]
    #input_csp = filter()

    # set the load in the three areas
    total_load = Dict(1=>0.0, 2=>0.0, 3=>0.0)
    for (id, load) in case[subnet_file_1]["load"]
        bus= case[subnet_file_1]["bus"]["$(load["load_bus"])"]
        total_load[bus["area"]] += load["pd"]*case[subnet_file_1]["baseMVA"]
    end

    hour_data = Dict()
    # made a copy of original network at each time step and make modifications using time-series data.
    for i in 1:size(hour_load, 1)
        load_data = hour_load[i,:]
        for subnet in eachrow(subnet_file)
            # file name and index of current subnetwork file
            name = subnet.file
            hour_data[i] = deepcopy(case)
            hour_data[i][name]["year"] = load_data.Year
            hour_data[i][name]["month"] = load_data.Month
            hour_data[i][name]["day"] = load_data.Day
            hour_data[i][name]["period"] = load_data.Period

        end
        hour_data[i][subnet_file_1]["ori_load"] = Dict(1=>load_data[Symbol(1)], 2=>load_data[Symbol(2)], 3=>load_data[Symbol(3)])    end

    # here distribute the power over the 3 areas
    for (id, name) in hour_data
        #for (ind, network) in name
            for (load_id, load) in name[subnet_file_1]["load"]
                #if haskey(network, "ori_load")
                    area = name[subnet_file_1]["bus"]["$(load["load_bus"])"]["area"]
                    scale = name[subnet_file_1]["ori_load"][area]/total_load[area]
                    load["pd"] = load["pd"]*scale
                    load["qd"] = load["qd"]*scale
                #end
            end
        #end
    end

    # here change all the data of the points according to time-serires data of PV,
    for (id, name) in hour_data
        #for (ind, network) in name
            for (gen_id, gen) in name[subnet_file_1]["gen"]
                #for subnet in eachrow(subnet_file)
                    #if haskey(gen, "name")
                        if gen["name"] in wind_names
                            gen["pmax"] = hour_wind[id, gen["name"]]/case[subnet_file_1]["baseMVA"]
                        end
                        if gen["name"] in pv_names
                            gen["pmax"] = hour_pv[id, gen["name"]]/case[subnet_file_1]["baseMVA"]
                        end
                        if gen["name"] in csp_names
                            gen["pmax"] = hour_csp[id, gen["name"]]/case[subnet_file_1]["baseMVA"]
                        end
                        if gen["name"] in rtpv_names
                            gen["pmax"] = hour_rtpv[id, gen["name"]]/case[subnet_file_1]["baseMVA"]
                        end
                    #else
                    #    gen["pmax"] =
                    #end
                #end
            end
        #end
    end

    # write the data to a specified JSON file for debug
    string = JSON.json(hour_data)
    open("$(folder)/RTS_GMLC_($(month_st).$(day_st).$(period_st)__$(month_en).$(day_en).$(period_en)).json", "w") do f
        write(f, string)
    end

    time_size = size(hour_load, 1)
    return hour_data
end
