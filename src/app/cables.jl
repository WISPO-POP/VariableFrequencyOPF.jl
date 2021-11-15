

function add_cables_from_json(
    base_network_folder::String,
    output_location::String,
    fbase::Number,
    cable_params_json::String;
    n_fit_points::Int64=100
    )

    mn_data = read_sn_data(base_network_folder)

    params = JSON.parsefile(cable_params_json)
    for (sn_idx,subnet) in params["sn"]
        for (idx,cable) in subnet["branch"]
            if mn_data["sn"][sn_idx]["variable_f"]
                f_min = mn_data["sn"]["$sn_idx"]["f_min"]
                f_max = mn_data["sn"]["$sn_idx"]["f_max"]
            else
                f_min = 0.1
                f_max = mn_data["sn"][sn_idx]["f_base"]
            end
            add_cable!(
                mn_data["sn"][sn_idx],
                cable,
                cable["index"],
                f_min::Number,
                f_max::Number,
                n_fit_points::Int64,
                output_location="$output_location/cable_modeling_plots"
            )
            # for (idx,branch) in mn_data["sn"][sn_idx]["branch"]
            #     println("branch $idx: r_0 = $(branch["br_r0"])")
            # end
        end
    end
    stringnet = JSON.json(mn_data)
    if !isdir(output_location)
        mkpath(output_location)
    end
    open("$output_location/multifrequency_network.json", "w") do f
        write(f, stringnet)
    end
