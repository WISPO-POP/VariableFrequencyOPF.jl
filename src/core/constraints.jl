

function add_constraints!(
   mn_data,
   ref_subnet,
   subnet_idx,
   model,
   va, vm, pg, qg, p, q, p_dc, q_dc, g, b, b_fr, b_to, g_fr, g_to, l_series,
   c_inv_series, f, b_shunt, cost_pg, cost_dcline, area_pg, zone_pg, redispatch_pg,
   redispatch_qg, redispatch_vm, redispatch_va, p_i, q_i,
   constraints,
   obj, gen_areas, area_interface,
   gen_zones, zone_interface,
   direct_pq,
   dc_current_limit,
   master_subnet
   )
   # Add Constraints
   # ---------------
   # println("Adding constraints in subnet $subnet_idx.")
   # check if DC subnet
   dc_subnet = ((!ref_subnet[:variable_f]) && (ref_subnet[:f_base] == 0))
   if (:f_max in keys(ref_subnet))
      println("f_max = $(ref_subnet[:f_max])")
      dc_subnet = dc_subnet || (ref_subnet[:f_max] == 0)
   end
   if dc_subnet
      println("Subnetwork $subnet_idx is DC. Using power flow equations for a DC network.")
   end
   # Fix the voltage angle to zero at the reference bus in each subnetwork
   # If no direct PQ control, fix the angle only for the master subnet
   if !dc_subnet && (direct_pq || (subnet_idx==master_subnet))
      for (i,bus) in ref_subnet[:ref_buses]
         if !(subnet_idx in keys(constraints[:theta_ref]))
            constraints[:theta_ref][subnet_idx] = Dict{Int64, Any}()
         end
         constraints[:theta_ref][subnet_idx][i] = @constraint(model, va[subnet_idx][i] == 0)
         # println("set angle reference bus $i in subnet $subnet_idx")
      end
   end

   # Nodal power balance constraints
   # Defining frequency dependent shunts

   # For each subnet, the bus shunts are indexed by tuple (i,j),
   # denoting the jth shunt at bus i.
   b_shunt[subnet_idx] = Dict{Tuple{Int64,Int64},Any}()
   for (i,bus) in ref_subnet[:bus]
      # Define converter interface power flow variables by bus
      if haskey(bus, "converter_index")
         bus_interfaces = bus["converter_index"]
      else
         bus_interfaces = Array{Int64,1}()
      end
      # Build a list of the loads and shunt elements connected to the bus i
      bus_loads = [ref_subnet[:load][l] for l in ref_subnet[:bus_loads][i]]
      bus_shunts = [ref_subnet[:shunt][s] for s in ref_subnet[:bus_shunts][i]]
      if ref_subnet[:variable_f]
         for (j,shunt) in enumerate(bus_shunts)
            if dc_subnet
               b_shunt[subnet_idx][i,j] = 0
            else
               c_bus_shunt = shunt["bs"]/(2*pi*ref_subnet[:f_base])
               b_shunt[subnet_idx][i,j] = @variable(
                  model,
                  base_name = "b_shunt_$(subnet_idx)_$(i)_$(j)",
               )
               @constraint(
                  model,
                  (2pi)*c_bus_shunt*f[subnet_idx] == b_shunt[subnet_idx][i,j]
               )
               # print("shunt $(j) = variable\n")
            end
         end
      else #if not a variable frequency subnetwork
         if :f_fixed in keys(ref_subnet)
            f_ratio = ref_subnet[:f_fixed]/ref_subnet[:f_base]
         else
            f_ratio = 1
         end
         for (j,shunt) in enumerate(bus_shunts)
            b_shunt[subnet_idx][i,j] = shunt["bs"]*f_ratio
            # print("shunt $(j) = $(shunt["bs"])\n")
         end
      end
      # print("defined shunts\n")
      # Active power balance at node i
      # for conv_idx in bus_interfaces
      #    println("bus $i conv_idx: $conv_idx")
      #    println("keys(p_i[$(conv_idx[1][1])]) = $(keys(p_i[conv_idx[1][1]]))")
      # end
      @constraint(
         model,
         sum(p[subnet_idx][a] for a in ref_subnet[:bus_arcs][i]) +                  # sum of active power flow on lines from bus i +
         sum(p_dc[subnet_idx][a_dc] for a_dc in ref_subnet[:bus_arcs_dc][i]) ==     # sum of active power flow on HVDC lines from bus i =
         sum(pg[subnet_idx][g] for g in ref_subnet[:bus_gens][i]) +                 # sum of active power generation at bus i +
         sum(p_i[conv_idx[1][1]][(subnet_idx, i)]
             for conv_idx in bus_interfaces) -              # sum of active power from interface to bus i -
         sum(load["pd"] for load in bus_loads) -                                    # sum of active load consumption at bus i -
         sum(shunt["gs"] for shunt in bus_shunts)*vm[subnet_idx][i]^2               # sum of active shunt element injections at bus i
      )
      # println("busgens: $(ref_subnet[:bus_gens][i])")
      # Reactive power balance at node i
      # println("bus_interfaces: $bus_interfaces")
      if !dc_subnet
         if ref_subnet[:variable_f]
            @NLconstraint(
               model,
               sum(q[subnet_idx][a] for a in ref_subnet[:bus_arcs][i]) +                                    # sum of reactive power flow on lines from bus i +
               sum(q_dc[subnet_idx][a_dc] for a_dc in ref_subnet[:bus_arcs_dc][i]) ==                       # sum of reactive power flow on HVDC lines from bus i =
               sum(qg[subnet_idx][g] for g in ref_subnet[:bus_gens][i]) +                                   # sum of reactive power generation at bus i +
               sum(q_i[conv_idx[1][1]][(subnet_idx, i)]
                   for conv_idx in bus_interfaces) -                                # sum of reactive power from interface to bus i -
               sum(load["qd"] for load in bus_loads) -                                                      # sum of reactive load consumption at bus i -
               sum(-b_shunt[subnet_idx][i,j] for (j,shunt) in enumerate(bus_shunts))*vm[subnet_idx][i]^2    # sum of reactive shunt element injections at bus i
            )
         else
            @constraint(
               model,
               sum(q[subnet_idx][a] for a in ref_subnet[:bus_arcs][i]) +                                    # sum of reactive power flow on lines from bus i +
               sum(q_dc[subnet_idx][a_dc] for a_dc in ref_subnet[:bus_arcs_dc][i]) ==                       # sum of reactive power flow on HVDC lines from bus i =
               sum(qg[subnet_idx][g] for g in ref_subnet[:bus_gens][i]) +                                   # sum of reactive power generation at bus i +
               sum(q_i[conv_idx[1][1]][(subnet_idx, i)]
                   for conv_idx in bus_interfaces) -                                # sum of reactive power from interface to bus i -
               sum(load["qd"] for load in bus_loads) -                                                      # sum of reactive load consumption at bus i -
               sum(-b_shunt[subnet_idx][i,j] for (j,shunt) in enumerate(bus_shunts))*vm[subnet_idx][i]^2    # sum of reactive shunt element injections at bus i
            )
         end
      end
   end

   # Branch power flow physics and limit constraints
   g[subnet_idx] = Dict{Int64,Any}()
   b[subnet_idx] = Dict{Int64,Any}()
   b_fr[subnet_idx] = Dict{Int64,Any}()
   b_to[subnet_idx] = Dict{Int64,Any}()
   g_fr[subnet_idx] = Dict{Int64,Any}()
   g_to[subnet_idx] = Dict{Int64,Any}()
   l_series[subnet_idx] = Dict{Int64,Any}()
   c_inv_series[subnet_idx] = Dict{Int64,Any}()
   for (i,branch) in ref_subnet[:branch]
      # Build the from variable id of the i-th branch, which is a tuple given by (branch id, from bus, to bus)
      f_idx = (i, branch["f_bus"], branch["t_bus"])
      # Build the to variable id of the i-th branch, which is a tuple given by (branch id, to bus, from bus)
      t_idx = (i, branch["t_bus"], branch["f_bus"])
      # note: it is necessary to distinguish between the from and to sides of a branch due to power losses

      p_fr = p[subnet_idx][f_idx]                     # p_fr is a reference to the optimization variable p[f_idx]
      p_to = p[subnet_idx][t_idx]                     # p_to is a reference to the optimization variable p[t_idx]
      # note: adding constraints to p_fr is equivalent to adding constraints to p[f_idx], and so on

      vm_fr = vm[subnet_idx][branch["f_bus"]]         # vm_fr is a reference to the optimization variable vm on the from side of the branch
      vm_to = vm[subnet_idx][branch["t_bus"]]         # vm_to is a reference to the optimization variable vm on the to side of the branch


      # Compute the branch parameters and transformer ratios from the data
      tr, ti = PowerModels.calc_branch_t(branch)
      tm = branch["tap"]^2
      # note: tap is assumed to be 1.0 on non-transformer branches
      # print("g_base: $(g_base)\n")
      # print("b_base: $(b_base)\n")
      if dc_subnet && branch["shift"] != 0
         throw(ArgumentError("Subnetwork $subnet_idx is specified as a DC network, but branch $(branch["index"]) has a nonzero phase shift: $(branch["shift"])"))
      end

      if ref_subnet[:variable_f]
         if ("f_dependent" in keys(branch)) && branch["f_dependent"] #if this is a branch (typically a cable) with modeled frequency-dependent R, L, and C parameters
            # Currently this supports linear frequency dependence in each of the parameters series R and X and shunt G and B
            if dc_subnet
               r0 = branch["br_rdc"]
               g_to0 = branch["g_to_dc"]
               g_fr0 = branch["g_fr_dc"]

               g[subnet_idx][i] = 1/r0
               b[subnet_idx][i] = 0
               b_fr[subnet_idx][i] = 0
               b_to[subnet_idx][i] = 0
               g_fr[subnet_idx][i] = g_fr0
               g_to[subnet_idx][i] = g_to0
            else
               x0 = branch["br_x0"]
               x1 = branch["br_x1"]
               x2 = branch["br_x2"]
               r0 = branch["br_r0"]
               r1 = branch["br_r1"]
               r2 = branch["br_r2"]
               b_to0 = branch["b_to0"]
               b_to1 = branch["b_to1"]
               b_to2 = branch["b_to2"]
               b_fr0 = branch["b_fr0"]
               b_fr1 = branch["b_fr1"]
               b_fr2 = branch["b_fr2"]
               g_to0 = branch["g_to0"]
               g_to1 = branch["g_to1"]
               g_to2 = branch["g_to2"]
               g_to3 = branch["g_to3"]
               g_to4 = branch["g_to4"]
               g_fr0 = branch["g_fr0"]
               g_fr1 = branch["g_fr1"]
               g_fr2 = branch["g_fr2"]
               g_fr3 = branch["g_fr3"]
               g_fr4 = branch["g_fr4"]

               ω = 2pi*f[subnet_idx]

               g[subnet_idx][i] = @variable(
                  model,
                  base_name = "g_$(subnet_idx)_$i",
               )
               # @NLconstraint(
               #    model,
               #    g[subnet_idx][i] == (r1*2pi*f[subnet_idx]+r0) / (
               #       f[subnet_idx]^2*(4*pi^2*(r1^2+x1^2)) + f[subnet_idx]*(4*pi*(r0*r1+x0*x1)) + r0^2 + x0^2
               #    )
               # )
               @NLconstraint(
                  model,
                  g[subnet_idx][i] == (r2*ω^2+r1*ω+r0) / (
                     ω^4*(r2^2+x2^2) + ω^3*(2*r1*r2+2*x1*x2) + ω^2*(2*r0*r2+r1^2+2*x0*x2+x1^2) + ω*(2*r0*r1+2*x0*x1) + r0^2 + x0^2
                  )
               )
               # print("defined G and equality constraint\n")
               b[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_$(subnet_idx)_$i",
               )
               # @NLconstraint(
               #    model,
               #    b[subnet_idx][i] == -(
               #       (x1*2pi*f[subnet_idx]+x0) / (
               #          f[subnet_idx]^2*(4*pi^2*(r1^2+x1^2)) + f[subnet_idx]*(4*pi*(r0*r1+x0*x1)) + r0^2 + x0^2
               #       )
               #    )
               # )
               @NLconstraint(
                  model,
                  b[subnet_idx][i] == -(
                     (x2*ω^2+x1*ω+x0) / (
                        ω^4*(r2^2+x2^2) + ω^3*(2*r1*r2+2*x1*x2) + ω^2*(2*r0*r2+r1^2+2*x0*x2+x1^2) + ω*(2*r0*r1+2*x0*x1) + r0^2 + x0^2
                     )
                  )
               )
               b_fr[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_fr_$(subnet_idx)_$i",
               )
               # @constraint(
               #    model,
               #    b_fr[subnet_idx][i] == 2pi*b_fr1*f[subnet_idx] + b_fr0
               # )
               @constraint(
                  model,
                  b_fr[subnet_idx][i] == ω^2*b_fr2 + ω*b_fr1 + b_fr0
               )
               b_to[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_to_$(subnet_idx)_$i",
               )
               # @constraint(
               #    model,
               #    b_to[subnet_idx][i] == 2pi*b_to1*f[subnet_idx] + b_to0
               # )
               @constraint(
                  model,
                  b_to[subnet_idx][i] == ω^2*b_to2 + ω*b_to1 + b_to0
               )
               g_fr[subnet_idx][i] = @variable(
                  model,
                  base_name = "g_fr_$(subnet_idx)_$i",
               )
               # @constraint(
               #    model,
               #    g_fr[subnet_idx][i] == 2pi*g_fr1*f[subnet_idx] + g_fr0
               # )
               @NLconstraint(
                  model,
                  g_fr[subnet_idx][i] == ω^4*g_fr4 + ω^3*g_fr3 + ω^2*g_fr2 + ω*g_fr1 + g_fr0
               )
               g_to[subnet_idx][i] = @variable(
                  model,
                  base_name = "g_to_$(subnet_idx)_$i",
               )
               # @constraint(
               #    model,
               #    g_to[subnet_idx][i] == 2pi*g_to1*f[subnet_idx] + g_to0
               # )
               @NLconstraint(
                  model,
                  g_to[subnet_idx][i] == ω^4*g_to4 + ω^3*g_to3 + ω^2*g_to2 + ω*g_to1 + g_to0
               )
            end

         else #if this is a normal branch with constant R, L, and C
            g_fr[subnet_idx][i] = branch["g_fr"]
            g_to[subnet_idx][i] = branch["g_to"]
            b_fr_base = branch["b_fr"]
            b_to_base = branch["b_to"]

            f_base = ref_subnet[:f_base]
            # Series parameters

            # Identify series L and C from line data
            # Assumption: the given base line impedance is either
            # purely inductive (positive) or purely capacitive (negative).
            # This means that series compensation should be represented in the
            # model as a separate branch in series
            x_base = branch["br_x"]
            if x_base >= 0
               l_series[subnet_idx][i] = x_base / (2pi*f_base)
               c_inv_series[subnet_idx][i] = 0
            else
               l_series[subnet_idx][i] = 0
               c_inv_series[subnet_idx][i] = - x_base * (2pi*f_base)
            end
            r = branch["br_r"]
            # Shunt parameters
            c_fr = b_fr_base / (2pi*f_base)
            c_to = b_to_base / (2pi*f_base)
            # print("c_fr: $(c_fr)\n")
            # print("c_to: $(c_to)\n")

            if dc_subnet
               g[subnet_idx][i] = 1/r
               b[subnet_idx][i] = 0
               b_fr[subnet_idx][i] = 0
               b_to[subnet_idx][i] = 0
            else
               g[subnet_idx][i] = @variable(
                  model,
                  base_name = "g_$(subnet_idx)_$i",
               )
               @NLconstraint(
                  model,
                  g[subnet_idx][i] == r/(r^2 + (
                     l_series[subnet_idx][i]^2 * (2pi)^2*f[subnet_idx]^2
                     + c_inv_series[subnet_idx][i]^2 / ((2pi)^2*f[subnet_idx]^2)
                     - 2 * l_series[subnet_idx][i] * c_inv_series[subnet_idx][i]
                     ))
               )
               # print("defined G and equality constraint\n")
               b[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_$(subnet_idx)_$i",
               )
               @NLconstraint(
                  model,
                  b[subnet_idx][i] == -(
                     (
                        2pi*f[subnet_idx]*l_series[subnet_idx][i]
                        - c_inv_series[subnet_idx][i] / ((2pi)*f[subnet_idx])
                        )
                     /(r^2 + (
                        l_series[subnet_idx][i]^2 * (2pi)^2*f[subnet_idx]^2
                        + c_inv_series[subnet_idx][i]^2 / ((2pi)^2*f[subnet_idx]^2)
                        - 2 * l_series[subnet_idx][i] * c_inv_series[subnet_idx][i]
                        )
                     )
                  )
               )
               b_fr[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_fr_$(subnet_idx)_$i",
               )
               @constraint(
                  model,
                  b_fr[subnet_idx][i] == 2pi*c_fr*f[subnet_idx]
               )
               b_to[subnet_idx][i] = @variable(
                  model,
                  base_name = "b_to_$(subnet_idx)_$i",
               )
               @constraint(
                  model,
                  b_to[subnet_idx][i] == 2pi*c_to*f[subnet_idx]
               )
               # print("defined variable G, B\n")
            end
         end
      else #if !ref_subnet[:variable_f]
         # The frequency is fixed at the base value and all remaining line parameters are defined as fixed based on the base values at that frequency
         # This also applies if the fixed base frequency is DC and the parameters have been defined at DC.
         # If the subnetwork is DC but the line parameters are defined at a different base frequency,
         # the frequency limits should be set to 0 and variable_f true, which is handled in the clause above.
         if :f_fixed in keys(ref_subnet)
            f_ratio = ref_subnet[:f_fixed]/ref_subnet[:f_base]
         else
            f_ratio = 1
            ref_subnet[:f_fixed] = ref_subnet[:f_base]
         end

         if f_ratio == 0 # DC subnetwork
            if ("f_dependent" in keys(branch)) && branch["f_dependent"]
               r0 = branch["br_rdc"]
               g_to0 = branch["g_to_dc"]
               g_fr0 = branch["g_fr_dc"]

               g[subnet_idx][i] = 1/r0
               b[subnet_idx][i] = 0
               b_fr[subnet_idx][i] = 0
               b_to[subnet_idx][i] = 0
               g_fr[subnet_idx][i] = g_fr0
               g_to[subnet_idx][i] = g_to0
            else
               r = branch["br_r"]
               g[subnet_idx][i] = 1/r
               b[subnet_idx][i] = 0
               b_fr[subnet_idx][i] = 0
               b_to[subnet_idx][i] = 0
               g_fr[subnet_idx][i] = branch["g_fr"]
               g_to[subnet_idx][i] = branch["g_to"]
            end
         elseif ("f_dependent" in keys(branch)) && branch["f_dependent"] #if this is a branch (typically a cable) with modeled frequency-dependent R, L, and C parameters
            x0 = branch["br_x0"]
            x1 = branch["br_x1"]
            x2 = branch["br_x2"]
            r0 = branch["br_r0"]
            r1 = branch["br_r1"]
            r2 = branch["br_r2"]
            b_to0 = branch["b_to0"]
            b_to1 = branch["b_to1"]
            b_to2 = branch["b_to2"]
            b_fr0 = branch["b_fr0"]
            b_fr1 = branch["b_fr1"]
            b_fr2 = branch["b_fr2"]
            g_to0 = branch["g_to0"]
            g_to1 = branch["g_to1"]
            g_to2 = branch["g_to2"]
            g_to3 = branch["g_to3"]
            g_to4 = branch["g_to4"]
            g_fr0 = branch["g_fr0"]
            g_fr1 = branch["g_fr1"]
            g_fr2 = branch["g_fr2"]
            g_fr3 = branch["g_fr3"]
            g_fr4 = branch["g_fr4"]

            ω = 2pi*ref_subnet[:f_fixed]

            # g[subnet_idx][i] = (r1*2pi*ref_subnet[:f_fixed]+r0) / (
            #    ref_subnet[:f_fixed]^2*(4*pi^2*(r1^2+x1^2)) + ref_subnet[:f_fixed]*(4*pi*(r0*r1+x0*x1)) + r0^2 + x0^2
            # )
            g[subnet_idx][i] = (r2*ω^2+r1*ω+r0) / (
               ω^4*(r2^2+x2^2) + ω^3*(2*r1*r2+2*x1*x2) + ω^2*(2*r0*r2+r1^2+2*x0*x2+x1^2) + ω*(2*r0*r1+2*x0*x1) + r0^2 + x0^2
            )
            # g[subnet_idx][i] = (r4*ω^4+r3*ω^3+r2*ω^2+r1*ω+r0) / (
            #    (r4*ω^4+r3*ω^3+r2*ω^2+r1*ω+r0)^2 + (x2*ω^2+x1*ω+x0)^2
            # )
            b[subnet_idx][i] = -(
               (x2*ω^2+x1*ω+x0) / (
                  ω^4*(r2^2+x2^2) + ω^3*(2*r1*r2+2*x1*x2) + ω^2*(2*r0*r2+r1^2+2*x0*x2+x1^2) + ω*(2*r0*r1+2*x0*x1) + r0^2 + x0^2
               )
            )
            # b[subnet_idx][i] = -(
            #    (x2*ω^2+x1*ω+x0) / (
            #       (r4*ω^4+r3*ω^3+r2*ω^2+r1*ω+r0)^2 + (x2*ω^2+x1*ω+x0)^2
            #    )
            # )
            b_fr[subnet_idx][i] = ω^2*b_fr2 + ω*b_fr1 + b_fr0
            b_to[subnet_idx][i] = ω^2*b_to2 + ω*b_to1 + b_to0
            g_fr[subnet_idx][i] = ω^4*g_fr4 + ω^3*g_fr3 + ω^2*g_fr2 + ω*g_fr1 + g_fr0
            g_to[subnet_idx][i] = ω^4*g_to4 + ω^3*g_to3 + ω^2*g_to2 + ω*g_to1 + g_to0
            println("subnet $subnet_idx branch $(branch["index"]) has frequency $(ref_subnet[:f_fixed]) and frequency-dependent parameters")
         elseif f_ratio == 1
            g_base, b_base = PowerModels.calc_branch_y(branch)
            g[subnet_idx][i] = g_base
            b[subnet_idx][i] = b_base
            b_fr[subnet_idx][i] = branch["b_fr"]
            b_to[subnet_idx][i] = branch["b_to"]
            g_fr[subnet_idx][i] = branch["g_fr"]
            g_to[subnet_idx][i] = branch["g_to"]
         else
            f_base = ref_subnet[:f_base]
            # Series parameters

            # Identify series L and C from line data
            # Assumption: the given base line impedance is either
            # purely inductive (positive) or purely capacitive (negative).
            # This means that series compensation should be represented in the
            # model as a separate branch in series
            g_fr[subnet_idx][i] = branch["g_fr"]
            g_to[subnet_idx][i] = branch["g_to"]
            b_fr_base = branch["b_fr"]
            b_to_base = branch["b_to"]
            x_base = branch["br_x"]
            if x_base >= 0
               l_series[subnet_idx][i] = x_base / (2pi*f_base)
               c_inv_series[subnet_idx][i] = 0
            else
               l_series[subnet_idx][i] = 0
               c_inv_series[subnet_idx][i] = - x_base * (2pi*f_base)
            end
            r = branch["br_r"]
            # Shunt parameters
            c_fr = b_fr_base / (2pi*f_base)
            c_to = b_to_base / (2pi*f_base)

            g[subnet_idx][i] = r/(r^2 + (
               l_series[subnet_idx][i]^2 * (2pi)^2*ref_subnet[:f_fixed]^2
               + c_inv_series[subnet_idx][i]^2 / ((2pi)^2*ref_subnet[:f_fixed]^2)
               - 2 * l_series[subnet_idx][i] * c_inv_series[subnet_idx][i]
               ))
            b[subnet_idx][i] = -(
               (
                  2pi*ref_subnet[:f_fixed]*l_series[subnet_idx][i]
                  - c_inv_series[subnet_idx][i] / ((2pi)*ref_subnet[:f_fixed])
                  )
               /(r^2 + (
                  l_series[subnet_idx][i]^2 * (2pi)^2*ref_subnet[:f_fixed]^2
                  + c_inv_series[subnet_idx][i]^2 / ((2pi)^2*ref_subnet[:f_fixed]^2)
                  - 2 * l_series[subnet_idx][i] * c_inv_series[subnet_idx][i]
                  )
               )
            )
            b_fr[subnet_idx][i] = 2pi*c_fr*ref_subnet[:f_fixed]
            b_to[subnet_idx][i] = 2pi*c_to*ref_subnet[:f_fixed]
         end

      end

      g_br = g[subnet_idx][i]          # g_br is a reference to the branch series conductance optimization variable or fixed parameter g[subnet_idx][i]
      b_br = b[subnet_idx][i]          # b_br is a reference to the branch series susceptance optimization variable or fixed parameter b[subnet_idx][i]
      b_fr_br = b_fr[subnet_idx][i]    # b_fr_br is a reference to the branch "from" side shunt susceptance optimization variable or fixed parameter b_fr_br[subnet_idx][i]
      b_to_br = b_to[subnet_idx][i]    # b_to_br is a reference to the branch "to" side shunt susceptance optimization variable or fixed parameter b_to_br[subnet_idx][i]
      g_fr_br = g_fr[subnet_idx][i]    # g_fr_br is a reference to the branch "from" side shunt conductance optimization variable or fixed parameter g_fr_br[subnet_idx][i]
      g_to_br = g_to[subnet_idx][i]    # g_to_br is a reference to the branch "to" side shunt conductance optimization variable or fixed parameter g_to_br[subnet_idx][i]

      # print("adding power flow constraints\n")


      if dc_subnet
         # DC power flow
         if !(:k_cond in keys(ref_subnet))
            ref_subnet[:k_cond] = sqrt(3)
         end
         if !(:k_ins in keys(ref_subnet))
            ref_subnet[:k_ins] = 1
         end

         k_cond = ref_subnet[:k_cond]
         k_ins = ref_subnet[:k_ins]

         println("k_cond: $k_cond")
         println("k_ins: $k_ins")
         println("g_br: $g_br")
         ## From side of the branch flow
         @NLconstraint(
            model,
            p_fr == k_cond*k_ins^2/sqrt(3)*(
               (g_br+(4/3)*g_fr_br)*vm_fr^2
               + (-g_br)*(vm_fr*vm_to)
            )
         )
         # @constraint(
         #    model,
         #    q_fr == 0
         # )


         # To side of the branch flow
         @NLconstraint(
            model,
            p_to == k_cond*k_ins^2/sqrt(3)*(
               (g_br+(4/3)*g_to_br)*vm_to^2
               + (-g_br)*(vm_to*vm_fr)
            )
         )
         # @constraint(
         #    model,
         #    q_to == 0
         # )

         # @constraint(
         #    model,
         #    va_fr == 0
         # )
         # @constraint(
         #    model,
         #    va_to == 0
         # )

      else
         q_fr = q[subnet_idx][f_idx]                     # q_fr is a reference to the optimization variable q[f_idx]
         q_to = q[subnet_idx][t_idx]                     # q_to is a reference to the optimization variable q[t_idx]
         va_fr = va[subnet_idx][branch["f_bus"]]         # va_fr is a reference to the optimization variable va on the from side of the branch
         va_to = va[subnet_idx][branch["t_bus"]]         # va_fr is a reference to the optimization variable va on the to side of the branch
         # From side of the branch flow
         @NLconstraint(
            model,
            p_fr == (
               (g_br+g_fr_br)/tm*vm_fr^2
               + (-g_br*tr+b_br*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to))
               + (-b_br*tr-g_br*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to))
            )
         )
         @NLconstraint(
            model,
            q_fr == (
               -(b_br+b_fr_br)/tm*vm_fr^2
               - (-b_br*tr-g_br*ti)/tm*(vm_fr*vm_to*cos(va_fr-va_to))
               + (-g_br*tr+b_br*ti)/tm*(vm_fr*vm_to*sin(va_fr-va_to))
            )
         )


         # To side of the branch flow
         @NLconstraint(
            model,
            p_to == (
               (g_br+g_to_br)*vm_to^2
               + (-g_br*tr-b_br*ti)/tm*(vm_to*vm_fr*cos(va_to-va_fr))
               + (-b_br*tr+g_br*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr))
            )
         )
         @NLconstraint(
            model,
            q_to == (
               -(b_br+b_to_br)*vm_to^2
               - (-b_br*tr+g_br*ti)/tm*(vm_to*vm_fr*cos(va_fr-va_to))
               + (-g_br*tr-b_br*ti)/tm*(vm_to*vm_fr*sin(va_to-va_fr))
            )
         )

         # Voltage angle difference limit
         if !(subnet_idx in keys(constraints[:theta_ulim]))
            constraints[:theta_ulim][subnet_idx] = Dict{Int64,Any}()
         end
         if !(subnet_idx in keys(constraints[:theta_llim]))
            constraints[:theta_llim][subnet_idx] = Dict{Int64,Any}()
         end
         if (("ignore_anglims" in keys(branch)) && (branch["ignore_anglims"])) #|| branch["transformer"]
            # Angle limits ignored on this branch. Set to +/- 90 for convergence.
            println("Setting +/- 90.0 deg angle limits on branch $(branch["index"])")
            constraints[:theta_ulim][subnet_idx][i] = @constraint(model, va_fr - va_to <= pi/2)
            constraints[:theta_llim][subnet_idx][i] = @constraint(model, va_fr - va_to >= -pi/2)
         else
            # If an alternative angle limit is defined, as in the case of series compensation with an intermediate bus
            if ("alt_ang_lim" in keys(branch)) && (length(branch["alt_ang_lim"])==2)
               (alt_f_bus, alt_t_bus) = branch["alt_ang_lim"]
               # println("ref branch: $branch")
               alt_va_fr = va[subnet_idx][alt_f_bus]
               alt_va_to = va[subnet_idx][alt_t_bus]
               # println("subnet $subnet_idx, branch $(branch["index"])")
               # println("alt_va_fr: $alt_va_fr")
               # println("alt_va_to: $alt_va_to")
               constraints[:theta_ulim][subnet_idx][i] = @constraint(model, alt_va_fr - alt_va_to <= branch["angmax"])
               constraints[:theta_llim][subnet_idx][i] = @constraint(model, alt_va_fr - alt_va_to >= branch["angmin"])

               # Set limits for the branch to +/- 90 for convergence.
               @constraint(model, va_fr - va_to <= pi/2)
               @constraint(model, va_fr - va_to >= -pi/2)
            else
               constraints[:theta_ulim][subnet_idx][i] = @constraint(model, va_fr - va_to <= branch["angmax"])
               constraints[:theta_llim][subnet_idx][i] = @constraint(model, va_fr - va_to >= branch["angmin"])
            end
         end
      end



      # Apparent power limit, from side and to side
      if "rate_a" in keys(branch)
         if !(subnet_idx in keys(constraints[:s_ulim]))
            constraints[:s_ulim][subnet_idx] = Dict{Int64,Any}()
         end
         if !(subnet_idx in keys(constraints[:s_llim]))
            constraints[:s_llim][subnet_idx] = Dict{Int64,Any}()
         end
         if dc_subnet && dc_current_limit
            constraints[:s_ulim][subnet_idx][i] = @constraint(model, p_fr^2 <= k_ins*k_cond*branch["rate_a"]^2)
            constraints[:s_llim][subnet_idx][i] = @constraint(model, p_to^2 <= k_ins*k_cond*branch["rate_a"]^2)
         elseif dc_subnet
            constraints[:s_ulim][subnet_idx][i] = @constraint(model, p_fr^2 <= branch["rate_a"]^2)
            constraints[:s_llim][subnet_idx][i] = @constraint(model, p_to^2 <= branch["rate_a"]^2)
         else
            constraints[:s_ulim][subnet_idx][i] = @constraint(model, p_fr^2 + q_fr^2 <= branch["rate_a"]^2)
            constraints[:s_llim][subnet_idx][i] = @constraint(model, p_to^2 + q_to^2 <= branch["rate_a"]^2)
         end
      end
      # print("added power flow constraints\n")
   end

   # HVDC line constraints
   for (i,dcline) in ref_subnet[:dcline]
      # Build the from variable id of the i-th HVDC line, which is a tuple given by (hvdc line id, from bus, to bus)
      f_idx = (i, dcline["f_bus"], dcline["t_bus"])
      # Build the to variable id of the i-th HVDC line, which is a tuple given by (hvdc line id, to bus, from bus)
      t_idx = (i, dcline["t_bus"], dcline["f_bus"])   # index of the ith HVDC line which is a tuple given by (line number, to bus, from bus)
      # note: it is necessary to distinguish between the from and to sides of a HVDC line due to power losses

      # Constraint defining the power flow and losses over the HVDC line
      @constraint(model, (1-dcline["loss1"])*p_dc[subnet_idx][f_idx] + (p_dc[subnet_idx][t_idx] - dcline["loss0"]) == 0)
   end
   # print("finished adding all constraints for network $(subnet_idx)\n")
   # print("adding cost variables\n")

   # assumes costs are given as quadratic functions
   cost_pg[subnet_idx] = @variable(model, base_name = "cost_pg_$(subnet_idx)")
   @constraint(
      model,
      cost_pg[subnet_idx] == sum(
      gen["cost"][1]*pg[subnet_idx][i]^2
      + gen["cost"][2]*pg[subnet_idx][i]
      + gen["cost"][3]
         for (i,gen) in ref_subnet[:gen]
      )
   )
   # index representing which side the HVDC line is starting
   from_idx = Dict(arc[1] => arc for arc in ref_subnet[:arcs_from_dc])
   cost_dcline[subnet_idx] = @variable(model, base_name = "cost_dcline_$(subnet_idx)")
   @constraint(
      model,
      cost_dcline[subnet_idx] == sum(
      dcline["cost"][1]*p_dc[subnet_idx][from_idx[i]]^2
      + dcline["cost"][2]*p_dc[subnet_idx][from_idx[i]]
      + dcline["cost"][3]
         for (i,dcline) in ref_subnet[:dcline]
      )
   )
   if (obj=="mincost") || (obj=="areagen") || (obj=="zonegen")
      if (obj=="areagen")
         areagens = keys(filter(p->(ref_subnet[:bus][last(p)["gen_bus"]]["area"] in gen_areas), ref_subnet[:gen]))
         # println("subnet $subnet_idx")
         # println("areagens: $(areagens)")
         area_pg[subnet_idx] = @variable(model, base_name = "area_pg_$(subnet_idx)")
         @constraint(
            model,
            area_pg[subnet_idx] == sum(
               pg[subnet_idx][i]
               for i in areagens
            )
         )
      end
      if (obj=="zonegen")
         zonegens = keys(filter(p->(ref_subnet[:bus][last(p)["gen_bus"]]["zone"] in gen_zones), ref_subnet[:gen]))
         # println("subnet $subnet_idx")
         # println("zonegens: $(zonegens)")
         zone_pg[subnet_idx] = @variable(model, base_name = "zone_pg_$(subnet_idx)")
         @constraint(
            model,
            zone_pg[subnet_idx] == sum(
               pg[subnet_idx][i]
               for i in zonegens
            )
         )
      end
   elseif obj=="minredispatch"
      # Get base case dispatch
      redispatch_pg[subnet_idx] = @variable(model, base_name = "dev_pg_$(subnet_idx)")
      @constraint(
         model,
         redispatch_pg[subnet_idx] == sum(
            (gen["pg"] - pg[subnet_idx][i])^2
            for (i,gen) in ref_subnet[:gen]
         )
      )
      redispatch_qg[subnet_idx] = @variable(model, base_name = "dev_qg_$(subnet_idx)")
      @constraint(
         model,
         redispatch_qg[subnet_idx] == sum(
            (gen["qg"] - qg[subnet_idx][i])^2
            for (i,gen) in ref_subnet[:gen]
         )
      )
      # redispatch_vm[subnet_idx] = @variable(model, base_name = "dev_vm_$(subnet_idx)")
      # @constraint(
      #    model,
      #    redispatch_vm[subnet_idx] == sum(
      #       (ref_subnet[:bus][gen["gen_bus"]]["vm"] - vm[subnet_idx][gen["gen_bus"]])^2
      #       for (i,gen) in ref_subnet[:gen]
      #    )
      # )
      redispatch_vm[subnet_idx] = @variable(model, base_name = "dev_vm_$(subnet_idx)")
      @constraint(
         model,
         redispatch_vm[subnet_idx] == sum(
            (bus["vm"] - vm[subnet_idx][i])^2
            for (i,bus) in ref_subnet[:bus] if (bus["bus_type"] in [1,2,3])
         )
      )
      redispatch_va[subnet_idx] = @variable(model, base_name = "dev_va_$(subnet_idx)")
      @constraint(
         model,
         redispatch_va[subnet_idx] == sum(
            (bus["va"] - va[subnet_idx][i])^2
            for (i,bus) in ref_subnet[:bus] if (bus["bus_type"] in [1,2,3])
         )
      )
      # println([gen["vg"] for (i,gen) in ref_subnet[:gen]])
      # println([ref_subnet[:bus][gen["gen_bus"]]["vm"] for (i,gen) in ref_subnet[:gen]])
   end
