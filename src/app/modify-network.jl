"""
    function upgrade_branches(
       base_network::String,
       output_location::String,
       fbase;
       indices=[],
       output_type="input"
       )
Creates a folder of network data for the network `base_network` with one line converted to LFAC, one for each index in `indices`, or if `indices` is empty, for every non-transformer branch in the network.
"""
function upgrade_branches(
   base_network::String,
   output_location::String,
   fbase;
   subnet_params=Dict(),
   interface_params=Dict(),
   indices=[],
   output_type="input",
   noloss=false
   )
   filename = split(base_network, "/")[end]
   println("$filename")
   filetype = split(lowercase(filename), '.')[end]
   base_name = filename[1:(end-length(filetype)-1)]
   (base_name, filetype) = splitext(filename)
   filetype = Unicode.normalize(filetype, casefold=true)
   fileext = filetype == ".m" ? filetype : ".json"
   if lowercase(output_type) == ".json"
      fileext = ".json"
   end
   println(fileext)
   base_dir = base_network[1:end-length(filename)]

   # println("base_network: $base_network")
   # println("base_dir: $base_dir")

   base_subnet_df = CSV.read("$base_dir/subnetworks.csv", DataFrame, copycols=true)

   # Subnet parameters
   if !("var_f" in keys(subnet_params))
      subnet_params["var_f"] = false
   end
   if !("fmin" in keys(subnet_params))
      subnet_params["fmin"] = fbase
   end
   if !("fmax" in keys(subnet_params))
      subnet_params["fmax"] = fbase
   end
   if !("var_f_lfac" in keys(subnet_params))
      subnet_params["var_f_lfac"] = true
   end
   if !("fbase_lfac" in keys(subnet_params))
      subnet_params["fbase_lfac"] = fbase
   end
   if !("fmin_lfac" in keys(subnet_params))
      subnet_params["fmin_lfac"] = 0.1
   end
   if !("fmax_lfac" in keys(subnet_params))
      subnet_params["fmax_lfac"] = 100.0
   end
   if :contingency_file in names(base_subnet_df)
      ctg_filename = base_subnet_df.contingency_file[1]
      subnet_df = DataFrame(
         index=[1,2],
         file=["$(base_name)$(fileext)", "lfac_$(base_name)$(fileext)"],
         variable_f=[subnet_params["var_f"], subnet_params["var_f_lfac"]],
         f_base=[fbase, subnet_params["fbase_lfac"]],
         f_min=[subnet_params["fmin"], subnet_params["fmin_lfac"]],
         f_max=[subnet_params["fmax"], subnet_params["fmax_lfac"]],
         contingency_file=[ctg_filename, "lfac_$(ctg_filename)"]
      )
      # subnet_df_fixf = DataFrame(
      #    index=[1,2],
      #    file=["$(base_name)$(fileext)", "lfac_$(base_name)$(fileext)"],
      #    variable_f=[subnet_params["var_f"], false],
      #    f_base=[fbase, fbase_lfac],
      #    f_min=[subnet_params["fmin"], subnet_params["fbase_lfac"]],
      #    f_max=[subnet_params["fmax"], subnet_params["fbase_lfac"]],
      #    contingency_file=[ctg_filename, "lfac_$(ctg_filename)"]
      # )
   else
      subnet_df = DataFrame(
         index=[1,2],
         file=["$(base_name)$(fileext)", "lfac_$(base_name)$(fileext)"],
         variable_f=[subnet_params["var_f"], subnet_params["var_f_lfac"]],
         f_base=[fbase, subnet_params["fbase_lfac"]],
         f_min=[subnet_params["fmin"], subnet_params["fmin_lfac"]],
         f_max=[subnet_params["fmax"], subnet_params["fmax_lfac"]]
      )
      # subnet_df_fixf = DataFrame(
      #    index=[1,2],
      #    file=["$(base_name)$(fileext)", "lfac_$(base_name)$(fileext)"],
      #    variable_f=[subnet_params["var_f"], false],
      #    f_base=[fbase, subnet_params["fbase_lfac"]],
      #    f_min=[subnet_params["fmin"], subnet_params["fbase_lfac"]],
      #    f_max=[subnet_params["fmax"], subnet_params["fbase_lfac"]]
      # )
   end

   data = PowerModels.parse_file(base_network)

   ctg_br_dict = Dict{Int64, Any}()


   if :contingency_file in names(subnet_df)
      ctg_list = parse_con_file(base_dir*"/"*subnet_df.contingency_file[1])

      for (ctg_idx,ctg) in enumerate(ctg_list)
         if ctg["component"] == "branch"
            circuit = parse(Int64, ctg["ckt"])

            br_idx = parse(Int64, sort(
               collect(keys(
                  filter(p->(
                     (last(p)["f_bus"]==ctg["i"] && last(p)["t_bus"]==ctg["j"])
                     || (last(p)["f_bus"]==ctg["j"] && last(p)["t_bus"]==ctg["i"])),
                     data["branch"]
                     )
                  )
               )
            )[circuit])

            println("br_idx: $(br_idx)")
            ctg_br_dict[br_idx] = ctg

         end
      end
   end

   # Converter limits and loss parameters in p.u.
   if !("imax" in keys(interface_params))
      interface_params["imax"] = 40.0
   end
   if !("vmax" in keys(interface_params))
      interface_params["vmax"] = 1.1
   end
   if !("c1" in keys(interface_params))
      interface_params["c1"] = noloss ? 0 : 1e-4
   end
   if !("c2" in keys(interface_params))
      interface_params["c2"] = noloss ? 0 : 1e-4
   end
   if !("c3" in keys(interface_params))
      interface_params["c3"] = noloss ? 0 : 1e-4
   end
   if !("sw1" in keys(interface_params))
      interface_params["sw1"] = noloss ? 0 : 1e-4
   end
   if !("sw2" in keys(interface_params))
      interface_params["sw2"] = noloss ? 0 : 1e-4
   end
   if !("sw3" in keys(interface_params))
      interface_params["sw3"] = noloss ? 0 : 1e-4
   end
   if !("M" in keys(interface_params))
      interface_params["M"] = 0.9
   end
   if !("smax" in keys(interface_params))
      interface_params["smax"] = 50.0
   end
   if !("R" in keys(interface_params))
      interface_params["R"] = 1.0e-5
   end
   if !("X" in keys(interface_params))
      interface_params["X"] = 1.0e-3
   end
   if !("G" in keys(interface_params))
      interface_params["G"] = 0.0
   end
   if !("B" in keys(interface_params))
      interface_params["B"] = 1.0e-4
   end
   if !("transformer" in keys(interface_params))
      interface_params["transformer"] = false
   end
   if !("tap" in keys(interface_params))
      interface_params["tap"] = 1.0
   end
   if !("shift" in keys(interface_params))
      interface_params["shift"] = 0.0
   end
   s_max = 100
   p_max = 0.0
   q_max = 0.0
   loss_param = 0.0
   lfac_vmin = 0.9
   lfac_vmax = 1.1
   # println(indices)
   for (i,(br_idx,branch)) in enumerate(data["branch"])
      lfac_ctg_br_dict = Dict{Int64, Any}()
      ctg_br_dict_tmp = deepcopy(ctg_br_dict)
      br_specified = ((length(indices) == 0) || (parse(Int64, br_idx) in indices)) # Defines whether or not the branch was specified as an input. Include all if empty set was specified.
      if (branch["br_status"]==1) && (!branch["transformer"]) && br_specified
         println("LFAC upgrade on branch $(branch["index"])")

         # iface_keys = ["index", "subnet_index", "bus"]
         # iface_types = [Int64, Int64, Int64]
         # # Add all other parameters in the interface_params dictionary
         # for (key,val) in keys(interface_params)
         #    push!(iface_keys, key)
         #    push!(iface_types, typeof(val))
         # end
         iface_df = DataFrame(index=Int64[],
            subnet_index=Int64[],
            bus=Int64[],
            imax=Float64[],
            vmax=Float64[],
            c1=Float64[],
            c2=Float64[],
            c3=Float64[],
            sw1=Float64[],
            sw2=Float64[],
            sw3=Float64[],
            M=Float64[],
            smax=Float64[],
            R=Float64[],
            X=Float64[],
            G=Float64[],
            B=Float64[],
            transformer=Bool[],
            tap=Float64[],
            shift=Float64[]
            )
         # println("sourceid: $(branch["source_id"])")
         if (length(branch["source_id"])>3) && (Unicode.normalize(branch["source_id"][4], casefold=true) == "sc") # is a series compensation branch
            seriescomp_bus = branch["sc_bus"]
            # println("seriescomp_bus: $seriescomp_bus")
            # Set two interface buses for base network
            subnet_index = 1
            base_f_bus = nothing
            base_t_bus = nothing
            next_f_bus = nothing
            next_t_bus = nothing
            lfac_next_branch = nothing
            if branch["f_bus"] == seriescomp_bus
               sc_f_bus = seriescomp_bus
               sc_t_bus = 2 # series compensation branch goes from seriescomp_bus to the t_bus in the LFAC network (always bus 2)
               base_t_bus = copy(branch["t_bus"])
               for (next_br_idx,next_branch) in data["branch"]
                  if next_branch["index"] != branch["index"] # exclude series compensation branch
                     if next_branch["f_bus"] == seriescomp_bus
                        base_f_bus = copy(next_branch["t_bus"])
                        lfac_next_branch = next_branch
                        next_f_bus = seriescomp_bus
                        next_t_bus = 1 # existing branch goes from seriescomp_bus to the f_bus in the LFAC network (bus 1)
                        println("Series compensation. Including connected branch $(lfac_next_branch["index"]) in LFAC network.")
                        break
                     elseif next_branch["t_bus"] == seriescomp_bus
                        base_f_bus = copy(next_branch["f_bus"])
                        lfac_next_branch = next_branch
                        next_t_bus = seriescomp_bus
                        next_f_bus = 1 # existing branch goes to seriescomp_bus from the f_bus in the LFAC network (bus 1)
                        println("Series compensation. Including connected branch $(lfac_next_branch["index"]) in LFAC network.")
                        break
                     end
                  end
               end
            elseif branch["t_bus"] == seriescomp_bus
               sc_t_bus = seriescomp_bus
               sc_f_bus = 1 # series compensation branch goes to seriescomp_bus from the f_bus in the LFAC network (always bus 1)
               base_f_bus = copy(branch["f_bus"])
               for (next_br_idx,next_branch) in data["branch"]
                  if next_branch["index"] != branch["index"] # exclude series compensation branch
                     if next_branch["f_bus"] == seriescomp_bus
                        base_t_bus = copy(next_branch["t_bus"])
                        lfac_next_branch = next_branch
                        next_f_bus = seriescomp_bus
                        next_t_bus = 2 # existing branch goes from seriescomp_bus to the t_bus in the LFAC network (bus 2)
                        println("Series compensation. Including connected branch $(lfac_next_branch["index"]) in LFAC network.")
                        break
                     elseif next_branch["t_bus"] == seriescomp_bus
                        base_t_bus = copy(next_branch["f_bus"])
                        lfac_next_branch = next_branch
                        next_t_bus = seriescomp_bus
                        next_f_bus = 2 # existing branch goes to seriescomp_bus from the t_bus in the LFAC network (bus 2)
                        println("Series compensation. Including connected branch $(lfac_next_branch["index"]) in LFAC network.")
                        break
                     end
                  end
               end
            else
               throw(ArgumentError("The series compensation bus $seriescomp_bus specified for branch $(branch["index"]) is not connected to the branch. f_bus=$f_bus and t_bus=$t_bus"))
            end



            lfac_buslookup = Dict(
               base_f_bus=>1,
               base_t_bus=>2,
               seriescomp_bus=>seriescomp_bus
            )

            # create output directory
            output_dir = "$output_location/br$(br_idx)_$(lfac_next_branch["index"])"
            if !isdir(output_dir)
               mkpath(output_dir)
            end

            # LFAC "from bus" interface
            iface_index = 1
            bus = base_f_bus
            interface_params["index"] = iface_index
            interface_params["subnet_index"] = subnet_index
            interface_params["bus"] = bus
            push!(iface_df, interface_params)
            f_area = copy(data["bus"]["$bus"]["area"])
            f_zone = copy(data["bus"]["$bus"]["zone"])

            # LFAC "to bus" interface
            iface_index = 2
            bus = base_t_bus
            interface_params["index"] = iface_index
            interface_params["subnet_index"] = subnet_index
            interface_params["bus"] = bus
            push!(iface_df, interface_params)
            t_area = copy(data["bus"]["$bus"]["area"])
            t_zone = copy(data["bus"]["$bus"]["zone"])

            for (bus_idx,bus) in data["bus"]
               bus["name"] = split(bus["name"], ";")[1]
            end
            println("series comp branch: $(branch["index"])")
            println("lfac next branch: $(lfac_next_branch["index"])")
            println("saving network at $output_dir/$(base_name)$(fileext)")
            # Disable branches and save network
            # Disabling branches is the only change to the base network.
            branch["br_status"] = 0
            lfac_next_branch["br_status"] = 0
            if fileext == ".m"
               io = open("$output_dir/$(base_name).m", "w");
               export_matpower(io, data)
               close(io)
            else
               stringnet = JSON.json(data)
               open("$output_dir/$(base_name)$(fileext)", "w") do f
                  write(f, stringnet)
               end
            end
            # Restore branch status
            branch["br_status"] = 1
            lfac_next_branch["br_status"] = 1

            # Create and save LFAC subnetwork
            lfac_case = Dict{String,Any}()
            lfac_case["name"] = data["name"]
            lfac_case["source_version"] = data["source_version"]
            lfac_case["baseMVA"] = data["baseMVA"]
            lfac_case["per_unit"] = true
            # Bus data
            lfac_case["bus"] = Dict{String, Any}(
               "1"=>Dict{String, Any}(
                  "bus_type"=>3,
                  "vmin"=>lfac_vmin,
                  "vmax"=>lfac_vmax,
                  "bus_i"=>1,
                  "index"=>1,
                  "va"=>0.0,
                  "vm"=>1.0,
                  "name"=>"Bus 1\tLF",
                  "area"=>f_area,
                  "zone"=>f_zone
               ),
               "2"=>Dict{String, Any}(
                  "bus_type"=>1,
                  "vmin"=>lfac_vmin,
                  "vmax"=>lfac_vmax,
                  "bus_i"=>2,
                  "index"=>2,
                  "va"=>0.0,
                  "vm"=>1.0,
                  "name"=>"Bus 2\tLF",
                  "area"=>t_area,
                  "zone"=>t_zone
               ),
               "$seriescomp_bus"=>Dict{String, Any}(
                  "bus_type"=>1,
                  "vmin"=>lfac_vmin,
                  "vmax"=>lfac_vmax,
                  "bus_i"=>seriescomp_bus,
                  "index"=>seriescomp_bus,
                  "va"=>0.0,
                  "vm"=>1.0,
                  "name"=>"SC Bus\tLF",
                  "area"=>data["bus"]["$seriescomp_bus"]["area"],
                  "zone"=>data["bus"]["$seriescomp_bus"]["zone"]
               )
            )
            # if "apply_ang_lim" in keys(data["bus"]["$seriescomp_bus"])
            #    lfac_case["bus"]["$seriescomp_bus"]["apply_ang_lim"] = data["bus"]["$seriescomp_bus"]["apply_ang_lim"]
            # end
            # Branch Data
            lfac_branch = deepcopy(branch)
            lfac_branch["f_bus"] = sc_f_bus
            lfac_branch["t_bus"] = sc_t_bus

            lfac_next_branch_copy = deepcopy(lfac_next_branch)
            lfac_next_branch_copy["f_bus"] = next_f_bus
            lfac_next_branch_copy["t_bus"] = next_t_bus
            # Change buses for alt angle limits to corresponding LFAC buses
            if "alt_ang_lim" in keys(lfac_branch)
               lfac_branch["alt_ang_lim"] = [lfac_buslookup[bus] for bus in lfac_branch["alt_ang_lim"]]
            end
            if "alt_ang_lim" in keys(lfac_next_branch_copy)
               lfac_next_branch_copy["alt_ang_lim"] = [lfac_buslookup[bus] for bus in lfac_next_branch_copy["alt_ang_lim"]]
            end

            lfac_case["branch"] = Dict{String, Any}(
               "$(lfac_branch["index"])"=>lfac_branch,
               "$(lfac_next_branch_copy["index"])"=>lfac_next_branch_copy
            )
            # Gen data
            lfac_case["gen"] = Dict{String, Any}(
               "1"=>Dict{String, Any}(
                  "gen_status"=>0,
                  "index"=>1,
                  "gen_bus"=>1,
                  "vg"=>1.0
               )
            )
            # Other data
            lfac_case["storage"] = Dict{String, Any}()
            lfac_case["switch"] = Dict{String, Any}()
            lfac_case["shunt"] = Dict{String, Any}()
            lfac_case["load"] = Dict{String, Any}()
            lfac_case["dcline"] = Dict{String, Any}()

            if fileext == ".m"
               io = open("$output_dir/lfac_$(base_name).m", "w");
               export_matpower(io, lfac_case)
               close(io)
            else
               stringnet = JSON.json(lfac_case)
               open("$output_dir/lfac_$(base_name)$(fileext)", "w") do f
                  write(f, stringnet)
               end
            end

         else # is not a series compensation branch

            # Check if branch is connected to a series compensation bus.
            # If so, skip the branch so that series compensated branches are not
            # split up in different subnetworks.
            sc_connected = false
            for (other_br_idx,other_branch) in data["branch"]
               # println("sourceid: $(other_branch["source_id"])")
               if (length(other_branch["source_id"])>3) && (Unicode.normalize(other_branch["source_id"][1], casefold=true) == "branch") && (Unicode.normalize(other_branch["source_id"][4], casefold=true) == "sc") # is a series compensation branch
                  # println("series compensation branch $(other_branch["index"])")
                  seriescomp_bus = other_branch["sc_bus"]
                  if (branch["f_bus"] == seriescomp_bus) || (branch["t_bus"] == seriescomp_bus)
                     sc_connected = true
                     break
                  end
               end
            end
            if sc_connected
               println("skipped branch $(branch["index"]) with series compensation")
               continue
            end
            # create output directory
            output_dir = "$output_location/br$(br_idx)"
            if !isdir(output_dir)
               mkpath(output_dir)
            end
            # Set two interface buses for base network
            subnet_index = 1
            iface_index = 1
            base_f_bus = branch["f_bus"]
            interface_params["index"] = iface_index
            interface_params["subnet_index"] = subnet_index
            interface_params["bus"] = base_f_bus
            push!(iface_df, interface_params)

            f_area = data["bus"]["$base_f_bus"]["area"]
            f_zone = data["bus"]["$base_f_bus"]["zone"]
            iface_index = 2
            base_t_bus = branch["t_bus"]
            interface_params["index"] = iface_index
            interface_params["subnet_index"] = subnet_index
            interface_params["bus"] = base_t_bus
            push!(iface_df, interface_params)
            t_area = data["bus"]["$base_t_bus"]["area"]
            t_zone = data["bus"]["$base_t_bus"]["zone"]
            for (bus_idx,bus) in data["bus"]
               if "name" in keys(bus)
                  bus["name"] = split(bus["name"], ";")[1]
               end
            end
            # Disable branch and save network
            branch["br_status"] = 0
            if fileext == ".m"
               io = open("$output_dir/$(base_name).m", "w");
               export_matpower(io, data)
               close(io)
            else
               stringnet = JSON.json(data)
               open("$output_dir/$(base_name)$(fileext)", "w") do f
                  write(f, stringnet)
               end
            end
            # Restore branch status
            branch["br_status"] = 1
            # Create and save LFAC subnetwork
            lfac_case = Dict{String,Any}()
            lfac_case["name"] = data["name"]
            lfac_case["source_version"] = data["source_version"]
            lfac_case["baseMVA"] = data["baseMVA"]
            lfac_case["per_unit"] = true
            # Bus data
            lfac_case["bus"] = Dict{String, Any}(
               "1"=>Dict{String, Any}(
                  "bus_type"=>3,
                  "vmin"=>lfac_vmin,
                  "vmax"=>lfac_vmax,
                  "bus_i"=>1,
                  "index"=>1,
                  "va"=>0.0,
                  "vm"=>1.0,
                  "name"=>"Bus 1\tLF",
                  "area"=>f_area,
                  "zone"=>f_zone
               ),
               "2"=>Dict{String, Any}(
                  "bus_type"=>1,
                  "vmin"=>lfac_vmin,
                  "vmax"=>lfac_vmax,
                  "bus_i"=>2,
                  "index"=>2,
                  "va"=>0.0,
                  "vm"=>1.0,
                  "name"=>"Bus 2\tLF",
                  "area"=>t_area,
                  "zone"=>t_zone
               )
            )
            # Branch Data
            lfac_branch = copy(branch)
            lfac_branch["f_bus"] = 1
            lfac_branch["t_bus"] = 2
            lfac_case["branch"] = Dict{String, Any}(
               "$(lfac_branch["index"])"=>lfac_branch
            )
            # Gen data
            lfac_case["gen"] = Dict{String, Any}(
               "1"=>Dict{String, Any}(
                  "gen_status"=>0,
                  "index"=>1,
                  "gen_bus"=>1,
                  "vg"=>1.0
               )
            )
            # Other data
            lfac_case["storage"] = Dict{String, Any}()
            lfac_case["switch"] = Dict{String, Any}()
            lfac_case["shunt"] = Dict{String, Any}()
            lfac_case["load"] = Dict{String, Any}()
            lfac_case["dcline"] = Dict{String, Any}()
            if fileext == ".m"
               io = open("$output_dir/lfac_$(base_name).m", "w");
               export_matpower(io, lfac_case)
               close(io)
            else
               stringnet = JSON.json(lfac_case)
               open("$output_dir/lfac_$(base_name)$(fileext)", "w") do f
                  write(f, stringnet)
               end
            end

            lfac_buslookup = Dict(
               base_f_bus=>1,
               base_t_bus=>2
            )

         end

         br_idx_int = parse(Int64,br_idx)
         if br_idx_int in keys(ctg_br_dict_tmp)
            bus_i = lfac_buslookup[ctg_br_dict_tmp[br_idx_int]["i"]]
            bus_j = lfac_buslookup[ctg_br_dict_tmp[br_idx_int]["j"]]
            lfac_ctg_br_dict[br_idx_int] = pop!(ctg_br_dict_tmp, br_idx_int)
            lfac_ctg_br_dict[br_idx_int]["i"] = bus_i
            lfac_ctg_br_dict[br_idx_int]["j"] = bus_j
            lfac_ctg_br_dict[br_idx_int]["ckt"] = 1
         end

         # Set two interface buses for LFAC line
         subnet_index = 2
         # LFAC "from bus" inerface
         iface_index = 1
         bus = 1
         interface_params["index"] = iface_index
         interface_params["subnet_index"] = subnet_index
         interface_params["bus"] = bus
         push!(iface_df, interface_params)
         # LFAC "to bus" inerface
         iface_index = 2
         bus = 2
         interface_params["index"] = iface_index
         interface_params["subnet_index"] = subnet_index
         interface_params["bus"] = bus
         push!(iface_df, interface_params)
         # Save interfaces file
         CSV.write("$output_dir/interfaces.csv", iface_df)
         # Save subnetworks file
         CSV.write("$output_dir/subnetworks.csv", subnet_df)

         # println("output_dir: $output_dir")
         if :contingency_file in names(subnet_df)
            write_branch_ctg_file(ctg_br_dict_tmp, output_dir*"/"*ctg_filename)
            write_branch_ctg_file(lfac_ctg_br_dict, output_dir*"/"*"lfac_"*ctg_filename)
         end





         # Copy files to a new folder with new subnetworks file for a fixed frequency
         # output_dir_fixf = "$output_location/br$(br_idx)_fixf"
         # output_dir_fixf = "$(rstrip(output_dir,'/'))_fixf"
         # if !isdir(output_dir_fixf)
         #    mkpath(output_dir_fixf)
         # end
         # cp("$output_dir/interfaces.csv", "$output_dir_fixf/interfaces.csv", force=true)
         # cp("$output_dir/lfac_$(filename)", "$output_dir_fixf/lfac_$(filename)", force=true)
         # cp("$output_dir/$(filename)", "$output_dir_fixf/$(filename)", force=true)
         # cp("$output_dir/ctg_filename", "$output_dir_fixf/ctg_filename", force=true)
         # cp("$output_dir/lfac_$(ctg_filename)", "$output_dir_fixf/lfac_$(ctg_filename)", force=true)
         # Save subnetworks file
         # CSV.write("$output_dir_fixf/subnetworks.csv", subnet_df_fixf)
         # if :contingency_file in names(subnet_df)
         #    write_branch_ctg_file(ctg_br_dict_tmp, output_dir_fixf*"/"*ctg_filename)
         #    write_branch_ctg_file(lfac_ctg_br_dict, output_dir_fixf*"/"*"lfac_"*ctg_filename)
         # end

      end
   end