end
"""
    function add_cable(
        network::Dict,
        cable_params::String,
        cable_index::Int64,
        f_min::Number,
        f_max::Number,
        n_fit_points::Int64,
        output_location::String="cable_modeling_plots/"
        )
"""
function add_cable!(
    subnetwork::Dict,
    cable_params::Dict,
    cable_index::Int64,
    f_min::Number,
    f_max::Number,
    n_fit_points::Int64;
    output_location::String="plots/"
    )
    # params = JSON.parsefile(cable_params)["branch"]["$(cable_index)"]
    params = cable_params
    fit_frequencies = range(f_min*2*pi,stop=f_max*2*pi,length=n_fit_points)
    X = zeros(n_fit_points);
    R = zeros(n_fit_points);
    B = zeros(n_fit_points);
    G = zeros(n_fit_points);
    base_kv = subnetwork["bus"]["$(params["f_bus"])"]["base_kv"]
    baseMVA = subnetwork["baseMVA"]
    Zbase = (base_kv*1e3)^2/(baseMVA*1e6)
    println("Zbase: $Zbase")
    for (i,omega) in enumerate(fit_frequencies)
        (Z,Y) = build_matrices_wedepohl(params, omega)
        l = params["length"]
        (Z_series,Y_shunt) = calc_values(l, Z, Y)
        Z_series_pu = Z_series/Zbase
        Y_shunt_pu = Y_shunt*Zbase
        X[i] = imag(Z_series_pu)
        R[i] = real(Z_series_pu)
        B[i] = imag(Y_shunt_pu)
        G[i] = real(Y_shunt_pu)
    end
    X_ls210 = [fit_frequencies.^2 fit_frequencies ones(size(fit_frequencies))]
    X_ls21 = [fit_frequencies.^2 fit_frequencies]
    X_ls10 = [fit_frequencies ones(size(fit_frequencies))]
    X_ls2 = [fit_frequencies.^4 fit_frequencies.^3 fit_frequencies.^2 fit_frequencies ones(size(fit_frequencies))]
    # b_r = (X_ls210'*X_ls210)\X_ls210'*R
    b_r = X_ls210\R
    # b_r = X_ls2\R
    # b_x = (X_ls21'*X_ls21)\X_ls21'*X
    b_x = X_ls21\X
    # b_b = (X_ls21'*X_ls21)\X_ls21'*B
    b_b = X_ls21\B
    # b_g = (X_ls2'*X_ls2)\X_ls2'*G
    b_g = X_ls2\G
    X_fit = b_x[1]*fit_frequencies.^2 .+b_x[2]*fit_frequencies
    R_fit = b_r[1]*fit_frequencies.^2 .+b_r[2]*fit_frequencies .+b_r[3]
    B_fit = b_b[1]*fit_frequencies.^2 .+b_b[2]*fit_frequencies
    G_fit = b_g[1]*fit_frequencies.^4 .+b_g[2]*fit_frequencies.^3 .+b_g[3]*fit_frequencies.^2 .+b_g[4]*fit_frequencies .+ b_g[5]
    # R_fit = b_r[1]*fit_frequencies.^4 .+b_r[2]*fit_frequencies.^3 .+b_r[3]*fit_frequencies.^2 .+b_r[4]*fit_frequencies .+ b_r[5]
    br_rdc = R[1]
    g_fr_dc = G[1]
    g_to_dc = G[1]
    x_err_max = maximum(abs.(X-X_fit))
    x_err_max_p = 100*x_err_max/maximum(X)
    r_err_max = maximum(abs.(R-R_fit))
    r_err_max_p = 100*r_err_max/maximum(R)
    b_err_max = maximum(abs.(B-B_fit))
    b_err_max_p = 100*b_err_max/maximum(B)
    g_err_max = maximum(abs.(G-G_fit))
    g_err_max_p = 100*g_err_max/maximum(G)

    @printf "Largest X error: %e (%.4g%% of maximum X)\n" x_err_max x_err_max_p
    @printf "Largest R error: %e (%.4g%% of maximum R)\n" r_err_max r_err_max_p
    @printf "Largest B error: %e (%.4g%% of maximum B)\n" b_err_max b_err_max_p
    @printf "Largest G error: %e (%.4g%% of maximum G)\n" g_err_max g_err_max_p

    println("[r2 r1 r0] = [$(b_r[1]) $(b_r[2]) $(b_r[3])]")
    println("[x2 x1 x0] = [$(b_x[1]) $(b_x[2]) 0]")
    println("[b2 b1 b0] = [$(b_b[1]) $(b_b[2]) 0]")
    println("[g4 g3 g2 g1 g0] = [$(b_g[1]) $(b_g[2]) $(b_g[3]) $(b_g[4]) $(b_g[5])]")
    # println("Largest R error: $(r_err_max) = $(r_err_max_p)% of maximum R")
    # println("Largest B error: $(b_err_max) = $(b_err_max_p)% of maximum B")
    # println("Largest G error: $(g_err_max) = $(g_err_max_p)% of maximum G")

    plot_fit = true
    if plot_fit
        upscale = 2 #upscaling in resolution
        fntsm = font("serif", pointsize=round(8.0*upscale))
        fntlg = font("serif", pointsize=round(12.0*upscale))
        default(titlefont=fntlg, guidefont=fntlg, tickfont=fntsm, legendfont=fntsm)
        default(size=(800*upscale,600*upscale))

        l = @layout [a ; b ; c ; d]
        p1 = plot(fit_frequencies/2/pi,X,ylabel="X (p.u.)",
            label="exact model",
            legend=:bottomright,
            left_margin=(10*upscale)*mm,
            right_margin=(10*upscale)*mm, top_margin=(10*upscale)*mm, bottom_margin=(10*upscale)*mm,
            linewidth=2*upscale
        )
        plot!(p1,fit_frequencies/2/pi,X_fit,
            label = "approximate model",
            line = (:dash, 2*upscale, :red)
            )
        p2 = plot(fit_frequencies/2/pi,R,ylabel="R (p.u.)",
            label="exact model",
            legend=:bottomright,
            linewidth=2*upscale
        )
        plot!(p2,fit_frequencies/2/pi,R_fit,
            label = "approximate model",
            line = (:dash, 2*upscale, :red)
        )
        p3 = plot(fit_frequencies/2/pi,B,ylabel="B (p.u.)",
            label="exact model",
            legend=:bottomright,
            linewidth=2*upscale
        )
        plot!(p3,fit_frequencies/2/pi,B_fit,
            label = "approximate model",
            line = (:dash, 2*upscale, :red)
        )
        p4 = plot(fit_frequencies/2/pi, G ,ylabel="G (p.u.)", xlabel="frequency (Hz)",
            label="exact model",
            legend=:bottomright,
            linewidth=2*upscale
        )
        plot!(p4,fit_frequencies/2/pi,G_fit,
            label = "approximate model",
            line = (:dash, 2*upscale, :red)
        )
        plt = plot(p1, p2, p3, p4, layout = l)
        if !isdir(output_location)
            mkpath(output_location)
        end
        savefig(plt,"$output_location/cable_$cable_index.pdf")
    end

    branch_entry = Dict(
        "br_status"=>1,
        "index"=>params["index"],
        "source_id"=>[
            "branch",
            params["index"]
        ],
        "f_bus"=>params["f_bus"],
        "t_bus"=>params["t_bus"],
        "rate_a"=>params["rate_a"],
        "rate_b"=>params["rate_b"],
        "rate_c"=>params["rate_c"],
        "transformer"=>false,
        "tap"=>1,
        "shift"=>0,
        "br_rdc"=>br_rdc,
        "g_fr_dc"=>g_fr_dc,
        "g_to_dc"=>g_to_dc,
        "br_r0"=>b_r[3],
        "br_r1"=>b_r[2],
        "br_r2"=>b_r[1],
        "br_x0"=>0,
        "br_x1"=>b_x[2],
        "br_x2"=>b_x[1],
        "b_to0"=>0,
        "b_to1"=>b_b[2]/2,
        "b_to2"=>b_b[1]/2,
        "b_fr0"=>0,
        "b_fr1"=>b_b[2]/2,
        "b_fr2"=>b_b[1]/2,
        "g_to0"=>b_g[5]/2,
        "g_to1"=>b_g[4]/2,
        "g_to2"=>b_g[3]/2,
        "g_to3"=>b_g[2]/2,
        "g_to4"=>b_g[1]/2,
        "g_fr0"=>b_g[5]/2,
        "g_fr1"=>b_g[4]/2,
        "g_fr2"=>b_g[3]/2,
        "g_fr3"=>b_g[2]/2,
        "g_fr4"=>b_g[1]/2,
        "f_dependent"=>true
    )
    if "angmin" ∈ keys(params) && "angmax" ∈ keys(params)
        branch_entry["angmin"] = params["angmin"]
        branch_entry["angmax"] = params["angmax"]
    else
        branch_entry["angmin"] = StatsBase.mode(branch["angmin"] for (i,branch) in subnetwork["branch"])
        branch_entry["angmax"] = StatsBase.mode(branch["angmax"] for (i,branch) in subnetwork["branch"])
    end

    if "$(params["index"])" in keys(subnetwork["branch"])
        println("Replacing the existing branch (index $(params["index"])) with the cable having the same index.")
    end
    subnetwork["branch"]["$(params["index"])"] = branch_entry

    branch_entry["baseMVA"] = subnetwork["baseMVA"]
    branch_entry["base_kv"] = subnetwork["bus"]["$(params["f_bus"])"]["base_kv"]
    branch_entry["Zbase"] = (branch_entry["base_kv"]*1e3)^2/(branch_entry["baseMVA"]*1e6)
    stringparams = JSON.json(branch_entry)
    if !isdir(output_location)
        mkpath(output_location)
    end
    open("$output_location/cable_params.json", "w") do f
        write(f, stringparams)
    end
