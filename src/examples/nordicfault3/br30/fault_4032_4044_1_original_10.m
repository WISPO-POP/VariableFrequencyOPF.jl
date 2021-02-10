%% MATPOWER Case Format : Version 2
function mpc = fault_4032_4044_1_original_10
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;
%% bus data
%    bus_i    type    Pd    Qd    Gs    Bs    area    Vm    Va    baseKV    zone    Vmax    Vmin
mpc.bus = [
	1	1	586.773235	141.73811	0.0	0.0	2	0.97678	-153.9453	20.0	1	1.1	0.9				
	2	1	328.104988	70.1864941	0.0	0.0	2	0.99544	-139.4149	20.0	1	1.1	0.9				
	3	1	254.77559900000003	80.4663534	0.0	0.0	2	0.97738	-149.165	20.0	1	1.1	0.9				
	4	1	816.395408	238.036017	0.0	0.0	2	0.97155	-139.7168	20.0	1	1.1	0.9				
	5	1	703.462049	181.753884	0.0	0.0	2	0.9732	-143.4856	20.0	1	1.1	0.9				
	11	1	199.709432	68.6000389	0.0	0.0	1	1.00111	-70.0701	20.0	1	1.1	0.9				
	12	1	299.989103	83.7933909	0.0	0.0	1	0.99747	-66.583	20.0	1	1.1	0.9				
	13	1	100.050383	34.4348853	0.0	0.0	1	0.99623	-62.3071	20.0	1	1.1	0.9				
	22	1	278.377645	78.9764801	0.0	0.0	1	0.98946	-82.2548	20.0	1	1.1	0.9				
	31	1	98.2266795	23.8313272	0.0	0.0	1	0.98638	-99.7871	20.0	1	1.1	0.9				
	32	1	199.352544	39.3440189	0.0	0.0	1	0.99453	-87.0895	20.0	1	1.1	0.9				
	41	1	522.565813	123.052459	0.0	0.0	2	0.96456	-121.5457	20.0	1	1.1	0.9				
	42	1	386.74752	119.098037	0.0	0.0	2	0.96225	-126.3923	20.0	1	1.1	0.9				
	43	1	876.292979	241.36380100000002	0.0	0.0	2	0.97491	-134.22040000000004	20.0	1	1.1	0.9				
	46	1	685.129955	202.89756800000004	0.0	0.0	2	0.97781	-134.8123	20.0	1	1.1	0.9				
	47	1	98.6717655	42.8394881	0.0	0.0	2	0.98175	-130.1331	20.0	1	1.1	0.9				
	51	1	790.966696	252.402351	0.0	0.0	2	0.98649	-142.6916	20.0	1	1.1	0.9				
	61	1	492.32958299999996	118.770784	0.0	0.0	3	0.97962	-126.5844	20.0	1	1.1	0.9				
	62	1	297.909426	82.6363251	0.0	0.0	3	0.99324	-123.48120000000002	20.0	1	1.1	0.9				
	63	1	588.985008	263.689962	0.0	0.0	3	0.99748	-119.79650000000001	20.0	1	1.1	0.9				
	71	1	300.078509	83.8441337	0.0	0.0	4	1.00302	-68.5785	20.0	1	1.1	0.9				
	72	1	2001.75904	396.797487	0.0	0.0	4	0.99828	-67.6927	20.0	1	1.1	0.9				
	1011	1	0.0	0.0	0.0	0.0	1	1.06024	-67.2661	130.0	1	1.1	0.9				
	1012	1	0.0	0.0	0.0	0.0	1	1.06335	-63.746	130.0	1	1.1	0.9				
	1013	1	0.0	0.0	0.0	0.0	1	1.05534	-59.4707	130.0	1	1.1	0.9				
	1014	1	0.0	0.0	0.0	0.0	1	1.06201	-56.4942	130.0	1	1.1	0.9				
	1021	1	0.0	0.0	0.0	0.0	1	1.03218	-58.040699999999994	130.0	1	1.1	0.9				
	1022	1	0.0	0.0	0.0	50.0	1	1.04517	-79.3893	130.0	1	1.1	0.9				
	1041	1	0.0	0.0	0.0	250.0	2	0.99014	-151.0472	130.0	1	1.1	0.9				
	1042	1	0.0	0.0	0.0	0.0	2	1.00869	-136.293	130.0	1	1.1	0.9				
	1043	1	0.0	0.0	0.0	200.0	2	1.00686	-145.9063	130.0	1	1.1	0.9				
	1044	1	0.0	0.0	0.0	200.0	2	0.97838	-136.6705	130.0	1	1.1	0.9				
	1045	1	0.0	0.0	0.0	200.0	2	0.98789	-140.4897	130.0	1	1.1	0.9				
	2031	1	0.0	0.0	0.0	0.0	1	1.0097	-96.9323	220.0	1	1.1	0.9				
	2032	1	0.0	0.0	0.0	0.0	1	1.06601	-84.2332	220.0	1	1.1	0.9				
	4011	1	0.0	0.0	0.0	0.0	1	1.02043	-68.1476	400.0	1	1.1	0.9				
	4012	1	0.0	0.0	0.0	-100.0	1	1.02253	-66.1493	400.0	1	1.1	0.9				
	4021	1	0.0	0.0	0.0	0.0	1	1.02681	-97.0879	400.0	1	1.1	0.9				
	4022	1	0.0	0.0	0.0	0.0	1	0.98654	-81.1914	400.0	1	1.1	0.9				
	4031	1	0.0	0.0	0.0	0.0	1	1.01452	-99.8015	400.0	1	1.1	0.9				
	4032	1	0.0	0.0	0.0	0.0	1	1.02359	-103.2469	400.0	1	1.1	0.9				
	4041	1	0.0	0.0	0.0	200.0	2	1.01677	-118.60459999999999	400.0	1	1.1	0.9				
	4042	1	0.0	0.0	0.0	0.0	2	1.00838	-123.45080000000002	400.0	1	1.1	0.9				
	4043	1	0.0	0.0	0.0	200.0	2	1.00972	-131.3289	400.0	1	1.1	0.9				
	4044	1	0.0	0.0	0.0	0.0	2	1.0087	-133.0995	400.0	1	1.1	0.9				
	4045	1	0.0	0.0	0.0	0.0	2	1.02901	-137.6283	400.0	1	1.1	0.9				
	4046	1	0.0	0.0	0.0	100.0	2	1.01377	-131.9259	400.0	1	1.1	0.9				
	4047	1	0.0	0.0	0.0	0.0	2	1.04502	-127.2664	400.0	1	1.1	0.9				
	4051	1	0.0	0.0	0.0	100.0	2	1.05392	-139.8298	400.0	1	1.1	0.9				
	4061	1	0.0	0.0	0.0	0.0	3	1.02281	-123.6834	400.0	1	1.1	0.9				
	4062	1	0.0	0.0	0.0	0.0	3	1.04869	-120.6396	400.0	1	1.1	0.9				
	4063	1	0.0	0.0	0.0	0.0	3	1.05174	-116.9876	400.0	1	1.1	0.9				
	4071	1	0.0	0.0	0.0	-400.0	4	1.04872	-65.7715	400.0	1	1.1	0.9				
	4072	1	0.0	0.0	0.0	0.0	4	1.05993	-64.8462	400.0	1	1.1	0.9				
	50001	2	0.0	0.0	0.0	0.0	1	1.07002	-58.1266	15.0	1	1.1	0.9				
	50002	2	0.0	0.0	0.0	0.0	1	1.05799	-55.6745	15.0	1	1.1	0.9				
	50003	2	0.0	0.0	0.0	0.0	1	1.06106	-50.5467	15.0	1	1.1	0.9				
	50004	2	0.0	0.0	0.0	0.0	1	1.03618	-52.7701	15.0	1	1.1	0.9				
	50005	2	0.0	0.0	0.0	0.0	1	1.03132	-72.7548	15.0	1	1.1	0.9				
	50006	2	0.0	0.0	0.0	0.0	2	1.01131	-128.2942	15.0	1	1.1	0.9				
	50007	2	0.0	0.0	0.0	0.0	2	1.01643	-137.9745	15.0	1	1.1	0.9				
	50008	2	0.0	0.0	0.0	0.0	1	1.05232	-77.2016	15.0	1	1.1	0.9				
	50009	2	0.0	0.0	0.0	0.0	1	1.00027	-62.29160000000001	15.0	1	1.1	0.9				
	50010	2	0.0	0.0	0.0	0.0	1	1.01725	-59.69180000000001	15.0	1	1.1	0.9				
	50011	2	0.0	0.0	0.0	0.0	1	1.02173	-89.9803	15.0	1	1.1	0.9				
	50012	2	0.0	0.0	0.0	0.0	1	1.02094	-92.1457	15.0	1	1.1	0.9				
	50013	2	0.0	0.0	0.0	0.0	2	1.01186	-118.6061	15.0	1	1.1	0.9				
	50014	2	0.0	0.0	0.0	0.0	2	1.04574	-115.7611	15.0	1	1.1	0.9				
	50015	2	0.0	0.0	0.0	0.0	2	1.04792	-119.8603	15.0	1	1.1	0.9				
	50016	2	0.0	0.0	0.0	0.0	2	1.05563	-132.88220000000004	15.0	1	1.1	0.9				
	50017	2	0.0	0.0	0.0	0.0	3	1.01208	-113.1373	15.0	1	1.1	0.9				
	50018	2	0.0	0.0	0.0	0.0	3	1.03372	-109.6613	15.0	1	1.1	0.9				
	50019	2	0.0	0.0	0.0	0.0	4	1.03117	-60.7879	15.0	1	1.1	0.9				
	50020	3	0.0	0.0	0.0	0.0	4	1.01954	-60.893800000000006	15.0	1	1.1	0.9				
];