end

function write_branch_ctg_file(ctg_dict, filename)
   open(filename, "w") do io
      for (idx,ctg) in ctg_dict
         output_str = "CONTINGENCY $(ctg["label"])\n$(uppercase(ctg["action"])) $(uppercase(ctg["component"])) FROM BUS $(ctg["i"]) TO BUS $(ctg["j"]) CIRCUIT $(ctg["ckt"])\nEND\n"
         write(io, output_str)
      end
      write(io,"END\n")
   end
end

function change_angle_lims(base_network, output_location, angle_lim_deg, indices=[])
   filename = split(base_network, "/")[end]
   prefix = base_network[1:(end-length(filename))]
   println("$filename")

   output_dir = "$output_location/"
   if !isdir(output_dir)
      mkpath(output_dir)
   end
   cp("$prefix/interfaces.csv", "$output_dir/interfaces.csv", force=true)
   cp("$prefix/subnetworks.csv", "$output_dir/subnetworks.csv", force=true)


   data = PowerModels.parse_file(base_network)

   for (i,(br_idx,branch)) in enumerate(data["branch"])
      if ((length(indices) == 0) || (parse(Int64, br_idx) in indices))
         branch["angmin"] = -angle_lim_deg * pi/180.0
         branch["angmax"] = angle_lim_deg * pi/180.0
      end
   end
   io = open("$output_dir/$filename", "w");
   export_matpower(io, data)
   close(io)

   if isfile("$prefix/lfac_$filename")
      data = PowerModels.parse_file("$prefix/lfac_$filename")
      for (i,(br_idx,branch)) in enumerate(data["branch"])
         if ((length(indices) == 0) || (parse(Int64, br_idx) in indices))
            branch["angmin"] = -angle_lim_deg * pi/180.0
            branch["angmax"] = angle_lim_deg * pi/180.0
         end
      end
      io = open("$output_dir/lfac_$filename", "w");
      export_matpower(io, data)
      close(io)
   end