end


function build_matrices_wedepohl(
    params::Dict,
    omega::Number
    )

    rho_central = params["rho_central"]
    rho_sheath = params["rho_sheath"]
    rho_earth = params["rho_earth"]
    mu_central = params["mu_central"]
    mu_sheath = params["mu_sheath"]
    mu_1 = params["mu_1"]
    mu_2 = params["mu_2"]
    mu_earth = params["mu_earth"]
    r1 = params["r1"]
    r2 = params["r2"]
    r3 = params["r3"]
    r4 = params["r4"]

    m_central = sqrt(im*omega*mu_central/rho_central)
    m_sheath = sqrt(im*omega*mu_sheath/rho_sheath)
    m_earth = sqrt(im*omega*mu_earth/rho_earth)

    h = params["h"]
    d = params["d"]
    s_ij = params["s_ij"]

    g1 = params["g1"]
    g2 = params["g2"]

    # eps0 = 8.854187e-12
    eps1 = params["eps1"]
    eps2 = params["eps2"]

    # Self impedance
    z1 = rho_central * m_central / (2*pi*r1) * besseli(0,m_central*r1)/besseli(1,m_central*r1);

    z2 = im*omega*mu_1 / 2 * log(r2/r1);
    z6 = im*omega*mu_2 / 2 * log(r4/r3);

    D = besseli(1,m_sheath*r3)*besselk(1,m_sheath*r2) - besseli(1,m_sheath*r2)*besselk(1,m_sheath*r3);

    z3 = rho_sheath*m_sheath/(2*pi*r2) * (besseli(0,m_sheath*r2)*besselk(1,m_sheath*r3) + besselk(0,m_sheath*r2)*besseli(1,m_sheath*r3)) / D;
    z4 = rho_sheath / (2*pi*r2*r3) / D;
    z5 = rho_sheath*m_sheath/(2*pi*r3) * (besseli(0,m_sheath*r3)*besselk(1,m_sheath*r2) + besselk(0,m_sheath*r3)*besseli(1,m_sheath*r2)) / D;

    z7 = im*omega*mu_earth/(2*pi) * (-1*log(MathConstants.eulergamma*m_earth*r4/2) + 1/2 - 4*m_earth*h/3);

    # Mutual impedance
    z_ij = im*omega*mu_earth/(2*pi) * (-1*log(MathConstants.eulergamma*m_earth*s_ij/2)+1/2-2/3*m_earth*(2*h));

    # Cable submatrices (each phase is assumed equal because of balanced
    # system and transposed cables)

    # Each submatrix contains entries for the central conductor and sheath and
    # coupling between them
    Z_i = [ (z1 + z2 + z3 + z5 + z6 + z7 - 2*z4) (z5 + z6 + z7 - z4);
              (z5 + z6 + z7 - z4                 ) (z5 + z6 + z7     )]

    # The induced voltage from adjacent cables is the same in the sheath as
    # the central conductor, so the terms for each are equal
    Z_ij = [ z_ij z_ij ;
               z_ij z_ij ]

    # Full Z matrix (all three phases)
    Zw = [ Z_i  Z_ij Z_ij;
             Z_ij Z_i  Z_ij;
             Z_ij Z_ij Z_i ]

    T = [1 0 0 0 0 0;
           0 0 1 0 0 0;
           0 0 0 0 1 0;
           0 1 0 0 0 0;
           0 0 0 1 0 0;
           0 0 0 0 0 1];

    Z = T * Zw * T';

    ## Construct Y matrix
    # Cable submatrices (each phase is assumed equal because of balanced
    # system and transposed cables)
    y1 = g1 + im*omega*2*pi*eps1 / log(r2/r1);
    y2 = g2 + im*omega*2*pi*eps2 / log(r4/r3);

    Y_i = [ (y1) (-y1);
              (-y1) (y1 + y2)]

    Yw = [Y_i zeros(2,2) zeros(2,2);
            zeros(2,2) Y_i zeros(2,2);
            zeros(2,2) zeros(2,2) Y_i]

    Y = T * Yw * T';

    return Z,Y