%% generator data
%    bus    Pg    Qg    Qmax    Qmin    Vg    mBase    status    Pmax    Pmin    Pc1    Pc2    Qc1min    Qc1max    Qc2min    Qc2max    ramp_agc    ramp_10    ramp_30    ramp_q    apf
mpc.gen = [
	50001	594.225	67.227	249.8	-249.8	1.0684	800.0	1	760.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50002	295.716	21.017	187.35	-187.35	1.0565	600.0	1	570.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50003	544.912	23.597	218.57500000000002	-218.57500000000002	1.0595	700.0	1	665.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50004	392.999	34.68	187.35	-187.35	1.0339	600.0	1	570.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50005	197.685	73.187	78.062	-78.062	1.0294	250.0	1	237.5	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50006	360.522	161.809	174.356	-124.9	1.0084	400.0	1	360.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50007	179.337	90.377	87.178	-62.45	1.0141	200.0	1	180.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50008	741.153	266.551	265.412	-265.412	1.0498	850.0	1	807.4999999999999	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50009	661.239	223.433	312.25	-312.25	0.9988	1000.0	1	950.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50010	594.234	269.051	249.8	-249.8	1.0157	800.0	1	760.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50011	247.268	104.877	93.675	-93.675	1.0211	300.0	1	285.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50012	306.65	150.906	109.287	-109.287	1.02	350.0	1	332.5	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50013	-0.068	132.07	300.0	-200.0	1.017	300.0	1	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50014	627.138	458.768	305.123	-218.57500000000002	1.0454	700.0	1	630.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50015	1075.548	511.038	523.068	-374.7	1.0455	1200.0	1	1080.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50016	598.151	291.966	305.123	-218.57500000000002	1.0531	700.0	1	630.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50017	527.936	88.577	261.534	-187.35	1.0092	600.0	1	540.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50018	1056.356	332.769	523.068	-374.7	1.0307	1200.0	1	1080.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50019	298.243	124.309	156.125	-156.125	1.03	500.0	1	475.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
	50020	2128.315	381.697	1405.125	-1405.125	1.0185	4500.0	1	4275.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0	0.0
];

