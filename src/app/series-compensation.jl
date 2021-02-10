function series_comp_range(base_network, output_location, k_min, k_max, steps, r_sc, existing_branch, station_bus, new_bus, enum_branches=false, base_frequency=nothing)
   k_vals = range(k_min,stop=k_max,length=steps)
   if !all(k_min.==0)
      k_vals = vcat([zeros(length(k_vals[1]))], k_vals)
      steps += 1
   end
   for i in 1:steps
      k = k_vals[i]
      output_folder = split(rstrip(output_location,'/'), "/")[end]
      output_folder = output_folder[output_folder .!= ""]
      output_dir = rstrip(output_location,'/')[1:(end-length(output_folder)-1)]
      output_base_net = add_series_comp(base_network, "$(output_dir)_sc$(i-1)/$output_folder/", k, r_sc, existing_branch, station_bus, new_bus, false)
      if enum_branches
         enumerate_branches(output_base_net,"$(output_dir)_sc$(i-1)/", base_frequency)
      end
   end
end

function add_series_comp(base_network, output_location, k, r_sc, existing_branch, station_bus, new_bus, allow_matpower_out=false)
   filename = split(base_network, "/")[end]
   prefix = base_network[1:(end-length(filename))]

   matpower_file = false
   (basefile, extension) = splitext(filename)
   if (Unicode.normalize(extension, casefold=true) == ".m") && (allow_matpower_out)
      matpower_file = true
      fileout = filename
   else
      fileout = "$basefile.json"
   end
   println("input: $filename")
   println("output: $fileout")

   output_dir = "$output_location/"
   if !isdir(output_dir)
      mkpath(output_dir)
   end
   for other_file in readdir(prefix)
      if Unicode.normalize(other_file, casefold=true) != Unicode.normalize(filename, casefold=true)
         cp("$prefix/$other_file", "$output_dir/$other_file", force=true)
      end
   end

   data = PowerModels.parse_file(base_network)
   highest_br_index =  max(parse.(Int64, keys(data["branch"]))...)
   for (i, k_i) in enumerate(k)
      if (k_i == 0.0) && (r_sc[i] == 0.0) # if a zero impedance branch is specified (degenerate case of series compensation)
         continue # skip to next branch if this one has zero impedance
      end
      # Get copy of series compensation origin bus
      # (note: station_bus can be either f_bus or t_bus in the new sc branch;
      # the direction of the sc branch
      # is made to be consistent with the existing branch)
      sc_bus_data = copy(data["bus"]["$(station_bus[i])"])
      # Create new sc destination bus
      sc_bus_data["bus_i"] = new_bus[i]
      sc_bus_data["index"] = new_bus[i]
      sc_bus_data["name"] = "SC $(sc_bus_data["name"])"
      sc_bus_data["pd"] = 0
      sc_bus_data["qd"] = 0
      # sc_bus_data["apply_ang_lim"] = false
      data["bus"]["$(new_bus[i])"] = sc_bus_data

      # Find the series compensation reactance from the existing branch data
      branch = data["branch"]["$(existing_branch[i])"]
      x_sc = -k_i * branch["br_x"]
      # Preserve the buses at which the angle limits are applied
      # in the "alt_ang_lim" field.
      # This is read and applied in multifrequency_opf.
      data["branch"]["$(existing_branch[i])"]["alt_ang_lim"] = [branch["f_bus"], branch["t_bus"]]

      # Change either origin or destination of the existing branch to the new bus
      if branch["f_bus"] == station_bus[i]
         data["branch"]["$(existing_branch[i])"]["f_bus"] = new_bus[i]
         println("Changed 'f_bus' of branch $(branch["index"]) from $(station_bus[i]) to $(new_bus[i])")
         sc_f_bus = station_bus[i]
         sc_t_bus = new_bus[i]
      elseif branch["t_bus"] == station_bus[i]
         data["branch"]["$(existing_branch[i])"]["t_bus"] = new_bus[i]
         println("Changed 't_bus' of branch $(branch["index"]) from $(station_bus[i]) to $(new_bus[i])")
         sc_f_bus = new_bus[i]
         sc_t_bus = station_bus[i]
      else
         throw(ArgumentError("The input existing_branch $(existing_branch[i]) is not connected to station_bus $(station_bus[i])."))
      end


      # Create a new sc branch
      new_br_index = highest_br_index + i
      new_branch = Dict(
         "f_bus"=> sc_f_bus,
         "t_bus"=> sc_t_bus,
         "index"=> new_br_index,
         "br_x"=> x_sc,
         "br_r"=> r_sc[i],
         "sc_bus"=> new_bus[i], # used to identify the new bus for purposes of adding LFAC lines that include both series branches
         "rate_a"=> branch["rate_a"],
         "rate_b"=> branch["rate_b"],
         "rate_c"=> branch["rate_c"],
         # "rate_a"=> 0,
         # "rate_b"=> 0,
         # "rate_c"=> 0,
         "br_status"=> branch["br_status"],
         "angmin"=> -pi/2,
         "angmax"=> pi/2,
         "ignore_anglims"=>true,
         "shift"=> 0,
         "g_to"=> 0,
         "g_fr"=> 0,
         "b_fr"=> 0,
         "b_to"=> 0,
         "source_id"=> [
          "branch",
          sc_f_bus,
          sc_t_bus,
          "SC"
          ],
         "transformer"=> false,
         "tap"=> 1
         )
      data["branch"]["$new_br_index"] = new_branch
   end
   if matpower_file
      io = open("$output_dir/$fileout", "w");
      export_matpower(io, data)
      close(io)
   else
      stringnet = JSON.json(data)
      open("$output_dir/$fileout", "w") do f
         write(f, stringnet)
      end
      # Since the file is changing to json format, specify the new filename in the subnetworks file
      subnet_df = CSV.read("$prefix/subnetworks.csv", copycols=true)
      subnet_df[subnet_df.file .== filename,:file] = fileout
      # Save subnetworks file
      CSV.write("$output_dir/subnetworks.csv", subnet_df)
   end
   return "$output_dir/$fileout"
end