end


function calc_values(length, Z, Y)
    gamma = sqrt(Z*Y);
    exp_p = 1/2*(exp(sqrt(Z*Y)*length)+exp(-sqrt(Z*Y)*length));
    exp_n = 1/2*(exp(sqrt(Z*Y)*length)-exp(-sqrt(Z*Y)*length));

    M = [(exp_p) (exp_n/sqrt(Z*Y)*Z);
         Z\sqrt(Z*Y)*exp_n Z\exp_p*Z]

    # A = [zeros(size(Z)), Z              ;
    #      Y             , zeros(size(Z))];
    #
    # [V,D] = eig(A);
    # M = V * expm(D*x) / V;

    alpha1 = M[1:3,1:3]
    alpha2 = M[1:3,4:6]
    alpha3 = M[4:6,1:3]
    alpha4 = M[4:6,4:6]
    beta1  = M[1:3,7:9]
    beta2  = M[1:3,10:12]
    beta3  = M[4:6,7:9]
    beta4  = M[4:6,10:12]
    gamma1 = M[7:9,1:3]
    gamma2 = M[7:9,4:6]
    gamma3 = M[10:12,1:3]
    gamma4 = M[10:12,4:6]
    delta1 = M[7:9,7:9]
    delta2 = M[7:9,10:12]
    delta3 = M[10:12,7:9]
    delta4 = M[10:12,10:12]

    As = [1 1 1;1 exp(-2*im*pi/3) exp(2*im*pi/3); 1 exp(2*im*pi/3) exp(-2*im*pi/3)];
    abcd = [0 1 0 0 0 0;0 0 0 0 1 0]*[inv(As) zeros(size(As));zeros(size(As)) inv(As)]*[alpha1-alpha2/alpha4*alpha3 beta1-alpha2/alpha4*beta3;gamma1-gamma2/alpha4*alpha3 delta1-gamma2/alpha4*beta3]*[As zeros(size(As));zeros(size(As)) As]*[0 1 0 0 0 0;0 0 0 0 1 0]';
    a = abcd[1,1]
    b = abcd[1,2]
    c = abcd[2,1]
    d = abcd[2,2]

    # Z_series = b;
    # Y_shunt = 2 * (a-1)/b;

    Z_series = (d-1)*(d+1)/c;
    Y_shunt = 2 * c/(d+1);

    return Z_series, Y_shunt
end

