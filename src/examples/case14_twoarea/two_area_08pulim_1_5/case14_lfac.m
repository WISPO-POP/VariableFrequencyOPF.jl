function mpc = case14_lfac
%CASE14_LFAC

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	3	0	0	0	0	1	1.06	0	0	1	1.06	0.94;
	2	2	32.55	19.05	0	0	1	1.045	-4.98	0	1	1.06	0.94;
	3	2	141.3	28.5	0	0	1	1.01	-12.72	0	1	1.06	0.94;
	4	1	0	0	0	0	1	1.019	-10.33	0	1	1.06	0.94;
	5	1	0	0	0	0	1	1.02	-8.78	0	1	1.06	0.94;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	1	232.4	-16.9	10	0	1.06	100	1	332.4	0	0	0	0	0	0	0	0	0	0	0	0;
	2	40	42.4	50	-40	1.045	100	1	140	0	0	0	0	0	0	0	0	0	0	0	0;
	3	0	23.4	40	0	1.01	100	1	100	0	0	0	0	0	0	0	0	0	0	0	0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	2	0.01938	0.05917	0.0528	80	0	0	0	0	1	-360	360;
	1	5	0.05403	0.22304	0.0492	80	0	0	0	0	1	-360	360;
	2	3	0.04699	0.19797	0.0438	80	0	0	0	0	1	-360	360;
	2	4	0.05811	0.17632	0.034	80	0	0	0	0	1	-360	360;
	2	5	0.05695	0.17388	0.0346	80	0	0	0	0	1	-360	360;
	3	4	0.06701	0.17103	0.0128	80	0	0	0	0	1	-360	360;
	4	5	0.01335	0.04211	0	80	0	0	0	0	1	-360	360;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0.0430292599	20	0;
	2	0	0	3	0.25	20	0;
	2	0	0	3	0.01	40	0;
];

%% bus names
mpc.bus_name = {
	'Bus 1     HV';
	'Bus 2     HV';
	'Bus 3     HV';
	'Bus 4     HV';
	'Bus 5     HV';
};