%% branch data
%    fbus    tbus    r    x    b    rateA    rateB    rateC    ratio    angle    status    angmin    angmax
mpc.branch = [
	1011	1013	0.01	0.07	0.0138	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1011	1013	0.01	0.07	0.0138	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1012	1014	0.0140237	0.09	0.01805	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1012	1014	0.0140237	0.09	0.01805	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1013	1014	0.00698225	0.05	0.01009	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1013	1014	0.00698225	0.05	0.01009	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1021	1022	0.03	0.2	0.03026	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1021	1022	0.03	0.2	0.03026	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1041	1043	0.01	0.06	0.01221	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1041	1043	0.01	0.06	0.01221	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1041	1045	0.0149704	0.12	0.02495	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1041	1045	0.0149704	0.12	0.02495	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1042	1044	0.0379882	0.28	0.05999	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1042	1044	0.0379882	0.28	0.05999	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1042	1045	0.05	0.3	0.05999	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1043	1044	0.01	0.08	0.01593	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	1043	1044	0.01	0.08	0.01593	350.0	350.0	350.0	0	0	1	-40.0	40.0								
	2031	2032	0.0120041	0.09	0.01521	500.0	500.0	500.0	0	0	1	-40.0	40.0								
	2031	2032	0.0120041	0.09	0.01521	500.0	500.0	500.0	0	0	1	-40.0	40.0								
	4011	4012	0.001	0.008	0.20106	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4011	4021	0.006	0.06	1.79949	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4011	4022	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4011	4071	0.005	0.045	1.4024	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4012	4022	0.004	0.035	1.05056	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4012	4071	0.005	0.05	1.49792	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4021	4032	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4021	4042	0.01	0.1	3.00086	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4022	4031	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4022	4031	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4031	4032	0.001	0.01	0.30159	1400.0	1400.0	1400.0	0	0	0	-40.0	40.0								
	4031	4041	0.006	0.08	2.39766	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4031	4041	0.006	0.08	2.39766	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4032	4042	0.01	0.066667	2.00058	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4032	4044	0.006	0.08	2.39766	1400.0	1400.0	1400.0	0	0	0	-40.0	40.0								
	4041	4044	0.003	0.03	0.89974	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4041	4061	0.006	0.045	1.30189	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4042	4043	0.002	0.015	0.49763	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4042	4044	0.002	0.02	0.59818	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4043	4044	0.001	0.01	0.30159	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4043	4046	0.001	0.01	0.30159	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4043	4047	0.002	0.02	0.59818	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4044	4045	0.002	0.02	0.59818	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4044	4045	0.002	0.02	0.59818	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4045	4051	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4045	4051	0.004	0.04	1.20134	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4045	4062	0.011	0.08	2.39766	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4046	4047	0.001	0.015	0.49763	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4061	4062	0.002	0.02	0.59818	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4062	4063	0.003	0.03	0.89974	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4062	4063	0.003	0.03	0.89974	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4071	4072	0.003	0.03	3.00086	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	4071	4072	0.003	0.03	3.00086	1400.0	1400.0	1400.0	0	0	1	-40.0	40.0								
	1041	1	0.0	0.00833333333	0.0	1200.0	1200.0	1200.0	1.0	0.0	1	-40.0	40.0								
	1042	2	0.0	0.0166666667	0.0	600.0	600.0	600.0	1.0	0.0	1	-40.0	40.0								
	1043	3	0.0	0.0217391304	0.0	459.99999999999994	459.99999999999994	459.99999999999994	1.01	0.0	1	-40.0	40.0								
	1044	4	0.0	0.00625	0.0	1600.0	1600.0	1600.0	0.99	0.0	1	-40.0	40.0								
	1045	5	0.0	0.00714285714	0.0	1400.0	1400.0	1400.0	1.0	0.0	1	-40.0	40.0								
	1011	11	0.0	0.025	0.0	400.0	400.0	400.0	1.04	0.0	1	-40.0	40.0								
	1012	12	0.0	0.0166666667	0.0	600.0	600.0	600.0	1.05	0.0	1	-40.0	40.0								
	1013	13	0.0	0.05	0.0	200.0	200.0	200.0	1.04	0.0	1	-40.0	40.0								
	1022	22	0.0	0.0178571429	0.0	560.0	560.0	560.0	1.04	0.0	1	-40.0	40.0								
	2031	31	0.0	0.05	0.0	200.0	200.0	200.0	1.01	0.0	1	-40.0	40.0								
	2032	32	0.0	0.025	0.0	400.0	400.0	400.0	1.06	0.0	1	-40.0	40.0								
	4041	41	0.0	0.00925925926	0.0	1080.0	1080.0	1080.0	1.04	0.0	1	-40.0	40.0								
	4042	42	0.0	0.0125	0.0	800.0	800.0	800.0	1.03	0.0	1	-40.0	40.0								
	4043	43	0.0	0.00555555556	0.0	1800.0	1800.0	1800.0	1.02	0.0	1	-40.0	40.0								
	4046	46	0.0	0.00714285714	0.0	1400.0	1400.0	1400.0	1.02	0.0	1	-40.0	40.0								
	4047	47	0.0	0.05	0.0	200.0	200.0	200.0	1.04	0.0	1	-40.0	40.0								
	4051	51	0.0	0.00625	0.0	1600.0	1600.0	1600.0	1.05	0.0	1	-40.0	40.0								
	4061	61	0.0	0.01	0.0	1000.0	1000.0	1000.0	1.03	0.0	1	-40.0	40.0								
	4062	62	0.0	0.0166666667	0.0	600.0	600.0	600.0	1.04	0.0	1	-40.0	40.0								
	4063	63	0.0	0.00847457627	0.0	1180.0	1180.0	1180.0	1.03	0.0	1	-40.0	40.0								
	4071	71	0.0	0.0166666667	0.0	600.0	600.0	600.0	1.03	0.0	1	-40.0	40.0								
	4072	72	0.0	0.0025	0.0	4000.0	4000.0	4000.0	1.05	0.0	1	-40.0	40.0								
	4011	1011	0.0	0.008	0.0	1250.0	1250.0	1250.0	0.95	0.0	1	-40.0	40.0								
	4012	1012	0.0	0.008	0.0	1250.0	1250.0	1250.0	0.95	0.0	1	-40.0	40.0								
	1012	50001	0.0	0.01875	0.0	800.0	800.0	800.0	1.0	0.0	1	-40.0	40.0								
	1013	50002	0.0	0.025	0.0	600.0	600.0	600.0	1.0	0.0	1	-40.0	40.0								
	1014	50003	0.0	0.0214285714	0.0	700.0	700.0	700.0	1.0	0.0	1	-40.0	40.0								
	1021	50004	0.0	0.025	0.0	600.0	600.0	600.0	1.0	0.0	1	-40.0	40.0								
	4022	1022	0.0	0.01200048	0.0	833.3000000000001	833.3000000000001	833.3000000000001	0.93	0.0	1	-40.0	40.0								
	1022	50005	0.0	0.06	0.0	250.0	250.0	250.0	1.05	0.0	1	-40.0	40.0								
	1042	50006	0.0	0.0375	0.0	400.0	400.0	400.0	1.05	0.0	1	-40.0	40.0								
	1043	50007	0.0	0.075	0.0	200.0	200.0	200.0	1.05	0.0	1	-40.0	40.0								
	4044	1044	0.0	0.01	0.0	1000.0	1000.0	1000.0	1.03	0.0	1	-40.0	40.0								
	4044	1044	0.0	0.01	0.0	1000.0	1000.0	1000.0	1.03	0.0	1	-40.0	40.0								
	4045	1045	0.0	0.01	0.0	1000.0	1000.0	1000.0	1.04	0.0	1	-40.0	40.0								
	4045	1045	0.0	0.01	0.0	1000.0	1000.0	1000.0	1.04	0.0	1	-40.0	40.0								
	4031	2031	0.0	0.01200048	0.0	833.3000000000001	833.3000000000001	833.3000000000001	1.0	0.0	1	-40.0	40.0								
	2032	50008	0.0	0.0176470588	0.0	850.0	850.0	850.0	1.05	0.0	1	-40.0	40.0								
	4011	50009	0.0	0.015	0.0	1000.0	1000.0	1000.0	1.05	0.0	1	-40.0	40.0								
	4012	50010	0.0	0.01875	0.0	800.0	800.0	800.0	1.05	0.0	1	-40.0	40.0								
	4021	50011	0.0	0.05	0.0	300.0	300.0	300.0	1.05	0.0	1	-40.0	40.0								
	4031	50012	0.0	0.0428571429	0.0	350.0	350.0	350.0	1.05	0.0	1	-40.0	40.0								
	4041	50013	0.0	0.0333333333	0.0	300.0	300.0	300.0	1.05	0.0	1	-40.0	40.0								
	4042	50014	0.0	0.0214285714	0.0	700.0	700.0	700.0	1.05	0.0	1	-40.0	40.0								
	4047	50015	0.0	0.0125	0.0	1200.0	1200.0	1200.0	1.05	0.0	1	-40.0	40.0								
	4051	50016	0.0	0.0214285714	0.0	700.0	700.0	700.0	1.05	0.0	1	-40.0	40.0								
	4062	50017	0.0	0.025	0.0	600.0	600.0	600.0	1.05	0.0	1	-40.0	40.0								
	4063	50018	0.0	0.0125	0.0	1200.0	1200.0	1200.0	1.05	0.0	1	-40.0	40.0								
	4071	50019	0.0	0.03	0.0	500.0	500.0	500.0	1.05	0.0	1	-40.0	40.0								
	4072	50020	0.0	0.00333333333	0.0	4500.0	4500.0	4500.0	1.05	0.0	1	-40.0	40.0								
];

