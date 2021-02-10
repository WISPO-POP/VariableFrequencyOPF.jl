
function set_startvals!(
   start_vals,
   va, vm, pg, qg, p, q, f
   )
   # Set starting values if given
   for (subnet_idx, subnet) in start_vals["nw"]
      subnet_idx_int = parse(Int64,subnet_idx)
      if subnet_idx_int in keys(vm)
         for (bus_i,bus) in subnet["bus"]
            bus_i_int = bus["bus_i"]
            # println("bus_i_int: $bus_i_int")
            # println("keys(vm[subnet_idx_int]): $(axes(vm[subnet_idx_int])[1])")
            if (bus_i_int in axes(vm[subnet_idx_int])[1]) && ("vm" in keys(bus))
               JuMP.set_start_value(vm[subnet_idx_int][bus_i_int], bus["vm"])
               JuMP.set_start_value(va[subnet_idx_int][bus_i_int], bus["va"])
               println("set bus $bus_i_int vm and va starting values")
            end
         end
         for (gen_i,gen) in subnet["gen"]
            gen_i_int = gen["index"]
            if (gen_i_int in axes(pg[subnet_idx_int])[1]) && ("pg" in keys(gen))
               JuMP.set_start_value(pg[subnet_idx_int][gen_i_int], gen["pg"])
               JuMP.set_start_value(qg[subnet_idx_int][gen_i_int], gen["qg"])
               println("set gen $gen_i_int pg and qg starting values")
            end
         end
         for (branch_i,branch) in subnet["branch"]
            f_idx = (branch["index"], branch["f_bus"], branch["t_bus"])
            t_idx = (branch["index"], branch["t_bus"], branch["f_bus"])
            if (f_idx in axes(p[subnet_idx_int])[1]) && ("pf" in keys(branch))
               JuMP.set_start_value(p[subnet_idx_int][f_idx], branch["pf"])
               JuMP.set_start_value(p[subnet_idx_int][t_idx], branch["pt"])
               JuMP.set_start_value(q[subnet_idx_int][f_idx], branch["qf"])
               JuMP.set_start_value(q[subnet_idx_int][t_idx], branch["qt"])
               println("set branch $(branch["index"]) p and q starting values")
            end
         end
         if "frequency" in keys(subnet)
            if ref[:nw][subnet_idx_int][:variable_f]
               JuMP.set_start_value(f[subnet_idx], subnet["frequency"])
               println("set subnet $subnet_idx_int frequency starting value")
            end
         end
      end
   end

end
