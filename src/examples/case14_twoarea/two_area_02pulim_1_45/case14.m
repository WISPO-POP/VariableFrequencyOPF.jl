function mpc = case14
%CASE14

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	4	1	69.31	-5.655	0	0	1	1.019	-10.33	0	1	1.06	0.94;
	5	1	11.02	2.32	0	0	1	1.02	-8.78	0	1	1.06	0.94;
	6	2	16.24	10.875	0	0	1	1.07	-14.22	0	1	1.06	0.94;
	7	1	0	0	0	0	1	1.062	-13.37	0	1	1.06	0.94;
	8	2	0	0	0	0	1	1.09	-13.36	0	1	1.06	0.94;
	9	1	42.775	24.07	0	19	1	1.056	-14.94	0	1	1.06	0.94;
	10	1	13.05	8.41	0	0	1	1.051	-15.1	0	1	1.06	0.94;
	11	1	5.075	2.61	0	0	1	1.057	-14.79	0	1	1.06	0.94;
	12	1	8.845	2.32	0	0	1	1.055	-15.07	0	1	1.06	0.94;
	13	1	19.575	8.41	0	0	1	1.05	-15.16	0	1	1.06	0.94;
	14	1	21.605	7.25	0	0	1	1.036	-16.04	0	1	1.06	0.94;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	6	0	12.2	24	-6	1.07	100	1	100	0	0	0	0	0	0	0	0	0	0	0	0;
	8	0	17.4	24	-6	1.09	100	1	100	0	0	0	0	0	0	0	0	0	0	0	0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	4	7	0	0.20912	0	0	0	0	0.978	0	1	-360	360;
	4	9	0	0.55618	0	0	0	0	0.969	0	1	-360	360;
	5	6	0	0.25202	0	0	0	0	0.932	0	1	-360	360;
	6	11	0.09498	0.1989	0	0	0	0	0	0	1	-360	360;
	6	12	0.12291	0.25581	0	0	0	0	0	0	1	-360	360;
	6	13	0.06615	0.13027	0	0	0	0	0	0	1	-360	360;
	7	8	0	0.17615	0	0	0	0	0	0	1	-360	360;
	7	9	0	0.11001	0	0	0	0	0	0	1	-360	360;
	9	10	0.03181	0.0845	0	0	0	0	0	0	1	-360	360;
	9	14	0.12711	0.27038	0	0	0	0	0	0	1	-360	360;
	10	11	0.08205	0.19207	0	0	0	0	0	0	1	-360	360;
	12	13	0.22092	0.19988	0	0	0	0	0	0	1	-360	360;
	13	14	0.17093	0.34802	0	0	0	0	0	0	1	-360	360;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0.01	40	0;
	2	0	0	3	0.01	40	0;
];

%% bus names
mpc.bus_name = {
	'Bus 4     HV';
	'Bus 5     HV';
	'Bus 6     LV';
	'Bus 7     ZV';
	'Bus 8     TV';
	'Bus 9     LV';
	'Bus 10    LV';
	'Bus 11    LV';
	'Bus 12    LV';
	'Bus 13    LV';
	'Bus 14    LV';
};