function calc_cable_params(
    r1::Float64,
    r2::Float64,
    r3::Float64,
    r4::Float64,
    depth::Number,
    d::Number,
    length::Number,
    conductor_material::String,
    sheath_material::String,
    insulation_material::String,
    configuration::String,
    index::Int64,
    f_bus::Int64,
    t_bus::Int64,
    rate_a::Number,
    rate_b::Number,
    rate_c::Number,
    angmin,
    angmax
    )

    #######################
    # Material properties #
    #######################

    # Electrical Resistivity, ρ [Ω⋅m]
    rho_copper = 1.68e-8
    rho_aluminum = 2.65e-8
    rho_lead = 2.20e-7
    rho_soil = 100
    rho_polyethylene = 2e11

    # Magnetic Permeability, μ [H/m]
    mu_copper = 1.256629e-6
    mu_aluminum = 1.256665e-6
    mu_lead = 1.256616e-6
    mu_vacuum = 4*pi*1e-7

    # Dielectric permittivity, ϵ [F/m]
    eps_vacuum = 8.854187e-12
    eps_r_polyethylene = 2.3
    eps_polyethylene = eps_r_polyethylene*eps_vacuum

    if lowercase(conductor_material) == "copper"
        rho_central = rho_copper
        mu_central = mu_copper
    elseif lowercase(conductor_material) == "aluminum"
        rho_central = rho_aluminum
        mu_central = mu_aluminum
    end

    if lowercase(sheath_material) == "aluminum"
        rho_sheath = rho_aluminum
        mu_sheath = mu_aluminum
    elseif lowercase(sheath_material) == "lead"
        rho_sheath = rho_lead
        mu_sheath = mu_lead
    end

    if lowercase(insulation_material) ∈ ["polyethylene","xlpe"]
        rho_insulation = rho_polyethylene
        eps1 = eps_polyethylene
        eps2 = eps_polyethylene
    end

    g1 = pi*(r2+r1)/((r2-r1)*rho_insulation)
    g2 = pi*(r4+r3)/((r4-r3)*rho_insulation)

    rho_earth = rho_soil
    mu_1 = mu_vacuum
    mu_2 = mu_vacuum
    mu_earth = mu_vacuum

    if lowercase(configuration) == "trefoil"
        s_ij = d
        h = depth + sqrt(3)/3*d
    elseif lowercase(configuration) == "flat"
        s_ij = 4/3*d
        h = depth
    end

    branch_dict = Dict(
        "r1"=>r1,
        "r2"=>r2,
        "r3"=>r3,
        "r4"=>r4,
        "rho_central"=>rho_central,
        "rho_sheath"=>rho_sheath,
        "rho_earth"=>rho_earth,
        "mu_central"=>mu_central,
        "mu_sheath"=>mu_sheath,
        "mu_1"=>mu_1,
        "mu_2"=>mu_2,
        "mu_earth"=>mu_earth,
        "h"=>h,
        "d"=>d,
        "s_ij"=>s_ij,
        "g1"=>g1,
        "g2"=>g2,
        "length"=>length,
        "eps1"=>eps1,
        "eps2"=>eps2,
        "rate_a"=>rate_a,
        "rate_b"=>rate_b,
        "rate_c"=>rate_c,
        "br_status"=>1,
        "f_bus"=>f_bus,
        "t_bus"=>t_bus,
        "index"=>index
    )
    if typeof(angmin) != Missing && typeof(angmax) != Missing
        branch_dict["angmin"] = angmin
        branch_dict["angmax"] = angmax
    end

    return branch_dict
end

function write_cable_data(
    cable_file::String,
    output_location::String
    )

    cable_dict = Dict("sn"=>Dict{String,Any}())

    cables = CSV.read(cable_file, DataFrame)

    for cable in eachrow(cables)
        cable_param = calc_cable_params(
            cable.r1,
            cable.r2,
            cable.r3,
            cable.r4,
            cable.depth,
            cable.d,
            cable.length,
            cable.conductor_material,
            cable.sheath_material,
            cable.insulation_material,
            cable.configuration,
            cable.index,
            cable.f_bus,
            cable.t_bus,
            cable.rate_a,
            cable.rate_b,
            cable.rate_c,
            cable.angmin,
            cable.angmax
        )
        if "$(cable.subnetwork)" ∉ keys(cable_dict["sn"])
            cable_dict["sn"]["$(cable.subnetwork)"] = Dict("branch"=>Dict{String,Any}())
        end
        cable_dict["sn"]["$(cable.subnetwork)"]["branch"]["$(cable.index)"] = cable_param
    end

    stringdict = JSON.json(cable_dict)
    if !isdir(output_location)
        mkpath(output_location)
    end
    open("$output_location/cable_params.json", "w") do f
        write(f, stringdict)
    end

end