end

function add_gen_zone_scaling_constraint!(
   ref_data,
   model,
   pg,
   constraints,
   unbounded_pg,
   gen_zones
   )

   alpha_upstream = @variable(
      model,
      base_name="alpha_upstream",
      lower_bound=0,
      start=1
   )
   alpha_downstream = @variable(
      model,
      base_name="alpha_downstream",
      lower_bound=0,
      start=1
   )
   for (subnet_idx, ref_subnet) in ref_data
      for i in keys(ref_subnet[:gen])
         if ref_subnet[:bus][ref_subnet[:gen][i]["gen_bus"]]["zone"] in gen_zones
            # This is a downstream generator (objective is to minimize downstream generation)
            println("adding downstream constraint for gen $i: starting value $(ref_subnet[:gen][i]["pg"])")
            @constraint(
               model,
               pg[subnet_idx][i] == alpha_downstream * ref_subnet[:gen][i]["pg"]
            )
         else
            # This is an upstream generator
            println("adding upstream constraint for gen $i: starting value $(ref_subnet[:gen][i]["pg"])")
            @constraint(
               model,
               pg[subnet_idx][i] == alpha_upstream * ref_subnet[:gen][i]["pg"]
            )
         end
      end
      if unbounded_pg
         delete_upper_bound.(pg[subnet_idx])
         delete!(constraints[:pg_ulim],subnet_idx)
         delete_lower_bound.(pg[subnet_idx])
         delete!(constraints[:pg_llim],subnet_idx)
      end
   end
   return alpha_upstream, alpha_downstream
end