end

function change_lims(base_network, output_location, angle_lim_deg, indices=[])
   filename = split(base_network, "/")[end]
   prefix = base_network[1:(end-length(filename))]
   println("$filename")

   output_dir = "$output_location/"
   if !isdir(output_dir)
      mkpath(output_dir)
   end
   cp("$prefix/interfaces.csv", "$output_dir/interfaces.csv", force=true)
   cp("$prefix/subnetworks.csv", "$output_dir/subnetworks.csv", force=true)


   data = PowerModels.parse_file(base_network)

   for (i,(br_idx,branch)) in enumerate(data["branch"])
      if ((length(indices) == 0) || (parse(Int64, br_idx) in indices))
         branch["angmin"] = -angle_lim_deg * pi/180.0
         branch["angmax"] = angle_lim_deg * pi/180.0
      end
   end
   io = open("$output_dir/$filename", "w");
   export_matpower(io, data)
   close(io)

   if isfile("$prefix/lfac_$filename")
      data = PowerModels.parse_file("$prefix/lfac_$filename")
      for (i,(br_idx,branch)) in enumerate(data["branch"])
         if ((length(indices) == 0) || (parse(Int64, br_idx) in indices))
            branch["angmin"] = -angle_lim_deg * pi/180.0
            branch["angmax"] = angle_lim_deg * pi/180.0
         end
      end
      io = open("$output_dir/lfac_$filename", "w");
      export_matpower(io, data)
      close(io)
   end
