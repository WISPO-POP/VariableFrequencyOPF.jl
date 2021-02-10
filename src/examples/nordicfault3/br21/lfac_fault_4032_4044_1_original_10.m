%% MATPOWER Case Format : Version 2
function mpc = fault_4032_4044_1_original_10
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;
%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	3	0.0	0.0	0.0	0.0	0.0	1.0	0.0	0.0	0.0	1.1	0.9				
	2	1	0.0	0.0	0.0	0.0	0.0	1.0	0.0	0.0	0.0	1.1	0.9				
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1	0.0	0.0	0.0	0.0	0.0	0.0	0	0.0	0.0															
];

%% branch data
%    fbus    tbus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	2	0.006	0.06	1.79949	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
];

%% bus names
mpc.bus_name = {
	'Bus 1	LF'
	'Bus 2	LF'
};

