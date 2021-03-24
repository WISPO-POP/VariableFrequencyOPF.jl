
"""
    read_sn_data(folder::String)

Reads a network folder and builds the mn_data dictionary.

# Arguments
- `folder::String`: the path to the folder containing all the network data
"""
function read_sn_data(folder::String; kwargs...)
   directory_path = "$folder/"
   subnet_file = "$(directory_path)/subnetworks.csv"

   subnets = CSV.read(subnet_file, DataFrame)

   if nrow(subnets) == 1
      interfaces = DataFrame(index=Int64[],file=String[],variable_f=Bool[],f_base=Float64[],f_min=Float64[],fmax=Float64[])
   else
      interface_file = "$(directory_path)/interfaces.csv"
      interfaces = CSV.read(interface_file, DataFrame)
   end

   networks = Dict{String,Any}()

   for subnet in eachrow(subnets)
      file_name = directory_path*subnet.file
      networks[subnet.file] = PowerModels.parse_file(file_name)

      # Add zeros to turn linear objective functions into quadratic ones
      # so that additional parameter checks are not required
      PowerModels.standardize_cost_terms!(networks[subnet.file], order=2)

   end

   mn_data = make_mn_data(subnets, interfaces, networks; kwargs...)

   return mn_data
end

"""
    function make_mn_data(
        subnetworks,
        interfaces,
        networks::Dict{String,Any}
    )

Builds the mn_data dictionary from the specifications of the subnetworks and interfaces DataFrames and the network data in the networks Dict.

# Arguments
- `subnetworks`: a DataFrame in the format of *subnetworks.csv*, and *interfaces.csv*
- `interfaces`: a DataFrame in the format of *interfaces.csv*
- `networks::Dict{String,Any}`: a Dict of all subnetworks, as PowerModels networks
"""
function make_mn_data(
   subnetworks,
   interfaces,
   networks::Dict{String,Any};
   no_converter_loss::Bool=false
   )

   mn_data = Dict{String,Any}(
      "sn" => Dict{String,Any}()
   )

   for subnet in eachrow(subnetworks)
      file_name = subnet.file
      # println("reading $(file_name)")

      mn_data["sn"]["$(subnet.index)"] = networks[file_name]
      mn_data["sn"]["$(subnet.index)"]["variable_f"] = typeof(subnet.variable_f)==Bool ? subnet.variable_f : (lowercase(subnet.variable_f) == "true")
      mn_data["sn"]["$(subnet.index)"]["f_base"] = subnet.f_base
      if mn_data["sn"]["$(subnet.index)"]["variable_f"]
         mn_data["sn"]["$(subnet.index)"]["f_min"] = subnet.f_min
         mn_data["sn"]["$(subnet.index)"]["f_max"] = subnet.f_max
      end

      # REMOVING BUSES OF TYPE 4 (ISOLATED)
      # mn_data["sn"]["$(subnet.index)"]["bus"] = filter(p->(last(p)["bus_type"]!=4), mn_data["sn"]["$(subnet.index)"]["bus"])
      # Disable loads at type 4 buses
      for (idx,load) in mn_data["sn"]["$(subnet.index)"]["load"]
         # println("Bus $(load["load_bus"])")
         # println(mn_data["sn"]["$(subnet.index)"]["bus"]["$(load["load_bus"])"])
         if mn_data["sn"]["$(subnet.index)"]["bus"]["$(load["load_bus"])"]["bus_type"]==4 && load["status"] == 1
            println("Bus $(load["load_bus"]) is type 4 (isolated) and has a load. The load will be disabled.")
            load["status"] = 0
         end
      end
      for (idx,gen) in mn_data["sn"]["$(subnet.index)"]["gen"]
         if mn_data["sn"]["$(subnet.index)"]["bus"]["$(gen["gen_bus"])"]["bus_type"]==4 && gen["gen_status"] == 1
            println("Bus $(gen["gen_bus"]) is type 4 (isolated) and has a generator. The generator will be disabled.")
            gen["gen_status"] = 0
         end
      end
      for (idx,shunt) in mn_data["sn"]["$(subnet.index)"]["shunt"]
         if mn_data["sn"]["$(subnet.index)"]["bus"]["$(shunt["shunt_bus"])"]["bus_type"]==4 && shunt["status"] == 1
            println("Bus $(shunt["shunt_bus"]) is type 4 (isolated) and has a shunt. The shunt will be disabled.")
            shunt["status"] = 0
         end
      end
   end


   mn_data["converter"] = Dict{Int64, Any}()
   interface_bus = Array{Tuple{Int64,Int64},1}()
   for interface in eachrow(interfaces)
      # Check that we have transformer/filter branch data in the interfaces file and for this terminal specifically
      if !no_converter_loss && all(indexin(["R","X","G","B"], names(interfaces)) .!= nothing) && !(any(x -> ismissing(x), interface[["R","X","G","B"]])) && !(interface.R == 0 && interface.X == 0)
         # First create the converter terminal buses. New bus index is '90X',
         # where X is the existing bus, e.g. bus 334 gets terminal bus 90334.
         # If 90X is already a bus in the network, try 900X, and so on.
         busmult=0
         new_bus_idx = Int(interface.bus + 900*10^(busmult+floor(log10(interface.bus))))
         while new_bus_idx in parse.(Int,keys(mn_data["sn"]["$(interface.subnet_index)"]["bus"]))
            busmult=busmult+1
            new_bus_idx = Int(interface.bus + 900*10^(busmult+floor(log10(interface.bus))))
         end
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"] = Dict{String,Any}()
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["bus_i"] = new_bus_idx
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["index"] = new_bus_idx
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["bus_type"] = 1
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["vmax"] = interface.vmax
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["vmin"] = 0.8
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["zone"] = copy(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"]["zone"])
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["area"] = copy(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"]["area"])
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["va"] = copy(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"]["va"])
         mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["vm"] = copy(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"]["vm"])
         if "base_kv" in names(interfaces)
            mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["base_kv"] = interface.base_kv
         elseif "base_kv" in keys(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"])
            mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["base_kv"] = copy(mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(interface.bus)"]["base_kv"])
         end
         # Include current limit in bus data
         # mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["converter_imax"] = Dict{Int64,Float64}()
         # mn_data["sn"]["$(interface.subnet_index)"]["bus"]["$(new_bus_idx)"]["converter_imax"][interface.index] = interface.imax

         # Now define a branch at the terminal
         new_branch_idx = maximum(parse.(Int,keys(mn_data["sn"]["$(interface.subnet_index)"]["branch"]))) + 1
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"] = Dict{String,Any}()
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["index"] = new_branch_idx
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["f_bus"] = new_bus_idx
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["t_bus"] = interface.bus
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["angmax"] = pi/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["angmin"] = -pi/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["br_r"] = interface.R
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["br_x"] = interface.X
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["g_to"] = interface.G/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["g_fr"] = interface.G/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["b_to"] = interface.B/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["b_fr"] = interface.B/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["g_to"] = interface.G/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["g_fr"] = interface.G/2
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["rate_a"] = interface.smax
         mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["br_status"] = 1
         if ("transformer" in names(interfaces)) && !(ismissing(interface.transformer))
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["transformer"] = interface.transformer
         else
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["transformer"] = false
         end
         if ("tap" in names(interfaces)) && !(ismissing(interface.tap))
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["tap"] = interface.tap
         else
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["tap"] = 1
         end
         if ("shift" in names(interfaces)) && !(ismissing(interface.shift))
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["shift"] = interface.shift
         else
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["shift"] = 0
         end
         if ("rate_b" in names(interfaces)) && !(ismissing(interface.rate_b))
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["rate_b"] = interface.rate_b
         else
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["rate_b"] = interface.smax
         end
         if ("rate_c" in names(interfaces)) && !(ismissing(interface.rate_c))
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["rate_c"] = interface.rate_c
         else
            mn_data["sn"]["$(interface.subnet_index)"]["branch"]["$(new_branch_idx)"]["rate_c"] = interface.smax
         end
         interface_bus = (interface.subnet_index,new_bus_idx)
         # if !((interface.index,interface.subnet_index,new_bus_idx) in keys(mn_data["converter"]))
         #    mn_data["converter"][interface.index,interface.subnet_index,new_bus_idx] = Dict{String,Any}("converter_buses" => Array{Tuple{Int64,Int64},1}())
         # end
         # if !((interface.subnet_index,new_bus_idx) in mn_data["converter"][interface.index,interface.subnet_index,new_bus_idx]["converter_buses"])
         #    push!(mn_data["converter"][interface.index,interface.subnet_index,new_bus_idx]["converter_buses"], (interface.subnet_index,new_bus_idx))
         # end
      else
         interface_bus = (interface.subnet_index,interface.bus)
      end

      # println("interface_bus: $(interface_bus)")
      # Create array to store indices of the converters connected to this bus,
      # along with dictionaries for all the parameters, indexed by the converter index
      if !("converter_index" in keys(mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]))
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_index"] = Array{Tuple,1}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_imax"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_vmax"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c1"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c2"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c3"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw1"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw2"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw3"] = Dict{Int64,Float64}()
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_M"] = Dict{Int64,Float64}()
      end
      param_labels = [:imax,:vmax,:c1,:c2,:c3,:sw1,:sw2,:sw3,:M]
      converter_params = Dict{Symbol,Any}()
      for label in param_labels
         # println("Interface labels: $(names(interface))")
         # println("Label: $label")
         if string(label) in names(interface)
            converter_params[label] = interface[label]
         else
            println("The converter parameter $label is not specified for interface $(interface.index).")
            if label == :vmax
               if "v_max" in names(interface)
                  println("Found v_max. Applying this limit. Change the label to \"vmax\" in interfaces.csv to ensure future functionality.")
                  converter_params[label] = interface[!,:v_max]
               else
                  converter_params[label] = 1.2
                  println("Set to 1.2.")
               end
            elseif label == :imax
               converter_params[label] = Inf
               println("Set limit to Inf.")
            elseif label == :M
               converter_params[label] = 1
               println("Set to 1.")
            else
               converter_params[label] = 0
               println("Set to 0.")
            end
         end
      end

      if !(interface.index in mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_index"])
         push!(mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_index"], (interface.index,interface_bus[1],interface_bus[2]))
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_imax"][interface.index] = converter_params[:imax]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_vmax"][interface.index] = converter_params[:vmax]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c1"][interface.index]   = no_converter_loss ? 0.0 : converter_params[:c1]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c2"][interface.index]   = no_converter_loss ? 0.0 : converter_params[:c2]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_c3"][interface.index]   = no_converter_loss ? 0.0 : converter_params[:c3]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw1"][interface.index]  = no_converter_loss ? 0.0 : converter_params[:sw1]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw2"][interface.index]  = no_converter_loss ? 0.0 : converter_params[:sw2]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_sw3"][interface.index]  = no_converter_loss ? 0.0 : converter_params[:sw3]
         mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_M"][interface.index]    = converter_params[:M]
      end
      # println("converter_imax: $(mn_data["sn"]["$(interface_bus[1])"]["bus"]["$(interface_bus[2])"]["converter_imax"])")



      if !(interface.index in keys(mn_data["converter"]))
         mn_data["converter"][interface.index] = Dict{String,Any}("converter_buses" => Array{Tuple{Int64,Int64},1}())
      end
      if !(interface_bus in mn_data["converter"][interface.index]["converter_buses"])
         push!(mn_data["converter"][interface.index]["converter_buses"], interface_bus)
      end

      if !("imax" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["imax"] = Dict(interface_bus => converter_params[:imax])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["imax"]))
         mn_data["converter"][interface.index]["imax"][interface_bus] = converter_params[:imax]
      end

      if !("vmax" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["vmax"] = Dict(interface_bus => converter_params[:vmax])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["vmax"]))
         mn_data["converter"][interface.index]["vmax"][interface_bus] = converter_params[:vmax]
      end

      if !("c1" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["c1"] = Dict(interface_bus => converter_params[:c1])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["c1"]))
         mn_data["converter"][interface.index]["c1"][interface_bus] = converter_params[:c1]
      end

      if !("c2" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["c2"] = Dict(interface_bus => converter_params[:c2])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["c2"]))
         mn_data["converter"][interface.index]["c2"][interface_bus] = converter_params[:c2]
      end

      if !("c3" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["c3"] = Dict(interface_bus => converter_params[:c3])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["c3"]))
         mn_data["converter"][interface.index]["c3"][interface_bus] = converter_params[:c3]
      end

      if !("sw1" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["sw1"] = Dict(interface_bus => converter_params[:sw1])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["sw1"]))
         mn_data["converter"][interface.index]["sw1"][interface_bus] = converter_params[:sw1]
      end

      if !("sw2" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["sw2"] = Dict(interface_bus => converter_params[:sw2])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["sw2"]))
         mn_data["converter"][interface.index]["sw2"][interface_bus] = converter_params[:sw2]
      end

      if !("sw3" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["sw3"] = Dict(interface_bus => converter_params[:sw3])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["sw3"]))
         mn_data["converter"][interface.index]["sw3"][interface_bus] = converter_params[:sw3]
      end

      if !("M" in keys(mn_data["converter"][interface.index]))
         mn_data["converter"][interface.index]["M"] = Dict(interface_bus => converter_params[:M])
      elseif !(interface_bus in keys(mn_data["converter"][interface.index]["M"]))
         mn_data["converter"][interface.index]["M"][interface_bus] = converter_params[:M]
      end

         # if "converter_buses" not in keys(mn_data["converter"][interface.index])
         #    mn_data["converter"][interface.index]["converter_buses"] = Array{Tuple(Int64,Int64)}()
         # end
      # print("parsed $(directory_path)/$(file_name)\n")
   end



   return mn_data
end

function to_powermodels_json(input_network, output_dir=nothing)
   filename = split(input_network, "/")[end]
   println("$filename")
   filetype = split(lowercase(filename), '.')[end]
   base_name = filename[1:(end-length(filetype)-1)]
   (base_name, filetype) = splitext(filename)
   filetype = Unicode.normalize(filetype, casefold=true)

   if output_dir == nothing
      output_dir = join(split(input_network, "/")[1:end-1],"/")
   end

   data = PowerModels.parse_file(input_network)

   stringnet = JSON.json(data)
   open("$output_dir/$(base_name).json", "w") do f
      write(f, stringnet)
   end
end
