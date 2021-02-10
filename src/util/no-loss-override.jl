
function create_noloss_dict(mn_data; existing_override=Dict())
   noloss_override = deepcopy(existing_override)
   try
      for (conv_idx, converter) in mn_data["converter"]
         if !("converter" in keys(noloss_override))
            noloss_override["converter"] = Dict()
         end
         for (bus, c1) in converter["c1"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c1" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c1"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c1"][bus] = 0.0
         end
         for (bus, c2) in converter["c2"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c2" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c2"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c2"][bus] = 0.0
         end
         for (bus, c3) in converter["c3"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c3" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c3"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c3"][bus] = 0.0
         end
         for (bus, sw1) in converter["sw1"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw1" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw1"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw1"][bus] = 0.0
         end
         for (bus, sw2) in converter["sw2"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw2" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw2"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw2"][bus] = 0.0
         end
         for (bus, sw3) in converter["sw3"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw3" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw3"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw3"][bus] = 0.0
         end
      end
   catch KeyError
      println("No converters in the network: no loss parameters to change.")
   end
   for (subnet_idx, subnet) in mn_data["nw"]
      for (bus_idx,bus) in subnet["bus"]
         if "converter_c1" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c1) in bus["converter_c1"]
               if !("converter_c1" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c1"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c1"][conv_idx] = 0.0
            end
         end
         if "converter_c2" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c2) in bus["converter_c2"]
               if !("converter_c2" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c2"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c2"][conv_idx] = 0.0
            end
         end
         if "converter_c3" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c3) in bus["converter_c3"]
               if !("converter_c3" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c3"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_c3"][conv_idx] = 0.0
            end
         end
         if "converter_sw1" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw1) in bus["converter_sw1"]
               if !("converter_sw1" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw1"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw1"][conv_idx] = 0.0
            end
         end
         if "converter_sw2" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw2) in bus["converter_sw2"]
               if !("converter_sw2" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw2"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw2"][conv_idx] = 0.0
            end
         end
         if "converter_sw3" in keys(bus)
            if !("nw" in keys(noloss_override))
               noloss_override["nw"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["nw"]))
               noloss_override["nw"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["nw"][subnet_idx]))
               noloss_override["nw"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["nw"][subnet_idx]["bus"]))
               noloss_override["nw"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw3) in bus["converter_sw3"]
               if !("converter_sw3" in keys(noloss_override["nw"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw3"] = Dict()
               end
               noloss_override["nw"][subnet_idx]["bus"][bus_idx]["converter_sw3"][conv_idx] = 0.0
            end
         end
      end
   end
   return noloss_override
end

function create_noloss_dict_scopf(mn_data; existing_override=Dict())
   noloss_override = deepcopy(existing_override)
   try
      for (conv_idx, converter) in mn_data["converter"]
         if !("converter" in keys(noloss_override))
            noloss_override["converter"] = Dict()
         end
         for (bus, c1) in converter["c1"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c1" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c1"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c1"][bus] = 0.0
         end
         for (bus, c2) in converter["c2"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c2" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c2"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c2"][bus] = 0.0
         end
         for (bus, c3) in converter["c3"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("c3" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["c3"] = Dict()
            end
            noloss_override["converter"][conv_idx]["c3"][bus] = 0.0
         end
         for (bus, sw1) in converter["sw1"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw1" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw1"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw1"][bus] = 0.0
         end
         for (bus, sw2) in converter["sw2"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw2" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw2"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw2"][bus] = 0.0
         end
         for (bus, sw3) in converter["sw3"]
            if !(conv_idx in keys(noloss_override["converter"]))
               noloss_override["converter"][conv_idx] = Dict()
            end
            if !("sw3" in keys(noloss_override["converter"][conv_idx]))
               noloss_override["converter"][conv_idx]["sw3"] = Dict()
            end
            noloss_override["converter"][conv_idx]["sw3"][bus] = 0.0
         end
      end
   catch KeyError
      println("No converters in the network: no loss parameters to change.")
   end
   for (subnet_idx, subnet) in mn_data["sn"]
      for (bus_idx,bus) in subnet["bus"]
         if "converter_c1" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c1) in bus["converter_c1"]
               if !("converter_c1" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c1"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c1"][conv_idx] = 0.0
            end
         end
         if "converter_c2" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c2) in bus["converter_c2"]
               if !("converter_c2" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c2"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c2"][conv_idx] = 0.0
            end
         end
         if "converter_c3" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_c3) in bus["converter_c3"]
               if !("converter_c3" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c3"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_c3"][conv_idx] = 0.0
            end
         end
         if "converter_sw1" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw1) in bus["converter_sw1"]
               if !("converter_sw1" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw1"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw1"][conv_idx] = 0.0
            end
         end
         if "converter_sw2" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw2) in bus["converter_sw2"]
               if !("converter_sw2" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw2"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw2"][conv_idx] = 0.0
            end
         end
         if "converter_sw3" in keys(bus)
            if !("sn" in keys(noloss_override))
               noloss_override["sn"] = Dict()
            end
            if !(subnet_idx in keys(noloss_override["sn"]))
               noloss_override["sn"][subnet_idx] = Dict()
            end
            if !("bus" in keys(noloss_override["sn"][subnet_idx]))
               noloss_override["sn"][subnet_idx]["bus"] = Dict()
            end
            if !(bus_idx in keys(noloss_override["sn"][subnet_idx]["bus"]))
               noloss_override["sn"][subnet_idx]["bus"][bus_idx] = Dict()
            end
            for (conv_idx, conv_sw3) in bus["converter_sw3"]
               if !("converter_sw3" in keys(noloss_override["sn"][subnet_idx]["bus"][bus_idx]))
                  noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw3"] = Dict()
               end
               noloss_override["sn"][subnet_idx]["bus"][bus_idx]["converter_sw3"][conv_idx] = 0.0
            end
         end
      end
   end
   return noloss_override
end