end

function scale_load(
      scaling,
      areas,
      directory,
      objective,
      x_axis,
      y_axis;
      gen_areas=[],
      area_transfer=[],
      gen_zones=[],
      zone_transfer=[],
      plot_vert_line::Tuple=([],""),
      plot_horiz_line::Tuple=([],""),
      xlimits::Array{Any,1}=[],
      ylimits::Array{Any,1}=[],
      output_plot_label::Tuple{String,String}=("",""),
      scopf::Bool=false,
      contingency::Int64=0
   )

   scale_all_areas = false
   if length(areas) == 0
      scale_all_areas = true
   end
   # get load pd and qd from areas of interest and put them in dict_filt
   sn_data = read_sn_data(directory)
   dict_filt = Dict()
   for (subnet_idx,sn_subnet) in sn_data["sn"]
      println("number of loads: $(length(sn_subnet["load"]))")
      for (load_idx,load) in sn_subnet["load"]
         if (sn_subnet["bus"]["$(load["load_bus"])"]["area"] in areas) || (scale_all_areas)
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
   (keys,values) = traverse_nested(dict_filt)

   # apply scaling
   # println("keys: $keys")
   # println("values: $values")
   values_scaled = collect(eachrow(values .* scaling'))
   # println("values_scaled: $values_scaled")
   params = (keys,values_scaled)
   println("number of scaled loads: $(length(values_scaled))")
   (results_dict, output_plot) = run_multiple_params(
      directory,
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
      contingency
   )
   return (results_dict, output_plot)
end
