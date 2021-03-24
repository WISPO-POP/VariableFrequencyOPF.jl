%% MATPOWER Case Format : Version 2
function mpc = fault_4032_4044_1_original_10
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;
%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	24011	3	0.0	0.0	0.0	0.0	1	1.02043	-68.1476	400.0	1	1.1	0.9
	24021	1	0.0	0.0	0.0	0.0	1	1.02681	-97.0879	400.0	1	1.1	0.9
	24042	1	0.0	0.0	0.0	0.0	2	1.00838	-123.45080000000002	400.0	1	1.1	0.9
	% 250011	2	0.0	0.0	0.0	0.0	1	1.02173	-89.9803	15.0	1	1.1	0.9
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	24011	0.0	0.0	0.0	0.0	1.0	300.0	0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
];

%% branch data
%    fbus    tbus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	24011	24021	0.006	0.06	1.79949	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0
	24021	24042	0.01	0.1	3.00086	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0
	% 24021	250011	0.0	0.05	0.0	300.0	300.0	300.0	1.05	0.0	1	-40.0	40.0
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	3	0.001	10.0	0.0
];

%% bus names
mpc.bus_name = {
	'Bus 4011	LF'
	'Bus 4021	LF'
	'Bus 4042	LF'
};