%%-----  OPF Data  -----%%
%% cost data
%    1    startup    shutdown    n    x1    y1    ...    xn    yn
%    2    startup    shutdown    n    c(n-1)    ...    c0
mpc.gencost = [
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.1	1000.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
	2	0.0	0.0	3	0.001	10.0	0.0
];

%% bus names
mpc.bus_name = {
	'LOAD 1041   '
	'LOAD 1042   '
	'LOAD 1043   '
	'LOAD 1044   '
	'LOAD 1043   '
	'LOAD 1011   '
	'LOAD 1012   '
	'LOAD 1013   '
	'LOAD 1022   '
	'LOAD 2031   '
	'LOAD 2032   '
	'LOAD 4041   '
	'LOAD 4042   '
	'LOAD 4043   '
	'LOAD 4046   '
	'LOAD 4047   '
	'LOAD 4051   '
	'LOAD 4061   '
	'LOAD 4062   '
	'LOAD 4063   '
	'LOAD 4071   '
	'LOAD 4072   '
	'1011        '
	'1012        '
	'1013        '
	'1014        '
	'1021        '
	'1022        '
	'1041        '
	'1042        '
	'1043        '
	'1044        '
	'1045        '
	'2031        '
	'2032        '
	'4011        '
	'4012        '
	'4021        '
	'4022        '
	'4031        '
	'4032        '
	'4041        '
	'4042        '
	'4043        '
	'4044        '
	'4045        '
	'4046        '
	'4047        '
	'4051        '
	'4061        '
	'4062        '
	'4063        '
	'4071        '
	'4072        '
	'G1          '
	'G2          '
	'G3          '
	'G4          '
	'G5          '
	'G6          '
	'G7          '
	'G8          '
	'G9          '
	'G10         '
	'G11         '
	'G12         '
	'G13         '
	'G14         '
	'G15         '
	'G16         '
	'G17         '
	'G18         '
	'G19         '
	'G20         '
};

