function add_vars!(
   mn_data,
   ref_subnet,
   subnet_idx,
   model,
   va, vm, pg, qg, p, q, p_dc, q_dc, g, b, b_fr, b_to, g_fr, g_to, l_series,
   c_inv_series, f, b_shunt, cost_pg, cost_dcline, area_pg, zone_pg, redispatch_pg,
   redispatch_qg, redispatch_vm, redispatch_va, p_i, q_i,
   constraints
   )
   # Add Optimization and State Variables
   # ------------------------------------

   # println("Adding variables for subnet $subnet_idx.")
   # Check if DC subnet
   # Automatically DC if fixed frequency and the base frequency is 0
   dc_subnet = ((!ref_subnet[:variable_f]) && (ref_subnet[:f_base] == 0))
   if (:f_max in keys(ref_subnet))
      # println("ref_subnet[:f_max]: $(ref_subnet[:f_max])")
      # Also DC if max frequency is 0
      dc_subnet = dc_subnet || (ref_subnet[:f_max] == 0)
   end
   if dc_subnet
      println("Subnetwork $subnet_idx is DC. Using power flow equations for a DC network.")
   end
   # Add voltage angles va for each bus
   # print("subnet $(subnet_idx). Adding variables\n")
   if !dc_subnet
      va[subnet_idx] = @variable(
         model,
         [i in keys(ref_subnet[:bus])],
         base_name="va_$(subnet_idx)",
         start = mn_data["sn"]["$(subnet_idx)"]["bus"]["$i"]["va"]
         # start = 0.0
      )
   end
   # println([mn_data["sn"]["$(subnet_idx)"]["bus"]["$i"]["va"] for i in keys(ref_subnet[:bus])])
   # note: [i in keys(ref[:bus])] adds one `va` variable for each bus in the subnetwork
   # Add voltage magnitudes vm for each bus
   vm[subnet_idx] = @variable(
      model,
      [i in keys(ref_subnet[:bus])],
      base_name = "vm_$(subnet_idx)",
      upper_bound = ref_subnet[:bus][i]["vmax"],
      lower_bound = ref_subnet[:bus][i]["vmin"],
      start = mn_data["sn"]["$(subnet_idx)"]["bus"]["$i"]["vm"]
      # start = 1.0
   )
   for bus_i in keys(ref_subnet[:bus])
      if !(subnet_idx in keys(constraints[:vm_llim]))
         constraints[:vm_llim][subnet_idx] = Dict{Int64,Any}()
      end
      if !(subnet_idx in keys(constraints[:vm_ulim]))
         constraints[:vm_ulim][subnet_idx] = Dict{Int64,Any}()
      end
      constraints[:vm_llim][subnet_idx][bus_i] = LowerBoundRef(vm[subnet_idx][bus_i])
      constraints[:vm_ulim][subnet_idx][bus_i] = UpperBoundRef(vm[subnet_idx][bus_i])
   end
   # note: this variable also includes the voltage magnitude limits and a starting value

   # Add active power generation variable pg for each generator (including limits)
   # NOTE: If any generator limit is at the PSS/E default of +/- 9999.0, it is applied as +/- Inf here
   pg[subnet_idx] = @variable(
      model,
      [i in keys(ref_subnet[:gen])],
      base_name="pg_$(subnet_idx)",
      lower_bound=ref_subnet[:gen][i]["pmin"]*ref_subnet[:baseMVA] != -9999.0 ? ref_subnet[:gen][i]["pmin"] : -Inf,
      upper_bound=ref_subnet[:gen][i]["pmax"]*ref_subnet[:baseMVA] != 9999.0 ? ref_subnet[:gen][i]["pmax"] : Inf,
      start = mn_data["sn"]["$(subnet_idx)"]["gen"]["$i"]["pg"]
   )
   # Add reactive power generation variable qg for each generator (including limits)

   if !dc_subnet
      qg[subnet_idx] =  @variable(
         model,
         [i in keys(ref_subnet[:gen])],
         base_name="qg_$(subnet_idx)",
         lower_bound=ref_subnet[:gen][i]["qmin"],
         upper_bound=ref_subnet[:gen][i]["qmax"],
         start = mn_data["sn"]["$(subnet_idx)"]["gen"]["$i"]["qg"]
      )
   end

   for gen_i in keys(ref_subnet[:gen])
      if !(subnet_idx in keys(constraints[:pg_llim]))
         constraints[:pg_llim][subnet_idx] = Dict{Int64,Any}()
      end
      if !(subnet_idx in keys(constraints[:pg_ulim]))
         constraints[:pg_ulim][subnet_idx] = Dict{Int64,Any}()
      end
      constraints[:pg_llim][subnet_idx][gen_i] = LowerBoundRef(pg[subnet_idx][gen_i])
      constraints[:pg_ulim][subnet_idx][gen_i] = UpperBoundRef(pg[subnet_idx][gen_i])

      if !dc_subnet
         if !(subnet_idx in keys(constraints[:qg_llim]))
            constraints[:qg_llim][subnet_idx] = Dict{Int64,Any}()
         end
         if !(subnet_idx in keys(constraints[:qg_ulim]))
            constraints[:qg_ulim][subnet_idx] = Dict{Int64,Any}()
         end
         constraints[:qg_llim][subnet_idx][gen_i] = LowerBoundRef(qg[subnet_idx][gen_i])
         constraints[:qg_ulim][subnet_idx][gen_i] = UpperBoundRef(qg[subnet_idx][gen_i])
      end
   end

   # if dc_subnet
   #    delete_lower_bound.(qg[subnet_idx])
   #    delete_upper_bound.(qg[subnet_idx])
   #    for i in keys(ref_subnet[:gen])
   #       @constraint(model, qg[subnet_idx][i] == 0)
   #    end
   # end

   # Add power flow variables p to represent the active power flow for each branch
   # Apply thermal limits here to bound the variables. Give very generous thermal limits (5x the angle limit at the base frequency) if no thermal limits are defined
   # rate_a = ["rate_a" in keys(ref_subnet[:branch][l]) ? ref_subnet[:branch][l]["rate_a"] : (5*(1.1)^2)/ref_subnet[:branch][l]["br_x"]*sin(max(ref_subnet[:branch][l]["angmax"],ref_subnet[:branch][l]["angmin"])) for (l, i, j) in ref_subnet[:arcs]]
   p[subnet_idx] = @variable(
      model,
      [(l, i, j) in ref_subnet[:arcs]],
      base_name = "p_$(subnet_idx)",
      # upper_bound = abs("rate_a" in keys(ref_subnet[:branch][l]) ? ref_subnet[:branch][l]["rate_a"] : (5*(1.1)^2)/ref_subnet[:branch][l]["br_x"]*sin(max(ref_subnet[:branch][l]["angmax"],ref_subnet[:branch][l]["angmin"]))),
      # lower_bound = -abs("rate_a" in keys(ref_subnet[:branch][l]) ? ref_subnet[:branch][l]["rate_a"] : (5*(1.1)^2)/ref_subnet[:branch][l]["br_x"]*sin(max(ref_subnet[:branch][l]["angmax"],ref_subnet[:branch][l]["angmin"])))
   )
   # Add power flow variables q to represent the reactive power flow for each branch
   if !dc_subnet
      q[subnet_idx] = @variable(
         model,
         [(l, i, j) in ref_subnet[:arcs]],
         base_name = "q_$(subnet_idx)",
         # upper_bound = abs("rate_a" in keys(ref_subnet[:branch][l]) ? ref_subnet[:branch][l]["rate_a"] : (5*(1.1)^2)/ref_subnet[:branch][l]["br_x"]*sin(max(ref_subnet[:branch][l]["angmax"],ref_subnet[:branch][l]["angmin"]))),
         # lower_bound = -abs("rate_a" in keys(ref_subnet[:branch][l]) ? ref_subnet[:branch][l]["rate_a"] : (5*(1.1)^2)/ref_subnet[:branch][l]["br_x"]*sin(max(ref_subnet[:branch][l]["angmax"],ref_subnet[:branch][l]["angmin"])))
      )
   end
   # note: ref_subnet[:arcs] includes both the from (i,j) and the to (j,i) sides of a branch

   # Add power flow variables p_dc to represent the active power flow for each HVDC line
   p_dc[subnet_idx] = @variable(
      model,
      [a in ref_subnet[:arcs_dc]],
      base_name = "p_dc_$(subnet_idx)",
   )
   # Add power flow variables q_dc to represent the reactive power flow at each HVDC terminal
   if !dc_subnet
      q_dc[subnet_idx] = @variable(
         model,
         [a in ref_subnet[:arcs_dc]],
         base_name = "q_dc_$(subnet_idx)",
      )
   end

   for (l,dcline) in ref_subnet[:dcline]
      f_idx = (l, dcline["f_bus"], dcline["t_bus"])
      t_idx = (l, dcline["t_bus"], dcline["f_bus"])

      JuMP.set_lower_bound(p_dc[subnet_idx][f_idx], dcline["pminf"])
      JuMP.set_upper_bound(p_dc[subnet_idx][f_idx], dcline["pmaxf"])
      JuMP.set_lower_bound(q_dc[subnet_idx][f_idx], dcline["qminf"])
      JuMP.set_upper_bound(q_dc[subnet_idx][f_idx], dcline["qmaxf"])

      JuMP.set_lower_bound(p_dc[subnet_idx][t_idx], dcline["pmint"])
      JuMP.set_upper_bound(p_dc[subnet_idx][t_idx], dcline["pmaxt"])
      JuMP.set_lower_bound(q_dc[subnet_idx][f_idx], dcline["qmint"])
      JuMP.set_upper_bound(q_dc[subnet_idx][f_idx], dcline["qmaxt"])
   end

   if ref_subnet[:variable_f]
      ref_subnet[:f_min] = max(ref_subnet[:f_min],0) # don't allow negative frequencies
      ref_subnet[:f_min] = min(ref_subnet[:f_min],ref_subnet[:f_max]) # don't allow minimum larger than maximum
      if ref_subnet[:f_min] == ref_subnet[:f_max]
         ref_subnet[:variable_f] = false
         ref_subnet[:f_fixed] = ref_subnet[:f_min]
      else
         f_init = (ref_subnet[:f_min]<=ref_subnet[:f_base]<=ref_subnet[:f_max]) ? ref_subnet[:f_base] : (ref_subnet[:f_min] + ref_subnet[:f_max])/2
         f[subnet_idx] = @variable(
            model,
            base_name="f_$(subnet_idx)",
            lower_bound=ref_subnet[:f_min],
            upper_bound=ref_subnet[:f_max],
            start=f_init
         )
      end
   end
end
