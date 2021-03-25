
"""
    multifrequency_opf(
        folder::String,
        obj::String;
        gen_areas=[],
        area_interface=[],
        gen_zones=[],
        zone_interface=[],
        print_results::Bool=false,
        override_param::Dict{Any}=Dict(),
        fix_f_override::Bool=false,
        direct_pq::Bool=true,
        master_subnet::Int64=1,
        suffix::String="",
        start_vals=Dict{String, Dict}("sn"=>Dict()),
        no_converter_loss::Bool=false,
        uniform_gen_scaling::Bool=false,
        unbounded_pg::Bool=false
    )

Models and solves the OPF for a single network with data contained in `folder`.

# Arguments
- `folder::String`: the directory containing all subnetwork data, *subnetworks.csv*, and *interfaces.csv*
- `obj::String`: the objective function to use, from the following:
   - "mincost": minimize generation cost
   - "areagen": minimize generation in the areas specified in `gen_areas`
   - "zonegen": minimize generation in the zones specified in `gen_zones`
   - "minredispatch": minimize the change in generator dispatch from the initial values defined in the network data
- `gen_areas`: integer array of all areas in which generation should be minimized if `obj=="areagen"`
- `area_interface`: two areas with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two areas. Must have exactly two elements.
- `gen_zones`: integer array of all zones in which generation should be minimized if `obj=="zonegen"`
- `zone_interface`: two zones with power transfer between them that should be saved and plotted. Results for P, Q, S, and loss are saved for power transfer between the two zones. Must have exactly two elements.
- `print_results::Bool`: if true, print the DataFrames containing the output values for buses, branches, generators, and interfaces. These values are always saved to the output *.csv* files whether true or false.
- `override_param::Dict{Any}`: values to override in the network data defined in `folder`. Must follow the same structure as the full network data dictionary, beginning with key "sn". Default empty Dict.
- `fix_f_override::Bool`: if true, fix the frequency in every subnetwork to the base value, overriding the `variable_f` parameter to `variable_f=false` for every subnetwork. Default false.
- `direct_pq::Bool`: If direct_pq is false, then the interface is treated as a single node and power flow respects Kirchoff Laws, by constraining the voltage magnitude and angle on each side to be equal and enforcing reactive power balance. Default true.
- `master_subnet::Int64`: if `direct_pq==false`, the angle reference must be defined for exactly one subnetwork, since the other subnetwork angles are coupled through the interfaces. Value of `master_subnet` defines which subnetwork provides this reference. Default 1.
- `suffix::String`: suffix to add to the output directory when saving results. Default empty string.
- `start_vals`: Nested dictionary populated with values to be used as a starting point in the optimization model. Applies to bus `vm` and `va`, gen `pg` and `qg`, branch `pt`, `pf`, `qt` and `qf` and subnet `f`. Any of these values which are present in the dictionary will be applied; other values will be ignored. A full network data dictionary can be used. Default `Dict{String, Dict}("sn"=>Dict())`.
"""
function multifrequency_opf(
   folder::String,
   obj::String;
   gen_areas=[],
   area_interface=[],
   gen_zones=[],
   zone_interface=[],
   print_results::Bool=false,
   override_param::Dict{Any}=Dict(),
   fix_f_override::Bool=false,
   direct_pq::Bool=true,
   master_subnet::Int64=1,
   suffix::String="",
   start_vals=Dict{String, Dict}("sn"=>Dict()),
   no_converter_loss::Bool=false,
   uniform_gen_scaling::Bool=false,
   unbounded_pg::Bool=false,
   output_to_files::Bool=true,
   output_location_base::String="",
   output_top_folder::String=""
   )

   println("read_sn_data($folder)")
   mn_data = read_sn_data(folder, no_converter_loss=no_converter_loss)

   folder = abspath(folder)
   if length(output_location_base) > 0
      output_folder = output_location_base
   else
      folder_split = splitpath(folder)
      toplevels = folder_split[1:end-3]
      output_folder = joinpath(toplevels...,"results/$(folder_split[end-1])/$(folder_split[end])$suffix")
   end
   output_folder = joinpath(output_folder, output_top_folder)
   if !isdir(output_folder)
      mkpath(output_folder)
   end

   # toplevel = split(folder,"/")[1]
   # output_folder = join([(i==toplevel ? "results/" : "$i/") for i in split(folder,"/")])*suffix
   println("output folder: $output_folder")
   if !isdir(output_folder)
      mkpath(output_folder)
   end

   (output_dict, res_summary, solution_pm, binding_cnstr_dict) = multifrequency_opf(
      mn_data,
      output_folder,
      obj,
      gen_areas,
      area_interface,
      gen_zones,
      zone_interface,
      print_results,
      override_param,
      fix_f_override,
      direct_pq,
      master_subnet,
      start_vals,
      uniform_gen_scaling,
      unbounded_pg,
      output_to_files
      )

      return (output_dict, res_summary, solution_pm, binding_cnstr_dict)
   end

   function multifrequency_opf(
      folder::String,
      obj::String,
      gen_areas,
      area_interface,
      gen_zones,
      zone_interface,
      print_results::Bool,
      override_param::Dict{Any}=Dict(),
      fix_f_override::Bool=false,
      direct_pq::Bool=true,
      master_subnet::Int64=1,
      suffix::String="",
      start_vals=Dict{String, Dict}("sn"=>Dict())
      )

      (output_dict, res_summary, solution_pm, binding_cnstr_dict) = multifrequency_opf(
         folder,
         obj;
         gen_areas=gen_areas,
         area_interface=area_interface,
         gen_zones=gen_zones,
         zone_interface=zone_interface,
         print_results=print_results,
         override_param=override_param,
         fix_f_override=fix_f_override,
         direct_pq=direct_pq,
         master_subnet=master_subnet,
         suffix=suffix,
         start_vals=start_vals,
      )

      return (output_dict, res_summary, solution_pm, binding_cnstr_dict)
   end

   function multifrequency_opf(
      mn_data::Dict{String,Any},
      output_folder::String,
      obj::String,
      gen_areas=[],
      area_interface=[],
      gen_zones=[],
      zone_interface=[],
      print_results::Bool=false,
      override_param::Dict{Any}=Dict(),
      fix_f_override::Bool=false,
      direct_pq::Bool=true,
      master_subnet::Int64=1,
      start_vals=Dict{String, Dict}("sn"=>Dict()),
      uniform_gen_scaling::Bool=false,
      unbounded_pg::Bool=false,
      output_to_files::Bool=true
      )

   # If direct_pq is false, then interface flow respects Kirchoff
   # Laws, constraining the voltage magnitude and angle on each side to be equal
   # and enforcing reactive power balance.
   # If false, the angle reference must be defined for only
   # one subnetwork, since the other subnetwork angles are coupled through the
   # interfaces. This "master subnet" is defined by input master_subnet

   # If fix_f_override is true, all subnetwork frequencies will be fixed,
   # regardless of what's specified in the subnetworks file

   # Instantiate a Solver
   #---------------------
   # pass options to IPOPT
   # make sure IPOPT logs to file so we can grep time, residuals and number of iterations
   ipopt_print_level = 0
   ipopt_log_to_file = true
   ipopt_file_log_level = 3
   ipopt_log_file = "$output_folder/ipopt_log"
   ipopt_max_iter = 20000
   if ipopt_log_to_file
      0 < ipopt_file_log_level < 3 && @warn("`file_print_level` should be 0 or ≥ 3 for IPOPT to report elapsed time, final residuals and number of iterations")
   end

   # Callback
   # callback === nothing || setIntermediateCallback(model, callback)
   nlp_optimizer = optimizer_with_attributes(
      Ipopt.Optimizer,
      "print_level" =>  ipopt_print_level,
      "output_file"=> ipopt_log_file,
      "file_print_level" => ipopt_file_log_level,
      "max_iter" => ipopt_max_iter
   )
   PowerModels.logger_config!("error")
   # nlp_optimizer = with_optimizer(Ipopt.Optimizer)
   # note: print_level changes the amount of solver information printed to the terminal

      # Add fix_f_override to override_params if true
   if fix_f_override
      for (subnet_idx, subnet) in mn_data["sn"]
         set_nested!(override_param, ["sn","$subnet_idx","variable_f"], false)
      end
   end

   # if any override parameter subnetwork index has a value of -1, apply it to all variable frequency networks
   if "sn" in keys(override_param)
      if "-1" in keys(override_param["sn"])
         subdict = pop!(override_param["sn"],"-1")
         for (subnet_idx, subnet) in mn_data["sn"]
            if subnet["variable_f"]
               override_param["sn"]["$subnet_idx"] = deepcopy(subdict)
               # println("Set override of subnet $subnet_idx to $subdict")
            end
         end
      end
   end

   # if any override parameters exist in the override_param dictionary, apply them
   combine_nested!(mn_data, override_param)

   if output_to_files
      stringnet = JSON.json(mn_data)
      open("$output_folder/network_data.json", "w") do f
         write(f, stringnet)
      end
   end
   # use build_ref to filter out inactive components
   ref = Dict{Int64,Any}()
   for (subnet_idx,subnet) in mn_data["sn"]
      subnet_idx_int = parse(Int64,subnet_idx)

      ref_temp = PowerModels.build_ref(subnet)
      if :it in keys(ref_temp)
         ref[subnet_idx_int] = ref_temp[:it][:pm][:nw][0]
      else
         ref[subnet_idx_int] = ref_temp[:nw][0]
      end

   end

   # note: ref contains all the relevant system parameters needed to build the OPF model
   # and it is a Dict with the ref data for each subnetwork
   # When we introduce constraints and variable bounds below, we use the parameters in ref.


   # Export ref to file for debugging
   if output_to_files
      println("Set ref data. Saving JSON.")
      stringref = JSON.json(ref)
      open("$output_folder/ref_data.json", "w") do f
         write(f, stringref)
      end
   end

   # Use this to print any generators which have intial values outside their limits
   print_init_gen_viol = false
   if print_init_gen_viol
      for (subnet_idx, ref_subnet) in ref
         for (i,gen) in ref_subnet[:gen]
            if gen["pg"] > gen["pmax"]
               println("gen $(gen["index"]) at bus $(gen["gen_bus"]): pg = $(gen["pg"]);\t pmax = $(gen["pmax"])\t (status = $(gen["gen_status"]))")
            end
         end
      end
   end

   # print_summary(mn_data["sn"]["1"])
   ###############################################################################
   # 1. Building the Optimal Power Flow Model
   ###############################################################################


   # Initialize a JuMP Optimization Model
   #-------------------------------------
   t_start = time_ns()
   model = Model(nlp_optimizer)

   va = Dict{Int64,Any}()
   vm = Dict{Int64,Any}()
   pg = Dict{Int64,Any}()
   qg = Dict{Int64,Any}()
   p = Dict{Int64,Any}()
   q = Dict{Int64,Any}()
   p_dc = Dict{Int64,Any}()
   q_dc = Dict{Int64,Any}()
   g = Dict{Int64,Any}()
   b = Dict{Int64,Any}()
   b_fr = Dict{Int64,Any}()
   b_to = Dict{Int64,Any}()
   g_fr = Dict{Int64,Any}()
   g_to = Dict{Int64,Any}()
   l_series = Dict{Int64,Any}()
   c_inv_series = Dict{Int64,Any}()
   f = Dict{Int64,Any}()
   b_shunt = Dict{Int64,Any}()
   cost_pg = Dict{Int64,Any}()
   cost_dcline = Dict{Int64,Any}()
   area_pg = Dict{Int64,Any}()
   zone_pg = Dict{Int64,Any}()
   redispatch_pg = Dict{Int64,Any}()
   redispatch_qg = Dict{Int64,Any}()
   redispatch_vm = Dict{Int64,Any}()
   redispatch_va = Dict{Int64,Any}()
   p_i = Dict{Int64,Any}()
   q_i = Dict{Int64,Any}()
   s_i = Dict{Int64,Any}()
   i_rms_sq = Dict{Int64,Any}()
   i_mabs = Dict{Int64,Any}()
   i_dc = Dict{Int64,Any}()
   s_M = Dict{Int64,Any}()
   conv_loss = Dict{Int64,Any}()

   # constraint references
   constraints = Dict{Symbol,Any}(
      :vm_ulim     => Dict{Int64,Any}(),
      :vm_llim     => Dict{Int64,Any}(),
      :pg_ulim     => Dict{Int64,Any}(),
      :pg_llim     => Dict{Int64,Any}(),
      :qg_ulim     => Dict{Int64,Any}(),
      :qg_llim     => Dict{Int64,Any}(),
      :s_ulim      => Dict{Int64,Any}(),
      :s_llim      => Dict{Int64,Any}(),
      :theta_llim  => Dict{Int64,Any}(),
      :theta_ulim  => Dict{Int64,Any}(),
      :theta_ref  => Dict{Int64,Any}()
   )

   for (subnet_idx, ref_subnet) in ref
      add_vars!(
         mn_data,
         ref_subnet,
         subnet_idx,
         model,
         va, vm, pg, qg, p, q, p_dc, q_dc, g, b, b_fr, b_to, g_fr, g_to, l_series,
         c_inv_series, f, b_shunt, cost_pg, cost_dcline, area_pg, zone_pg, redispatch_pg,
         redispatch_qg, redispatch_vm, redispatch_va, p_i, q_i,
         constraints,
         )
   end
   # Add converter interface variables and constraints
   for (conv_idx, conv_params) in mn_data["converter"]
      p_i[conv_idx] = @variable(
         model,
         [(subnet, bus) in conv_params["converter_buses"]],
         base_name = "p_i_$(conv_idx)",
      )

      q_i[conv_idx] = @variable(
         model,
         [(subnet, bus) in conv_params["converter_buses"]],
         base_name = "q_i_$(conv_idx)",
      )
      for (subnet, bus) in conv_params["converter_buses"]
         smax = ref[subnet][:bus][bus]["converter_vmax"][conv_idx]*ref[subnet][:bus][bus]["converter_imax"][conv_idx]
         set_lower_bound(p_i[conv_idx][(subnet, bus)], -smax)
         set_upper_bound(p_i[conv_idx][(subnet, bus)], smax)
         set_lower_bound(q_i[conv_idx][(subnet, bus)], -smax)
         set_upper_bound(q_i[conv_idx][(subnet, bus)], smax)
      end

      # Keep track of DC subnets connected to the converter in conv_dc_subnets
      # so that they can be excluded from the loss model (the loss parameters
      # for an AC-DC converter should be applied only on the AC side)
      conv_dc_subnets = []
      for (subnet, bus) in conv_params["converter_buses"]
         dc_subnet = ((!ref[subnet][:variable_f]) && (ref[subnet][:f_base] == 0))
         if (:f_max in keys(ref[subnet]))
            # Also DC if max frequency is 0
            dc_subnet = dc_subnet || (ref[subnet][:f_max] == 0)
         end
         if dc_subnet
            push!(conv_dc_subnets, subnet)
         end
      end

      i_rms_sq[conv_idx] = @variable(
         model,
         [(subnet, bus) in conv_params["converter_buses"]],
         base_name = "i_rms_sq_$(conv_idx)",
         lower_bound = 0
      )
      for (subnet, bus) in conv_params["converter_buses"]
         if !(subnet in conv_dc_subnets)
            if (ref[subnet][:bus][bus]["converter_c1"][conv_idx] == 0) &&
                  (ref[subnet][:bus][bus]["converter_sw1"][conv_idx] == 0)
               @constraint(
                  model,
                  i_rms_sq[conv_idx][(subnet, bus)] == 0
               )
            else
               M = ref[subnet][:bus][bus]["converter_M"][conv_idx]
               p_im = p_i[conv_idx][(subnet, bus)]
               q_im = q_i[conv_idx][(subnet, bus)]
               v_i = vm[subnet][bus]
               @NLconstraint(
                  model,
                  i_rms_sq[conv_idx][(subnet, bus)] == (
                     M^2*p_im^2 / (18*v_i^2)
                     + (p_im^2 + q_im^2) / (36*v_i^2)
                     )
               )
            end
         end
      end

      # Interface power balance, including converter loss as a linear constraint if all c1, c2, c3, sw1, sw2, sw3 are not all zero
      if all(all(values(ref[subnet][:bus][bus]["converter_c1"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            all(all(values(ref[subnet][:bus][bus]["converter_c2"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            all(all(values(ref[subnet][:bus][bus]["converter_c3"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            all(all(values(ref[subnet][:bus][bus]["converter_sw1"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            all(all(values(ref[subnet][:bus][bus]["converter_sw2"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            all(all(values(ref[subnet][:bus][bus]["converter_sw3"][conv_idx]) .== 0) for (subnet, bus) in conv_params["converter_buses"]) &&
            false
         @constraint(
            model,
            sum(p_i[conv_idx][(subnet, bus)]
                for (subnet, bus) in conv_params["converter_buses"] if !(subnet in conv_dc_subnets)) == 0
         )
      else
      # Interface power balance, including converter loss parameterized by Λ, B, Γ, as a nonlinear constraint if any Λ, B, Γ are nonzero
         # s_i[conv_idx] = @variable(
         #    model,
         #    [(subnet, bus) in conv_params["converter_buses"]],
         #    base_name = "s_i_$(conv_idx)",
         #    lower_bound = 0,
         # )
         # for (subnet, bus) in conv_params["converter_buses"]
         #    if !(subnet in conv_dc_subnets)
         #       if (ref[subnet][:bus][bus]["converter_c2"][conv_idx] != 0) ||
         #             (ref[subnet][:bus][bus]["converter_sw2"][conv_idx] != 0)
         #          @constraint(
         #             model,
         #             p_i[conv_idx][(subnet, bus)]^2 + q_i[conv_idx][(subnet, bus)]^2 == s_i[conv_idx][(subnet, bus)]^2
         #          )
         #       end
         #    end
         # end
         # @NLconstraint(
         #    model,
         #    sum(p_i[conv_idx][(subnet, bus)]
         #        for (subnet, bus) in conv_params["converter_buses"])
         #    + sum(ref[subnet][:bus][bus]["converter_lambda"][conv_idx]*s_i[conv_idx][(subnet, bus)]
         #          for (subnet, bus) in conv_params["converter_buses"] if !(subnet in conv_dc_subnets))
         #    + sum(ref[subnet][:bus][bus]["converter_beta"][conv_idx]*s_i[conv_idx][(subnet, bus)]/vm[subnet][bus]
         #          for (subnet, bus) in conv_params["converter_buses"] if !(subnet in conv_dc_subnets))
         #    + sum(ref[subnet][:bus][bus]["converter_gamma"][conv_idx]*s_i[conv_idx][(subnet, bus)]^2/vm[subnet][bus]^2
         #          for (subnet, bus) in conv_params["converter_buses"] if !(subnet in conv_dc_subnets))
         #    == 0
         # )


         i_mabs[conv_idx] = @variable(
            model,
            [(subnet, bus) in conv_params["converter_buses"]],
            base_name = "i_mabs_$(conv_idx)",
            lower_bound = 0
         )

         if !(conv_idx in keys(s_M))
            s_M[conv_idx] = Dict{Any,Any}()
         end
         if !(conv_idx in keys(s_i))
            s_i[conv_idx] = Dict{Any,Any}()
         end
         for (subnet, bus) in conv_params["converter_buses"]
            if !(subnet in conv_dc_subnets)
               if (ref[subnet][:bus][bus]["converter_c2"][conv_idx] == 0) &&
                     (ref[subnet][:bus][bus]["converter_sw2"][conv_idx] == 0)
                  @constraint(
                     model,
                     i_mabs[conv_idx][(subnet, bus)] == 0
                  )
               else
                  s_i[conv_idx][(subnet, bus)] = @variable(
                        model,
                        base_name = "s_i_$(conv_idx)_$(subnet)_$(bus)",
                        lower_bound = 0,
                     )
                  @constraint(
                     model,
                     p_i[conv_idx][(subnet, bus)]^2 + q_i[conv_idx][(subnet, bus)]^2 == s_i[conv_idx][(subnet, bus)]^2
                  )
                  M = ref[subnet][:bus][bus]["converter_M"][conv_idx]
                  p_im = p_i[conv_idx][(subnet, bus)]
                  q_im = q_i[conv_idx][(subnet, bus)]
                  v_i = vm[subnet][bus]
                  if M == 1
                     # @NLconstraint(
                     #    model,
                     #    i_mabs[conv_idx][(subnet, bus)] ==
                     #    sqrt(2)/(3*pi*v_i)*(
                     #       p_im^2/s_i[conv_idx][(subnet, bus)]
                     #       - sqrt(q_im^2)
                     #       )
                     # )
                     # @NLconstraint(
                     #    model,
                     #    i_mabs[conv_idx][(subnet, bus)] ==
                     #    sqrt(2)/(3*pi*v_i)*(
                     #       p_im - q_im
                     #       )
                     # )
                     # s_M[conv_idx][(subnet, bus)] = @variable(
                     #       model,
                     #       base_name = "s_M_$(conv_idx)_$(subnet)_$(bus)",
                     #       lower_bound = 0,
                     #       upper_bound = ref[subnet][:bus][bus]["converter_vmax"][conv_idx]*ref[subnet][:bus][bus]["converter_imax"][conv_idx],
                     #    )
                     # @constraint(
                     #    model,
                     #    p_i[conv_idx][(subnet, bus)]^2*(1-ref[subnet][:bus][bus]["converter_M"][conv_idx]^2) + q_i[conv_idx][(subnet, bus)]^2 == s_M[conv_idx][(subnet, bus)]^2
                     # )
                     # @NLconstraint(
                     #    model,
                     #    i_mabs[conv_idx][(subnet, bus)] ==
                     #    2/(3*v_i*sqrt(2))*(
                     #       p_im^2/s_i[conv_idx][(subnet, bus)] + s_M[conv_idx][(subnet, bus)]
                     #       )
                     # )
                     @NLconstraint(
                        model,
                        i_mabs[conv_idx][(subnet, bus)] ==
                        2/(3*v_i*sqrt(2))*(
                           p_im^2/s_i[conv_idx][(subnet, bus)] + abs(q_im)
                           )
                     )
                  else
                     s_M[conv_idx][(subnet, bus)] = @variable(
                           model,
                           base_name = "s_M_$(conv_idx)_$(subnet)_$(bus)",
                           lower_bound = 0,
                           upper_bound = ref[subnet][:bus][bus]["converter_vmax"][conv_idx]*ref[subnet][:bus][bus]["converter_imax"][conv_idx],
                        )
                     @constraint(
                        model,
                        p_i[conv_idx][(subnet, bus)]^2*(1-ref[subnet][:bus][bus]["converter_M"][conv_idx]^2) + q_i[conv_idx][(subnet, bus)]^2 == s_M[conv_idx][(subnet, bus)]^2
                     )
                     # @NLconstraint(
                     #    model,
                     #    i_mabs[conv_idx][(subnet, bus)] ==
                     #    sqrt(2)/(3*pi*v_i)*(
                     #       M^2*p_im^2/s_i[conv_idx][(subnet, bus)]
                     #       - s_M[conv_idx][(subnet, bus)]
                     #       )
                     # )
                     # @NLconstraint(
                     #    model,
                     #    i_mabs[conv_idx][(subnet, bus)] ==
                     #    2/(3*v_i*sqrt(2))*(
                     #       M^2*p_im^2/s_i[conv_idx][(subnet, bus)] + s_M[conv_idx][(subnet, bus)]
                     #       )
                     # )

                     @NLconstraint(
                        model,
                        i_mabs[conv_idx][(subnet, bus)] ==
                        2/(3*v_i*sqrt(2))*(
                           M*p_im*(M*p_im/s_i[conv_idx][(subnet, bus)]) + s_M[conv_idx][(subnet, bus)]
                           )
                     )
                  end
               end
            end
         end

         i_dc[conv_idx] = @variable(
            model,
            [(subnet, bus) in conv_params["converter_buses"]],
            base_name = "i_dc$(conv_idx)",
            lower_bound = 0
         )
         for (subnet, bus) in conv_params["converter_buses"]
            if !(subnet in conv_dc_subnets)
               if (ref[subnet][:bus][bus]["converter_c3"][conv_idx] == 0) &&
                     (ref[subnet][:bus][bus]["converter_sw3"][conv_idx] == 0)
                  @constraint(
                     model,
                     i_dc[conv_idx][(subnet, bus)] == 0
                  )
               else
                  M = ref[subnet][:bus][bus]["converter_M"][conv_idx]
                  p_im = p_i[conv_idx][(subnet, bus)]
                  v_i = vm[subnet][bus]
                  @NLconstraint(
                     model,
                     i_dc[conv_idx][(subnet, bus)] == M*abs(p_im) / (sqrt(2) * v_i)
                  )
               end
            end
         end

         conv_loss[conv_idx] = @variable(
            model,
            base_name = "conv_loss_$(conv_idx)",
            lower_bound = 0
         )

         # Interface power balance
         @constraint(
            model,
            conv_loss[conv_idx] == 6*(
               sum(ref[subnet][:bus][bus]["converter_c1"][conv_idx]*i_rms_sq[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"])
               + sum(ref[subnet][:bus][bus]["converter_c2"][conv_idx]*i_mabs[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"])
               + sum(ref[subnet][:bus][bus]["converter_c3"][conv_idx]*i_dc[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"])
               + sum(ref[subnet][:bus][bus]["converter_sw1"][conv_idx]*i_rms_sq[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"])
               + sum(ref[subnet][:bus][bus]["converter_sw2"][conv_idx]*i_mabs[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"])
               + sum(ref[subnet][:bus][bus]["converter_sw3"][conv_idx] for (subnet, bus) in conv_params["converter_buses"])
            )
         )

         @constraint(
            model,
            sum(p_i[conv_idx][(subnet, bus)] for (subnet, bus) in conv_params["converter_buses"]) + conv_loss[conv_idx] == 0
         )
      end
      # Converter current limits
      for (subnet, bus) in conv_params["converter_buses"]
         i_lim = ref[subnet][:bus][bus]["converter_imax"][conv_idx]
         if i_lim < Inf
            @constraint(
               model,
               i_rms_sq[conv_idx][(subnet, bus)] - i_lim^2*vm[subnet][bus]^2 <= 0
            )
         end
      end

      # Interface coupling of vm and va to model control of frequency alone (no direct PQ control)
      ############################################################################################
      if !direct_pq
         println("No direct PQ control")
         @constraint(
            model,
            sum(q_i[conv_idx[1]][(subnet, bus)]
                for (subnet, bus) in conv_params["converter_buses"]) == 0
         )
         for ((subnet1, bus1), (subnet2, bus2)) in combinations(conv_params["converter_buses"], 2)

            @constraint(
               model,
               vm[subnet1][bus1] == vm[subnet2][bus2]
            )
            @constraint(
               model,
               va[subnet1][bus1] == va[subnet2][bus2]
            )
         end
      end
      ############################################################################################

   end

   # Set apparent power limit for a 0 Hz system based on DC current,
   # incorporating constants k_ins and k_cond if true
   # If false, apply the same apparent power limit to the active power
   dc_current_limit = false

   for (subnet_idx, ref_subnet) in ref

      add_constraints!(
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

   end


   if uniform_gen_scaling
      println("APPLYING UNIFORM GENERATOR SCALING")
      (alpha_upstream,
      alpha_downstream) = add_gen_zone_scaling_constraint!(
         ref,
         model,
         pg,
         constraints,
         unbounded_pg,
         gen_zones
         )
   end

   # Set starting values if given
   # ----------------------------
   set_startvals!(
      start_vals,
      va, vm, pg, qg, p, q, f
      )


   # Add Objective Function
   # ----------------------
   if obj=="mincost"
      # Minimize the cost of active power generation and cost of HVDC line usage
      @objective(model, Min,
         sum(cost_pg[subnet_idx] for (subnet_idx, ref_subnet) in ref) +
         sum(cost_dcline[subnet_idx] for (subnet_idx, ref_subnet) in ref)
      )
   elseif obj=="minredispatch"
      # Minimize the deviations from the base case dispatch
      @objective(model, Min,
         sum(redispatch_pg[subnet_idx] for (subnet_idx, ref_subnet) in ref) +
         # sum(redispatch_qg[subnet_idx] for (subnet_idx, ref_subnet) in ref) +
         1e9*sum(redispatch_vm[subnet_idx] for (subnet_idx, ref_subnet) in ref)
         # sum(redispatch_va[subnet_idx] for (subnet_idx, ref_subnet) in ref)
      )
   elseif obj=="areagen"
      # Minimize the generation in the specified areas
      @objective(model, Min,
         sum(area_pg[subnet_idx] for (subnet_idx, ref_subnet) in ref)
      )
   elseif obj=="zonegen"
      # Minimize the generation in the specified zones
      @objective(model, Min,
         sum(zone_pg[subnet_idx] for (subnet_idx, ref_subnet) in ref)
      )
   else
      println("The specified objective has not been implemented. Using minumum cost as the objective.")
      obj = "mincost"
      # Minimize the cost of active power generation and cost of HVDC line usage
      @objective(model, Min,
         sum(cost_pg[subnet_idx] for (subnet_idx, ref_subnet) in ref) +
         sum(cost_dcline[subnet_idx] for (subnet_idx, ref_subnet) in ref)
      )
   end

   #########################################
   # 2. Solve the Optimal Power Flow Model #
   #########################################
   # Solve the optimization problem
   open("$output_folder/model.lp", "w") do f
      print(f, model)
   end

   optimize!(model)

   t_end = time_ns()
   t_build_solve = (t_end - t_start)/1e9
   # Check that the solver terminated without an error
   println("The solver termination status is $(termination_status(model))")

   ipopt_output = readlines(ipopt_log_file)

   cpu_time = 0.0
   dual_feas = primal_feas = Inf
   iter = -1
   for line in ipopt_output
      if occursin("CPU secs", line)
         cpu_time += Meta.parse(split(line, "=")[2])
      elseif occursin("Dual infeasibility", line)
         dual_feas = Meta.parse(split(line)[4])
      elseif occursin("Constraint violation", line)
         primal_feas = Meta.parse(split(line)[4])
      elseif occursin("Number of Iterations....", line)
         iter = Meta.parse(split(line)[4])
      end
   end

   #########################
   # 3. Review the Results #
   #########################

   # Save the resulting setpoints in PowerModels format
   solution_pm = deepcopy(mn_data)
   for (subnet_idx, ref_subnet) in ref
      for (i,gen) in ref_subnet[:gen]
         solution_pm["sn"]["$subnet_idx"]["gen"]["$i"]["pg"] = value(pg[subnet_idx][gen["index"]])
         solution_pm["sn"]["$subnet_idx"]["gen"]["$i"]["qg"] = value(qg[subnet_idx][gen["index"]])
      end
      for (i,bus) in ref_subnet[:bus]
         solution_pm["sn"]["$subnet_idx"]["bus"]["$i"]["vm"] = value(vm[subnet_idx][bus["bus_i"]])
         solution_pm["sn"]["$subnet_idx"]["bus"]["$i"]["va"] = value(va[subnet_idx][bus["bus_i"]])
      end
      for (i,branch) in ref_subnet[:branch]
         f_idx = (i, branch["f_bus"], branch["t_bus"])
         t_idx = (i, branch["t_bus"], branch["f_bus"])
         solution_pm["sn"]["$subnet_idx"]["branch"]["$i"]["pf"] = value(p[subnet_idx][f_idx])
         solution_pm["sn"]["$subnet_idx"]["branch"]["$i"]["pt"] = value(p[subnet_idx][t_idx])
         solution_pm["sn"]["$subnet_idx"]["branch"]["$i"]["qf"] = value(q[subnet_idx][f_idx])
         solution_pm["sn"]["$subnet_idx"]["branch"]["$i"]["qt"] = value(q[subnet_idx][t_idx])
         va_fr = va[subnet_idx][branch["f_bus"]]
         va_to = va[subnet_idx][branch["t_bus"]]
         solution_pm["sn"]["$subnet_idx"]["branch"]["$i"]["angle"] = value(va_fr) - value(va_to)
      end
      for (i,dcline) in ref_subnet[:dcline]
         f_idx = (i, dcline["f_bus"], dcline["t_bus"])
         t_idx = (i, dcline["t_bus"], dcline["f_bus"])
         solution_pm["sn"]["$subnet_idx"]["dcline"]["$i"]["pf"] = value(p_dc[subnet_idx][f_idx])
         solution_pm["sn"]["$subnet_idx"]["dcline"]["$i"]["pt"] = value(p_dc[subnet_idx][t_idx])
         solution_pm["sn"]["$subnet_idx"]["dcline"]["$i"]["qf"] = value(q_dc[subnet_idx][f_idx])
         solution_pm["sn"]["$subnet_idx"]["dcline"]["$i"]["qt"] = value(q_dc[subnet_idx][t_idx])
      end
   end
   # Export network to file for debugging
   if output_to_files
      println("Wrote solution to PowerModels network. Saving JSON.")
      stringnet = JSON.json(solution_pm)
      open("$output_folder/network_solved.json", "w") do f
         write(f, stringnet)
      end
   end

   # Check the value of the objective function
   objval = objective_value(model)
   println("The objective value is $(objval).")

   println("CPU time (s): $cpu_time")
   println("Dual infeasibility: $dual_feas")
   println("Constraint violation: $primal_feas")
   println("Iterations: $iter")

   # cost = (sum(value(cost_pg[subnet_idx]) for (subnet_idx, ref_subnet) in ref) +
   #         sum(value(cost_dcline[subnet_idx]) for (subnet_idx, ref_subnet) in ref)
   #         )


   # total_load = sum(sum(ref_subnet[:load][l] for l in ref_subnet[:bus_loads][i]) for (i,bus) in ref_subnet[:bus])
   res_summary = Dict{Int64, DataFrame}()

   # Define arrays for summary table
   n_subnets = length(ref)
   subnets_arr=Array{Int64}(undef, n_subnets)
   f_arr=Array{Float64}(undef, n_subnets)
   fmin_arr=Array{Float64}(undef, n_subnets)
   fmax_arr=Array{Float64}(undef, n_subnets)
   min_v_arr=Array{Float64}(undef, n_subnets)
   max_v_arr=Array{Float64}(undef, n_subnets)
   avg_v_arr=Array{Float64}(undef, n_subnets)
   ngen_Qll_arr=Array{Int64}(undef, n_subnets)
   ngen_Qul_arr=Array{Int64}(undef, n_subnets)
   ngen_arr=Array{Int64}(undef, n_subnets)
   minQloss_arr=Array{Float64}(undef, n_subnets)
   maxQloss_arr=Array{Float64}(undef, n_subnets)
   n_negQloss_arr=Array{Int64}(undef, n_subnets)
   n_s_bound_arr=Array{Int64}(undef, n_subnets)
   max_ang_diff_arr=Array{Float64}(undef, n_subnets)
   min_ang_diff_arr=Array{Float64}(undef, n_subnets)
   nbranch_arr=Array{Int64}(undef, n_subnets)
   loss_arr=Array{Float64}(undef, n_subnets)
   cost_arr=Array{Float64}(undef, n_subnets)
   obj_arr=Array{Float64}(undef, n_subnets)
   time_s_arr=Array{Float64}(undef, n_subnets)
   status_arr=Array{TerminationStatusCode}(undef, n_subnets)
   subnet_load=Array{Float64}(undef, n_subnets)
   subnet_generation=Array{Float64}(undef, n_subnets)
   subnet_line_loss=Array{Float64}(undef, n_subnets)
   subnet_total_loss=Array{Float64}(undef, n_subnets)
   converter_loss=Array{Float64}(undef, n_subnets)

   summary_idx = 1
   for (subnet_idx, ref_subnet) in ref
      print("\nsubnetwork $(subnet_idx)\n================\n")
      freq_res = ref_subnet[:variable_f] ? value(f[subnet_idx]) : ref_subnet[:f_base]
      freq_min = ref_subnet[:variable_f] ? ref_subnet[:f_min] : ref_subnet[:f_base]
      freq_max = ref_subnet[:variable_f] ? ref_subnet[:f_max] : ref_subnet[:f_base]
      println("frequency: $(freq_res) Hz\n================\n")
      # Iterate over buses
      bus_load = Dict{Int64,Any}()
      # gen_string = "\ngen output\ngen,\tbus,\tp,\tq\n"
      # bus_string = "\nbus voltage\nbus,\tvm,\tva\n"

      # Define arrays for bus table
      n_bus = length(ref_subnet[:bus])
      bus_arr = Array{Int64}(undef, n_bus)
      vm_arr = Array{Float64}(undef, n_bus)
      va_arr = Array{Float64}(undef, n_bus)
      vmin_arr = Array{Float64}(undef, n_bus)
      vmax_arr = Array{Float64}(undef, n_bus)

      # Define arrays for gen table
      n_gen = length(ref_subnet[:gen])
      gen_arr = Array{Int64}(undef, n_gen)
      gen_bus_arr = Array{Int64}(undef, n_gen)
      p_arr = Array{Float64}(undef, n_gen)
      pmin_arr = Array{Float64}(undef, n_gen)
      pmax_arr = Array{Float64}(undef, n_gen)
      q_arr = Array{Float64}(undef, n_gen)
      qmin_arr = Array{Float64}(undef, n_gen)
      qmax_arr = Array{Float64}(undef, n_gen)
      pbase_arr = Array{Float64}(undef, n_gen)
      qbase_arr = Array{Float64}(undef, n_gen)

      bus_idx = 1
      gen_i = 1
      for (i,bus) in ref_subnet[:bus]
         # println("bus_idx: $bus_idx")
         bus_arr[bus_idx] = bus["index"]
         # println("bus[\"index\"]: $(bus["index"])")
         vm_arr[bus_idx] = value(vm[subnet_idx][i])
         va_arr[bus_idx] = value(va[subnet_idx][i]) * 180/pi
         vmin_arr[bus_idx] = bus["vmin"]
         vmax_arr[bus_idx] = bus["vmax"]
         # bus_string *= "$i,\t$(vm_tmp),\t$(va_tmp)\n"
         busgens = ref_subnet[:bus_gens][i]
         for gen_idx in busgens
            # println("gen_i: $gen_i")
            # println("gen_idx: $gen_idx")
            gen_arr[gen_i] = gen_idx
            # println("bus[\"index\"]: $(bus["index"])")
            gen_bus_arr[gen_i] = bus["index"]
            p_arr[gen_i] = value(pg[subnet_idx][gen_idx])
            q_arr[gen_i] = value(qg[subnet_idx][gen_idx])
            pmin_arr[gen_i] = ref_subnet[:gen][gen_idx]["pmin"]
            pmax_arr[gen_i] = ref_subnet[:gen][gen_idx]["pmax"]
            qmin_arr[gen_i] = ref_subnet[:gen][gen_idx]["qmin"]
            qmax_arr[gen_i] = ref_subnet[:gen][gen_idx]["qmax"]
            pbase_arr[gen_i] = ref_subnet[:gen][gen_idx]["pg"]
            qbase_arr[gen_i] = ref_subnet[:gen][gen_idx]["qg"]
            # gen_string *= "$(gen_idx),\t$i,\t$(pg_tmp),\t$(qg_tmp)\n"
            gen_i += 1
         end
         busloads = ref_subnet[:bus_loads][i]
         if !isempty(busloads)
            bus_load[i] = sum([ref_subnet[:load][l]["pd"] for l in busloads])
         end
         bus_idx += 1
      end
      bus_df = DataFrame(
         bus = bus_arr, vm = vm_arr, va = va_arr, vmin = vmin_arr, vmax = vmax_arr
      )
      gen_df = DataFrame(
         gen = gen_arr, bus = gen_bus_arr, pg = p_arr, qg = q_arr,
         pgmin = pmin_arr, pgmax = pmax_arr, qgmin = qmin_arr, qgmax = qmax_arr,
         pbase = pbase_arr, qbase = qbase_arr
      )

      # Iterate over branches
      n_branch = length(ref_subnet[:branch])

      # Define arrays for branch table
      branch_arr = Array{Int64}(undef, n_branch)
      from_bus_arr = Array{Int64}(undef, n_branch)
      to_bus_arr = Array{Int64}(undef, n_branch)
      B_arr = Array{Float64}(undef, n_branch)
      G_arr = Array{Float64}(undef, n_branch)
      Xseries_arr = Array{Float64}(undef, n_branch)
      Bfr_arr = Array{Float64}(undef, n_branch)
      Bto_arr = Array{Float64}(undef, n_branch)
      Gfr_arr = Array{Float64}(undef, n_branch)
      Gto_arr = Array{Float64}(undef, n_branch)
      rate_a_arr = Array{Float64}(undef, n_branch)
      p_from_arr = Array{Float64}(undef, n_branch)
      p_to_arr = Array{Float64}(undef, n_branch)
      p_loss_arr = Array{Float64}(undef, n_branch)
      q_from_arr = Array{Float64}(undef, n_branch)
      q_to_arr = Array{Float64}(undef, n_branch)
      q_loss_arr = Array{Float64}(undef, n_branch)
      s_from_arr = Array{Float64}(undef, n_branch)
      s_to_arr = Array{Float64}(undef, n_branch)
      angle_diff_arr = Array{Float64}(undef, n_branch)
      angle_min_arr = Array{Float64}(undef, n_branch)
      angle_max_arr = Array{Float64}(undef, n_branch)
      for (i,(idx,branch)) in enumerate(ref_subnet[:branch])
         branch_arr[i] = idx
         from_bus_arr[i] = branch["f_bus"]
         to_bus_arr[i] = branch["t_bus"]
         rate_a_arr[i] = "rate_a" in keys(branch) ? branch["rate_a"] : Inf
         B_arr[i] = typeof(b[subnet_idx][idx])==VariableRef ? value(b[subnet_idx][idx]) : b[subnet_idx][idx]
         G_arr[i] = typeof(g[subnet_idx][idx])==VariableRef ? value(g[subnet_idx][idx]) : g[subnet_idx][idx]
         Xseries_arr[i] = ref_subnet[:variable_f] ? (value(f[subnet_idx])*2pi*l_series[subnet_idx][idx] - c_inv_series[subnet_idx][idx]/(value(f[subnet_idx])*2pi)) : branch["br_x"]

         Bfr_arr[i] = typeof(b_fr[subnet_idx][idx])==VariableRef ? value(b_fr[subnet_idx][idx]) : b_fr[subnet_idx][idx]
         Bto_arr[i] = typeof(b_to[subnet_idx][idx])==VariableRef ? value(b_to[subnet_idx][idx]) : b_to[subnet_idx][idx]
         Gfr_arr[i] = typeof(g_fr[subnet_idx][idx])==VariableRef ? value(g_fr[subnet_idx][idx]) : g_fr[subnet_idx][idx]
         Gto_arr[i] = typeof(g_to[subnet_idx][idx])==VariableRef ? value(g_to[subnet_idx][idx]) : g_to[subnet_idx][idx]
         f_idx = (idx, branch["f_bus"], branch["t_bus"])
         t_idx = (idx, branch["t_bus"], branch["f_bus"])
         p_from_arr[i] = value(p[subnet_idx][f_idx])
         q_from_arr[i] = value(q[subnet_idx][f_idx])
         p_to_arr[i] = value(p[subnet_idx][t_idx])
         q_to_arr[i] = value(q[subnet_idx][t_idx])
         s_from_arr[i] = sqrt(p_from_arr[i]^2 + q_from_arr[i]^2)
         s_to_arr[i] = sqrt(p_to_arr[i]^2 + q_to_arr[i]^2)
         p_loss_arr[i] = abs(p_from_arr[i] + p_to_arr[i])
         q_loss_arr[i] = q_from_arr[i] + q_to_arr[i]
         angle_diff_arr[i] = (value(va[subnet_idx][branch["f_bus"]]) - value(va[subnet_idx][branch["t_bus"]])) * 180/pi
         angle_min_arr[i] = branch["angmin"] * 180/pi
         angle_max_arr[i] = branch["angmax"] * 180/pi
      end
      br_df = DataFrame(
         branch = branch_arr, from_bus = from_bus_arr, to_bus = to_bus_arr,
         X = Xseries_arr, B = B_arr, G = G_arr, Bfr = Bfr_arr, Bto = Bto_arr,
         # Gfr = Gfr_arr, Gto = Gto_arr,
         p_from = p_from_arr,
         p_to = p_to_arr, q_from = q_from_arr, q_to = q_to_arr,
         p_loss = p_loss_arr, q_loss = q_loss_arr, s_from = s_from_arr,
         s_to = s_to_arr, rate_a = rate_a_arr,
         ang_deg = angle_diff_arr, angmin = angle_min_arr, angmax = angle_max_arr,
      )

      # Sum of generation
      subnet_load[summary_idx] = sum(Float64[load for (i,load) in bus_load])
      subnet_generation[summary_idx] = sum(Float64[value(pg[subnet_idx][i]) for i in keys(ref_subnet[:gen])])
      # full_gen += total_generation
      subnet_line_loss[summary_idx] = sum(Float64[abs(value(p[subnet_idx][(i,br["f_bus"],br["t_bus"])]) + value(p[subnet_idx][(i,br["t_bus"],br["f_bus"])])) for (i,br) in ref_subnet[:branch]])
      subnet_total_loss[summary_idx] = subnet_generation[summary_idx] - subnet_load[summary_idx]

      converter_loss[summary_idx] = sum(Float64[value(conv_loss[conv_idx]) for (conv_idx, conv_params) in mn_data["converter"]])


      if print_results
         print("\nbus voltages\n$(bus_df)\n")
         print("\ngeneration\n$(gen_df)\n")
         print("\nbranch values\n$(br_df)\n")

         println("\ntotal load: $(subnet_load)")

         println("total subnet generation: $(subnet_generation)")
         println("total subnet losses: $(subnet_loss)")
      end

      if output_to_files
         CSV.write("$output_folder/res_bus_$subnet_idx.csv", bus_df)
         CSV.write("$output_folder/res_gen_$subnet_idx.csv", gen_df)
         CSV.write("$output_folder/res_branch_$subnet_idx.csv", br_df)
      end

      subnets_arr[summary_idx] = subnet_idx
      f_arr[summary_idx] = freq_res
      fmin_arr[summary_idx] = freq_min
      fmax_arr[summary_idx] = freq_max
      min_v_arr[summary_idx]=min(vm_arr...)
      max_v_arr[summary_idx]=max(vm_arr...)
      avg_v_arr[summary_idx]=mean(vm_arr)
      ngen_Qll_arr[summary_idx]=sum(q_arr .≈ qmin_arr)
      ngen_Qul_arr[summary_idx]=sum(q_arr .≈ qmax_arr)
      ngen_arr[summary_idx]=length(ref_subnet[:gen])
      minQloss_arr[summary_idx]=min(q_loss_arr...)
      ngen_arr[summary_idx]=length(ref_subnet[:gen])
      minQloss_arr[summary_idx]=min(q_loss_arr...)
      maxQloss_arr[summary_idx]=max(q_loss_arr...)
      n_negQloss_arr[summary_idx]=sum(q_loss_arr.<0.0)
      n_s_bound_arr[summary_idx]=sum((s_to_arr .≈ rate_a_arr) .| (s_from_arr .≈ rate_a_arr))
      max_ang_diff_arr[summary_idx]=max(angle_diff_arr...)
      min_ang_diff_arr[summary_idx]=min(angle_diff_arr...)
      nbranch_arr[summary_idx]=length(ref_subnet[:branch])
      cost_arr[summary_idx]=(value(cost_pg[subnet_idx]) + value(cost_dcline[subnet_idx]))
      obj_arr[summary_idx]=objval
      time_s_arr[summary_idx]=t_build_solve
      status_arr[summary_idx]=termination_status(model)
      summary_idx += 1
   end
   res_summary = DataFrame(
      subnet=subnets_arr,
      f=f_arr, fmin=fmin_arr, fmax=fmax_arr,
      min_v=min_v_arr, max_v=max_v_arr, avg_v=avg_v_arr,
      ngen_Qll=ngen_Qll_arr, ngen_Qul=ngen_Qul_arr,
      ngen=ngen_arr, minQloss=minQloss_arr,
      maxQloss=maxQloss_arr, n_negQloss=n_negQloss_arr,
      n_s_bound=n_s_bound_arr,
      max_ang_diff=max_ang_diff_arr, min_ang_diff=min_ang_diff_arr,
      nbranch=nbranch_arr,
      total_loss=subnet_total_loss,
      converter_loss=converter_loss,
      cost=cost_arr,
      objective=obj_arr,
      time_s=time_s_arr,
      status=status_arr
   )
   if output_to_files
      CSV.write("$output_folder/res_summary.csv", res_summary)
   end

   tot_load = 0.0
   tot_gen = 0.0
   tot_shunt_p = 0.0
   tot_branch_loss = 0.0
   tot_interface_p = 0.0
   tot_dc_loss = 0.0
   tot_bus_flow = 0.0
   for (subnet_idx, ref_subnet) in ref
      sn_load = 0.0
      sn_gen = 0.0
      sn_shunt_p = 0.0
      sn_branch_loss = 0.0
      sn_interface_p = 0.0
      sn_dc_loss = 0.0
      sn_bus_flow = 0.0
      for (i,bus) in ref_subnet[:bus]
         if haskey(bus, "converter_index")
            bus_interfaces = bus["converter_index"]
         else
            bus_interfaces = Array{Int64,1}()
         end
         bus_flows = sum(Float64[value(p[subnet_idx][a]) for a in ref_subnet[:bus_arcs][i]])
         bus_loads = [ref_subnet[:load][l] for l in ref_subnet[:bus_loads][i]]
         bus_shunts = [ref_subnet[:shunt][s] for s in ref_subnet[:bus_shunts][i]]
         bus_i_gen = sum(Float64[value(pg[subnet_idx][g]) for g in ref_subnet[:bus_gens][i]])                  # sum of active power generation at bus i
         bus_i_load = sum(Float64[load["pd"] for load in bus_loads])                                    # sum of active load consumption at bus i
         bus_i_shunt_p = sum(Float64[shunt["gs"] for shunt in bus_shunts])*value(vm[subnet_idx][i])^2   # sum of active shunt element injections at bus i
         bus_i_interface_p = sum(Float64[value(p_i[conv_idx][(subnet_idx, i)]) for (conv_idx,busi,busj) in bus_interfaces])
         bus_i_dc_p = sum(Float64[value(p_dc[subnet_idx][a_dc]) for a_dc in ref_subnet[:bus_arcs_dc][i]])
         sn_load += bus_i_load
         sn_gen += bus_i_gen
         sn_shunt_p += bus_i_shunt_p
         sn_interface_p += bus_i_interface_p
         sn_dc_loss += bus_i_dc_p
         sn_bus_flow += bus_flows
         bus_bal = -bus_flows+bus_i_gen+bus_i_interface_p-bus_i_shunt_p-bus_i_load-bus_i_dc_p
         if bus_bal > 1e-6
            println("Subnet $subnet_idx bus $i power balance: $(bus_bal)")
         end
      end
      subnet_br_loss = sum(Float64[abs(value(p[subnet_idx][(i,br["f_bus"],br["t_bus"])]) + value(p[subnet_idx][(i,br["t_bus"],br["f_bus"])])) for (i,br) in ref_subnet[:branch]])
      sn_branch_loss += subnet_br_loss
      if output_to_files
         open("$output_folder/balance_$(subnet_idx).csv", "w") do io
            write(io, "total load, $(sn_load)\ntotal generation, $(sn_gen)\ntotal shunt losses, $(sn_shunt_p)\ntotal branch losses, $(sn_branch_loss)\ntotal interface losses, $(sn_interface_p)\ntotal dc line losses, $(sn_dc_loss)\ntotal flow from buses, $(sn_bus_flow)")
         end
      end
      tot_load += sn_load
      tot_gen += sn_gen
      tot_shunt_p += sn_shunt_p
      tot_interface_p += sn_interface_p
      tot_dc_loss += sn_dc_loss
      tot_bus_flow += sn_bus_flow
   end
   if output_to_files
      open("$output_folder/balance_tot.csv", "w") do io
         write(io, "total load, $(tot_load)\ntotal generation, $(tot_gen)\ntotal shunt losses, $(tot_shunt_p)\ntotal branch losses, $(tot_branch_loss)\ntotal interface losses, $(tot_interface_p)\ntotal dc line losses, $(tot_dc_loss)\ntotal flow from buses, $(tot_bus_flow)")
      end
   end

   # Define arrays for interface table
   n_iface_bus = sum(Int64[length(interface["converter_buses"]) for (i,interface) in mn_data["converter"]])
   iface_arr = Array{Int64}(undef, n_iface_bus)
   subnet_arr = Array{Int64}(undef, n_iface_bus)
   bus_arr = Array{Int64}(undef, n_iface_bus)
   p_i_arr = Array{Float64}(undef, n_iface_bus)
   q_i_arr = Array{Float64}(undef, n_iface_bus)
   s_i_arr = Array{Float64}(undef, n_iface_bus)
   # Iterate over interfaces
   i = 1
   for (iface_idx,interface) in mn_data["converter"]
      for conv_bus in interface["converter_buses"]
         iface_arr[i] = iface_idx[1]
         subnet_arr[i] = conv_bus[1]
         bus_arr[i] = conv_bus[2]
         p_i_arr[i] = value(p_i[iface_idx][conv_bus])
         q_i_arr[i] = value(q_i[iface_idx][conv_bus])
         s_i_arr[i] = sqrt(p_i_arr[i]^2 + q_i_arr[i]^2)
         i += 1
      end
   end
   iface_df = DataFrame(
      interface = iface_arr, subnetwork = subnet_arr, bus = bus_arr,
      p_int = p_i_arr, q_int = q_i_arr, s_int = s_i_arr
   )
   if print_results
      print("\ninterface transfers\n$(iface_df)\n")

      # println("total system generation: $(full_gen)")
      # println("total system losses: $(full_loss)")
   end
   if output_to_files
      CSV.write("$output_folder/res_interfaces.csv", iface_df)
   end
   # Apply the PV bus changes and run the power flow
   # for (subnet_idx, ref_subnet) in ref
   #    for (i,bus) in ref_subnet[:bus]
   #       # println("bus $i:")
   #       # println("base value: $(mn_data["sn"]["$subnet_idx"]["bus"]["$(bus["index"])"]["vm"])")
   #       mn_data["sn"]["$subnet_idx"]["bus"]["$(bus["index"])"]["vm"] = value(vm[subnet_idx][i])
   #       # println("changed to: $(value(vm[subnet_idx][i]))")
   #    end
   #    for (i,gen) in ref_subnet[:gen]
   #       # println("gen $i:")
   #       # println("base value: $(mn_data["sn"]["$subnet_idx"]["gen"]["$(gen["index"])"]["pg"])")
   #       mn_data["sn"]["$subnet_idx"]["gen"]["$(gen["index"])"]["pg"] = value(pg[subnet_idx][i])
   #       # println("changed to: $(value(pg[subnet_idx][i]))")
   #    end
   # end
   # pm_1 = build_model(mn_data["sn"]["1"], ACPPowerModel, PowerModels.post_pf, setting = Dict("output" => Dict("branch_flows" => true)))
   # result = optimize_model!(pm_1, with_optimizer(Ipopt.Optimizer))
   # # result=run_pf(ref, ACPPowerModel, with_optimizer(Ipopt.Optimizer))
   # print_summary(result["solution"])
   # key = collect(keys(res_summary))[1]


   # Define output dictionary
   output_dict = Dict{String, Any}(
      "cost"=>cost_arr,
      "frequency (Hz)"=>f_arr,
      "subnet"=>[subnet_idx for (subnet_idx, ref_subnet) in ref],
      "status"=>termination_status(model),
      "total time (s)"=>t_build_solve,
      "CPU time (s)"=>cpu_time,
      "iterations"=>iter,
      "generation"=>subnet_generation,
      "total loss"=>subnet_total_loss,
      "line loss"=>subnet_line_loss,
      "converter loss"=>converter_loss
      )

   if obj=="areagen"
      areagen = [value(area_pg[subnet_idx]) for (subnet_idx, ref_subnet) in ref]
      n_areas = length(gen_areas)
      if n_areas > 1
         gen_areas_sorted = sort(gen_areas)
         gen_label = "generation in areas"
         for i in 1:(n_areas-2)
            gen_label *= " $(gen_areas_sorted[i]),"
         end
         gen_label *=  " $(gen_areas_sorted[end-1]) and $(gen_areas_sorted[end]) (p.u.)"
      else
         gen_label = "generation in areas $(gen_areas[1]) (p.u.)"
      end
      output_dict[gen_label] = areagen
   end

   if obj=="zonegen"
      zonegen = [value(zone_pg[subnet_idx]) for (subnet_idx, ref_subnet) in ref]
      n_zones = length(gen_zones)
      if n_zones > 1
         gen_zones_sorted = sort(gen_zones)
         gen_label = "generation in zones"
         for i in 1:(n_zones-2)
            gen_label *= " $(gen_zones_sorted[i]),"
         end
         gen_label *=  " $(gen_zones_sorted[end-1]) and $(gen_zones_sorted[end]) (p.u.)"
      else
         gen_label = "generation in zones $(gen_zones[1]) (p.u.)"
      end
      output_dict[gen_label] = zonegen
   end

   if length(area_interface) == 2
      boundary_p = zeros(Float64,length(ref))
      boundary_q = zeros(Float64,length(ref))
      boundary_s = Array{Float64}(undef, length(ref))
      boundary_s_rev = Array{Float64}(undef, length(ref))
      boundary_slack = Array{Float64}(undef, length(ref))
      boundary_p_rev = zeros(Float64,length(ref))
      boundary_q_rev = zeros(Float64,length(ref))
      boundary_capacity = zeros(Float64,length(ref))
      boundary_loss = Array{Float64}(undef, length(ref))
      for (i,(subnet_idx, ref_subnet)) in enumerate(ref)
         boundary_arcs = Array{Tuple{Int64,Int64,Int64},1}()
         boundary_arcs_reverse = Array{Tuple{Int64,Int64,Int64},1}()
         f_area_buses = filter(p->(last(p)["area"]==area_interface[1]),ref_subnet[:bus])
         # println("f_area_buses: $f_area_buses")
         # bus_arcs = getindex.(Ref(ref_subnet[:bus_arcs]), f_area_buses)
         for (idx, bus) in f_area_buses
            bus_arcs = ref_subnet[:bus_arcs][idx]
            for arc in bus_arcs
               if ref_subnet[:bus][arc[3]]["area"] == area_interface[2]
                  push!(boundary_arcs, arc)
                  push!(boundary_arcs_reverse, (arc[1],arc[3],arc[2]))
                  boundary_p[i] += value(p[subnet_idx][arc])
                  boundary_q[i] += value(q[subnet_idx][arc])
                  boundary_p_rev[i] += value(p[subnet_idx][(arc[1],arc[3],arc[2])])
                  boundary_q_rev[i] += value(q[subnet_idx][(arc[1],arc[3],arc[2])])
                  boundary_capacity[i] += ref[subnet_idx][:branch][arc[1]]["rate_a"] * ref[subnet_idx][:branch][arc[1]]["br_status"]
               end
            end
         end
         # println("boundary_arcs: $boundary_arcs")
         # println("boundary_p: $boundary_p")
         boundary_s[i] = sqrt(boundary_p[i]^2 + boundary_q[i]^2)
         boundary_s_rev[i] = sqrt(boundary_p_rev[i]^2 + boundary_q_rev[i]^2)
         boundary_slack[i] = boundary_capacity[i] - max(abs(boundary_s[i]), abs(boundary_s_rev[i]))
         boundary_loss[i] = abs(boundary_p[i] + boundary_p_rev[i])
      end
      output_dict["P flow from area $(area_interface[1]) to $(area_interface[2]) (p.u.)"] = boundary_p
      output_dict["P flow from area $(area_interface[2]) to $(area_interface[1]) (p.u.)"] = boundary_p_rev
      output_dict["Q flow from area $(area_interface[1]) to $(area_interface[2]) (p.u.)"] = boundary_q
      output_dict["Q flow from area $(area_interface[2]) to $(area_interface[1]) (p.u.)"] = boundary_q_rev
      output_dict["S flow from area $(area_interface[1]) to $(area_interface[2]) (p.u.)"] = boundary_s
      output_dict["S flow from area $(area_interface[2]) to $(area_interface[1]) (p.u.)"] = boundary_s_rev
      output_dict["S slack from area $(area_interface[1]) to $(area_interface[2]) (p.u.)"] = boundary_slack
      output_dict["S capacity from area $(area_interface[1]) to $(area_interface[2]) (p.u.)"] = boundary_capacity
      output_dict["loss between area $(area_interface[1]) and $(area_interface[2]) (p.u.)"] = boundary_loss
   elseif length(area_interface) > 2
      println("Warning: area_interface has $(length(area_interface)) elements. Results are saved for power transfer between areas only when exactly two areas are given in area_interface.")
   end

   if length(zone_interface) == 2
      unspecified_to_zones = false
      if length(zone_interface[2]) == 0
         unspecified_to_zones = true
      end
      boundary_p = zeros(Float64,length(ref))
      boundary_q = zeros(Float64,length(ref))
      boundary_s = Array{Float64}(undef, length(ref))
      boundary_s_rev = Array{Float64}(undef, length(ref))
      boundary_slack = Array{Float64}(undef, length(ref))
      boundary_p_rev = zeros(Float64,length(ref))
      boundary_q_rev = zeros(Float64,length(ref))
      boundary_capacity = zeros(Float64,length(ref))
      boundary_loss = Array{Float64}(undef, length(ref))
      for (i,(subnet_idx, ref_subnet)) in enumerate(ref)
         boundary_arcs = Array{Tuple{Int64,Int64,Int64},1}()
         boundary_arcs_reverse = Array{Tuple{Int64,Int64,Int64},1}()
         f_area_buses = filter(p->(last(p)["zone"] in zone_interface[1]),ref_subnet[:bus])
         # println("f_area_buses: $f_area_buses")
         # bus_arcs = getindex.(Ref(ref_subnet[:bus_arcs]), f_area_buses)
         for (idx, bus) in f_area_buses
            bus_arcs = ref_subnet[:bus_arcs][idx]
            for arc in bus_arcs
               if (ref_subnet[:bus][arc[3]]["zone"] in zone_interface[2]) || (unspecified_to_zones && !(ref_subnet[:bus][arc[3]]["zone"] in zone_interface[2]))
                  push!(boundary_arcs, arc)
                  push!(boundary_arcs_reverse, (arc[1],arc[3],arc[2]))
                  boundary_p[i] += value(p[subnet_idx][arc])
                  boundary_q[i] += value(q[subnet_idx][arc])
                  boundary_p_rev[i] += value(p[subnet_idx][(arc[1],arc[3],arc[2])])
                  boundary_q_rev[i] += value(q[subnet_idx][(arc[1],arc[3],arc[2])])
                  br_rate_a = Inf
                  if "rate_a" in keys(ref[subnet_idx][:branch][arc[1]])
                     br_rate_a = ref[subnet_idx][:branch][arc[1]]["rate_a"]
                  end
                  boundary_capacity[i] += br_rate_a * ref[subnet_idx][:branch][arc[1]]["br_status"]
               end
            end
         end
         # println("boundary_arcs: $boundary_arcs")
         # println("boundary_p: $boundary_p")
         boundary_s[i] = sqrt(boundary_p[i]^2 + boundary_q[i]^2)
         boundary_s_rev[i] = sqrt(boundary_p_rev[i]^2 + boundary_q_rev[i]^2)
         boundary_slack[i] = boundary_capacity[i] - max(abs(boundary_s[i]), abs(boundary_s_rev[i]))
         boundary_loss[i] = abs(boundary_p[i] + boundary_p_rev[i])
      end
      output_dict["P flow from zones $(zone_interface[1]) to $(zone_interface[2]) (p.u.)"] = boundary_p
      output_dict["P flow from zones $(zone_interface[2]) to $(zone_interface[1]) (p.u.)"] = boundary_p_rev
      output_dict["Q flow from zones $(zone_interface[1]) to $(zone_interface[2]) (p.u.)"] = boundary_q
      output_dict["Q flow from zones $(zone_interface[2]) to $(zone_interface[1]) (p.u.)"] = boundary_q_rev
      output_dict["S flow from zones $(zone_interface[1]) to $(zone_interface[2]) (p.u.)"] = boundary_s
      output_dict["S flow from zones $(zone_interface[2]) to $(zone_interface[1]) (p.u.)"] = boundary_s_rev
      output_dict["S slack from zones $(zone_interface[1]) to $(zone_interface[2]) (p.u.)"] = boundary_slack
      output_dict["S capacity from zones $(zone_interface[1]) to $(zone_interface[2]) (p.u.)"] = boundary_capacity
      output_dict["loss between zones $(zone_interface[1]) and $(zone_interface[2]) (p.u.)"] = boundary_loss
   elseif length(zone_interface) > 2
      println("Warning: zone_interface has $(length(zone_interface)) elements. Results are saved for power transfer between zones only when exactly two arrays of zones are given in zone_interface.")
   end
   if uniform_gen_scaling
      output_dict["alpha_upstream"] = value(alpha_upstream)
      output_dict["alpha_downstream"] = value(alpha_downstream)
   end

   outdict_string = JSON.json(output_dict)
   if output_to_files
      open("$output_folder/output_values.json", "w") do f
          write(f, outdict_string)
      end
   end

   binding_cnstr_dict = Dict{Symbol, Any}()
   # Get duals for all constraints in the constraints reference dict
   if termination_status(model) in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, ALMOST_OPTIMAL]
      if has_duals(model)
         for (class_i,class) in constraints
            # println("$class_i constraints")
            for (subnet_i,subnet) in class
               # println("subnet: $subnet")
               # println("typeof(subnet): $(typeof(subnet))")
               if !isa(subnet, Dict)
                  subnet_dict = Dict(1=>subnet)
               else
                  subnet_dict = subnet
               end
               # println("subnet_dict: $subnet_dict")
               for (cnstr_i,cnstr) in subnet_dict
                  if abs(dual(cnstr)) >= 1e-6
                     if !(class_i in keys(binding_cnstr_dict))
                        binding_cnstr_dict[class_i] = Dict{String, Any}()
                     end
                     # if "ctg_label" in keys(mn_data["sn"]["$ctg_i"])
                     #    lbl = mn_data["sn"]["$ctg_i"]["ctg_label"]
                     # else
                     #    lbl = "no"
                     # end
                     if !("subnet $subnet_i" in keys(binding_cnstr_dict[class_i]))
                        binding_cnstr_dict[class_i]["subnet $subnet_i"] = Array{String,1}()
                     end
                     # println("dual: $(dual(cnstr))")
                     push!(binding_cnstr_dict[class_i]["subnet $subnet_i"], "$cnstr")
                  end
               end
            end
         end
      else
         println("model has no duals")
      end
   end
   binding_cnstr_dict_string = JSON.json(binding_cnstr_dict)
   if output_to_files
      open("$output_folder/binding_constraints.json", "w") do f
         write(f, binding_cnstr_dict_string)
      end
   end

   return (output_dict, res_summary, solution_pm, binding_cnstr_dict)
end
