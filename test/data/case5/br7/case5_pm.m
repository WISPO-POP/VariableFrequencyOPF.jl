%% MATPOWER Case Format : Version 2
function mpc = case5
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100.0;
%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	2	0.0	0.0	0.0	0.0	1	1.0	2.80377	230.0	1	1.1	0.9				
	2	1	300.0	98.61	0.0	0.0	1	1.08407	-0.73465	230.0	1	1.1	0.9				
	3	2	300.0	98.61	0.0	0.0	1	1.0	-0.55972	230.0	1	1.1	0.9				
	4	3	400.0	131.47	0.0	0.0	1	1.0	0.0	230.0	1	1.1	0.9				
	10	2	0.0	0.0	0.0	0.0	1	1.0	3.5903300000000002	230.0	1	1.1	0.9				
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	1	40.0	30.0	30.0	-30.0	1.07762	100.0	1	40.0	0.0															
	1	170.0	127.49999999999999	127.49999999999999	-127.49999999999999	1.07762	100.0	1	170.0	0.0															
	3	324.498	390.0	390.0	-390.0	1.1	100.0	1	520.0	0.0															
	4	0.0	-10.802	150.0	-150.0	1.06414	100.0	1	200.0	0.0															
	10	470.694	-165.039	450.0	-450.0	1.06907	100.0	1	600.0	0.0															
];

%% branch data
%    fbus    tbus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1	2	0.00281	0.0281	0.00712	400.0	400.0	400.0	0	0	1	-29.999999999999996	29.999999999999996								
	1	4	0.00304	0.0304	0.00658	426.0	426.0	426.0	0	0	1	-29.999999999999996	29.999999999999996								
	1	10	0.00064	0.0064	0.03126	426.0	426.0	426.0	0	0	1	-29.999999999999996	29.999999999999996								
	2	3	0.00108	0.0108	0.01852	426.0	426.0	426.0	0	0	1	-29.999999999999996	29.999999999999996								
	3	4	0.00297	0.0297	0.00674	426.0	426.0	426.0	1.05	1.0	1	-29.999999999999996	29.999999999999996								
	3	4	0.003274425	0.03274425	0.006772114342403629	426.0	426.0	426.0	0.9523809523809523	1.0	1	-29.999999999999996	29.999999999999996								
	4	10	0.00297	0.0297	0.00674	240.0	240.0	240.0	0	0	0	-29.999999999999996	29.999999999999996								
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	2	14.0	0.0
	2	0.0	0.0	2	15.0	0.0
	2	0.0	0.0	2	30.0	0.0
	2	0.0	0.0	2	40.0	0.0
	2	0.0	0.0	2	10.0	0.0
];

