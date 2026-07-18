function [modelFile,model] = build_npc_tl_psfb_cdr_final()
% Device-level NPC three-level PSFB with isolated current-doubler output.

bdclose('all');

paths = project_paths();
model = 'npc_tl_psfb_cdr_final';
modelFile = paths.model;
modelDir = fileparts(modelFile);
if ~exist(modelDir,'dir'), mkdir(modelDir); end

load_system('sps_lib');
load_system('simulink');
if bdIsLoaded(model), close_system(model,0); end
new_system(model);
open_system(model);

Ts = 20e-9;
set_param(model, ...
    'StopTime','8e-3', ...
    'SolverType','Fixed-step', ...
    'Solver','FixedStepDiscrete', ...
    'FixedStep',sprintf('%.12g',Ts), ...
    'ReturnWorkspaceOutputs','on');

lib.pg = 'sps_lib/powergui';
lib.vdc = 'sps_lib/Sources/DC Voltage Source';
lib.gnd = 'sps_lib/Utilities/Ground';
lib.mosfet = 'sps_lib/Power Electronics/Mosfet';
lib.diode = 'sps_lib/Power Electronics/Diode';
lib.rlc = 'sps_lib/Passives/Series RLC Branch';
lib.xfmr = 'sps_lib/Power Grid Elements/Linear Transformer';
lib.vmeas = 'sps_lib/Sensors and Measurements/Voltage Measurement';
lib.imeas = 'sps_lib/Sensors and Measurements/Current Measurement';
lib.clock = 'simulink/Sources/Clock';
lib.constant = 'simulink/Sources/Constant';
lib.goto = 'simulink/Signal Routing/Goto';
lib.from = 'simulink/Signal Routing/From';
lib.demux = 'simulink/Signal Routing/Demux';
lib.toWs = 'simulink/Sinks/To Workspace';
lib.scope = 'simulink/Sinks/Scope';
lib.mux = 'simulink/Signal Routing/Mux';
lib.sum = 'simulink/Math Operations/Add';

add(lib.pg,'powergui',[20 20 125 65],struct( ...
    'SimulationMode','Discrete','SampleTime',sprintf('%.12g',Ts)));
add(lib.vdc,'Vdc_input',[25 275 95 345],struct('Amplitude','740'));
add(lib.gnd,'PRI_GND',[30 595 90 650],struct());
add(lib.imeas,'Iin_measure',[100 205 160 260],struct('OutputType','Real'));
addR('Rin_damp_0p1',[115 285 180 335],'0.1','right');
addC('Cdc1_47uF',[210 90 275 170],'47e-6','0.015','down');
addC('Cdc2_47uF',[210 430 275 510],'47e-6','0.015','down');
addR('Rbal1_1p5M',[300 90 365 170],'1.5e6','down');
addR('Rbal2_1p5M',[300 430 365 510],'1.5e6','down');

switches = {'QA1','QA2','QA3','QA4','QB1','QB2','QB3','QB4'};
pos = [430 55 500 115; 430 190 500 250; 430 360 500 420; 430 495 500 555; ...
       755 55 825 115; 755 190 825 250; 755 360 825 420; 755 495 825 555];
for k = 1:numel(switches)
    addSwitch(switches{k},pos(k,:),0.06,80e-12);
end

addClamp('DCA_UP',[545 145 615 195],'right');
addClamp('DCA_LOW',[545 435 615 485],'left');
addClamp('DCB_UP',[870 145 940 195],'right');
addClamp('DCB_LOW',[870 435 940 485],'left');

% Main isolated power-transfer path.
add(lib.imeas,'Ipri_measure',[965 250 1025 305],struct('OutputType','Real'));
addRL('Lr_22uH',[1050 250 1140 305],'22e-6','0.08','right');
addC('Cb_1uF',[1165 250 1255 305],'1e-6','0.03','right');
add(lib.xfmr,'T_iso_9to1',[1295 135 1425 420],struct( ...
    'UNITS','SI', ...
    'NominalPower','[300 150e3]', ...
    'winding1','[180 0.08 1e-6]', ...
    'winding2','[20 0.003 50e-9]', ...
    'ThreeWindings','off', ...
    'RmLm','[2e5 5e-3]', ...
    'Measurements','None'));

% Innovation branch: DC-blocked auxiliary commutation current path.
add(lib.imeas,'Iaux_measure',[540 605 600 660],struct('OutputType','Real'));
addRLC('Laux_Caux_comm',[625 605 745 660],'200e-6','1e-6','0.08','right');

% True single-secondary current doubler.
addRL('Lo1_47uH',[1485 120 1575 175],'47e-6','0.008','right');
addRL('Lo2_47uH',[1485 235 1575 290],'47e-6','0.008','right');
add(lib.imeas,'ILo1_measure',[1600 120 1660 175],struct('OutputType','Real'));
add(lib.imeas,'ILo2_measure',[1600 235 1660 290],struct('OutputType','Real'));
addSwitch('SR1',[1470 370 1540 430],0.002,180e-12);
addSwitch('SR2',[1600 370 1670 430],0.002,180e-12);
addRectDiode('D5_deadtime',[1470 480 1540 530],'left');
addRectDiode('D6_deadtime',[1600 480 1670 530],'left');
addC('Co_4700uF',[1745 325 1815 405],'4700e-6','0.001','down');
add(lib.imeas,'Iload_measure',[1825 250 1885 305],struct('OutputType','Real'));
addR('Rload_0p75ohm',[1890 325 1960 405],'0.75','down');
add(lib.gnd,'ISO_GND',[1665 585 1725 640],struct());

% Electrical measurements.
add(lib.vmeas,'Vin_measure',[100 680 170 735],struct('OutputType','Real'));
add(lib.vmeas,'Vtop_measure',[205 680 275 735],struct('OutputType','Real'));
add(lib.vmeas,'Vbot_measure',[305 680 375 735],struct('OutputType','Real'));
add(lib.vmeas,'VAB_measure',[970 90 1040 145],struct('OutputType','Real'));
add(lib.vmeas,'Vsec_measure',[1435 190 1505 245],struct('OutputType','Real'));
add(lib.vmeas,'Vout_measure',[2010 325 2080 405],struct('OutputType','Real'));

% Input source, split capacitors, and neutral O.
connectP('Vdc_input','R',1,'Iin_measure','L',1);
connectP('Iin_measure','R',1,'Rin_damp_0p1','L',1);
connectP('Rin_damp_0p1','R',1,'Cdc1_47uF','L',1);
connectP('Cdc1_47uF','R',1,'Cdc2_47uF','L',1);
connectP('Cdc2_47uF','R',1,'Vdc_input','L',1);
connectP('Vdc_input','L',1,'PRI_GND','L',1);
connectP('Rin_damp_0p1','R',1,'Rbal1_1p5M','L',1);
connectP('Rbal1_1p5M','R',1,'Cdc1_47uF','R',1);
connectP('Cdc1_47uF','R',1,'Rbal2_1p5M','L',1);
connectP('Rbal2_1p5M','R',1,'Vdc_input','L',1);

% Four series devices in each NPC leg. A and B are the inner junctions.
connectP('Rin_damp_0p1','R',1,'QA1','L',1);
connectP('QA1','R',1,'QA2','L',1);
connectP('QA2','R',1,'QA3','L',1);
connectP('QA3','R',1,'QA4','L',1);
connectP('QA4','R',1,'Vdc_input','L',1);
connectP('Cdc1_47uF','R',1,'DCA_UP','L',1);
connectP('DCA_UP','R',1,'QA1','R',1);
connectP('QA3','R',1,'DCA_LOW','L',1);
connectP('DCA_LOW','R',1,'Cdc1_47uF','R',1);

connectP('Rin_damp_0p1','R',1,'QB1','L',1);
connectP('QB1','R',1,'QB2','L',1);
connectP('QB2','R',1,'QB3','L',1);
connectP('QB3','R',1,'QB4','L',1);
connectP('QB4','R',1,'Vdc_input','L',1);
connectP('Cdc1_47uF','R',1,'DCB_UP','L',1);
connectP('DCB_UP','R',1,'QB1','R',1);
connectP('QB3','R',1,'DCB_LOW','L',1);
connectP('DCB_LOW','R',1,'Cdc1_47uF','R',1);

% A -> Lr -> Cb -> primary -> B.
connectP('QA2','R',1,'Ipri_measure','L',1);
connectP('Ipri_measure','R',1,'Lr_22uH','L',1);
connectP('Lr_22uH','R',1,'Cb_1uF','L',1);
connectP('Cb_1uF','R',1,'T_iso_9to1','L',1);
connectP('T_iso_9to1','L',2,'QB2','R',1);

% Symmetric auxiliary branch is directly across A-B and includes Caux.
connectP('QA2','R',1,'Iaux_measure','L',1);
connectP('Iaux_measure','R',1,'Laux_Caux_comm','L',1);
connectP('Laux_Caux_comm','R',1,'QB2','R',1);

% Single secondary: neither S1 nor S2 is tied directly to isolated ground.
connectP('T_iso_9to1','R',1,'Lo1_47uH','L',1);
connectP('T_iso_9to1','R',2,'Lo2_47uH','L',1);
connectP('Lo1_47uH','R',1,'ILo1_measure','L',1);
connectP('Lo2_47uH','R',1,'ILo2_measure','L',1);
connectP('ILo1_measure','R',1,'Co_4700uF','L',1);
connectP('ILo2_measure','R',1,'Co_4700uF','L',1);

% SR drains are at S1/S2; sources return to the isolated ground.
connectP('T_iso_9to1','R',1,'SR1','L',1);
connectP('SR1','R',1,'ISO_GND','L',1);
connectP('T_iso_9to1','R',2,'SR2','L',1);
connectP('SR2','R',1,'ISO_GND','L',1);
connectP('ISO_GND','L',1,'D5_deadtime','L',1);
connectP('D5_deadtime','R',1,'T_iso_9to1','R',1);
connectP('ISO_GND','L',1,'D6_deadtime','L',1);
connectP('D6_deadtime','R',1,'T_iso_9to1','R',2);

connectP('Co_4700uF','R',1,'ISO_GND','L',1);
connectP('Co_4700uF','L',1,'Iload_measure','L',1);
connectP('Iload_measure','R',1,'Rload_0p75ohm','L',1);
connectP('Rload_0p75ohm','R',1,'ISO_GND','L',1);

% Measurement electrical connections.
connectP('Vin_measure','L',1,'Rin_damp_0p1','R',1);
connectP('Vin_measure','L',2,'Vdc_input','L',1);
connectP('Vtop_measure','L',1,'Rin_damp_0p1','R',1);
connectP('Vtop_measure','L',2,'Cdc1_47uF','R',1);
connectP('Vbot_measure','L',1,'Cdc1_47uF','R',1);
connectP('Vbot_measure','L',2,'Vdc_input','L',1);
connectP('VAB_measure','L',1,'QA2','R',1);
connectP('VAB_measure','L',2,'QB2','R',1);
connectP('Vsec_measure','L',1,'T_iso_9to1','R',1);
connectP('Vsec_measure','L',2,'T_iso_9to1','R',2);
connectP('Vout_measure','L',1,'Co_4700uF','L',1);
connectP('Vout_measure','L',2,'ISO_GND','L',1);

% Controller. Goto/From tags keep the visible power schematic readable.
add(lib.clock,'Clock',[25 820 65 850],struct());
add(lib.constant,'SR_enable',[25 885 90 915],struct('Value','1'));
ctrl = [model '/Closed_Loop_PON_Controller'];
add_block('simulink/User-Defined Functions/MATLAB Function',ctrl, ...
    'Position',[185 790 555 1010]);
rt = sfroot;
chart = rt.find('-isa','Stateflow.EMChart','Path',ctrl);
chart.Script = controllerCode();
set_param(model,'SimulationCommand','update');
connectS('Clock',1,'Closed_Loop_PON_Controller',1);
connectTag('Vin_measure',1,'sig_vin',[105 750 185 775]);
connectTag('Iin_measure',1,'sig_iin',[105 715 185 740]);
connectTag('Vout_measure',1,'sig_vout',[2020 430 2100 455]);
connectTag('Vtop_measure',1,'sig_vtop',[215 750 295 775]);
connectTag('Vbot_measure',1,'sig_vbot',[315 750 395 775]);
connectTag('VAB_measure',1,'sig_uab',[985 155 1065 180]);
connectTag('Vsec_measure',1,'sig_vsec',[1435 255 1515 280]);
connectTag('Ipri_measure',1,'sig_ipri',[970 315 1050 340]);
connectTag('Iaux_measure',1,'sig_iaux',[545 670 625 695]);
connectTag('ILo1_measure',1,'sig_ilo1',[1600 80 1680 105]);
connectTag('ILo2_measure',1,'sig_ilo2',[1600 300 1680 325]);
connectTag('Iload_measure',1,'sig_iload',[1840 205 1920 230]);

addFrom('From_vout_ctrl','sig_vout',[95 805 165 830]);
addFrom('From_vin_ctrl','sig_vin',[95 850 165 875]);
connectS('From_vout_ctrl',1,'Closed_Loop_PON_Controller',2);
connectS('From_vin_ctrl',1,'Closed_Loop_PON_Controller',3);
connectS('SR_enable',1,'Closed_Loop_PON_Controller',4);
addFrom('From_iload_ctrl','sig_iload',[95 930 165 955]);
connectS('From_iload_ctrl',1,'Closed_Loop_PON_Controller',5);

gateNames = [switches {'SR1','SR2'}];
for k = 1:numel(gateNames)
    tag = ['gate_' gateNames{k}];
    add(lib.goto,['Goto_' gateNames{k}],[610 760+27*k 690 780+27*k],struct('GotoTag',tag));
    connectS('Closed_Loop_PON_Controller',k,['Goto_' gateNames{k}],1);
end
for k = 1:numel(switches)
    addFrom(['From_' switches{k}],['gate_' switches{k}], ...
        [pos(k,1)-75 pos(k,2)+15 pos(k,1)-15 pos(k,2)+35]);
    connectS(['From_' switches{k}],1,switches{k},1);
end
addFrom('From_SR1','gate_SR1',[1380 385 1450 410]);
addFrom('From_SR2','gate_SR2',[1685 385 1755 410]);
connectS('From_SR1',1,'SR1',1);
connectS('From_SR2',1,'SR2',1);

% D5/D6 measurement vectors are [current, voltage]. Keep them available for
% aligned dead-time-current plots without inserting extra series sensors.
connectTag('D5_deadtime',1,'meas_D5',[1765 470 1845 490]);
connectTag('D6_deadtime',1,'meas_D6',[1765 510 1845 530]);

% State and phase tags from controller outputs 11-13.
for k = 11:13
    tags = {'stateA','stateB','phase'};
    tag = ['ctrl_' tags{k-10}];
    name = ['Goto_' tags{k-10}];
    add(lib.goto,name,[735 760+27*k 815 780+27*k],struct('GotoTag',tag));
    connectS('Closed_Loop_PON_Controller',k,name,1);
end

% MOSFET measurement vectors: signal 2 is Vds.
for k = 1:numel(gateNames)
    sw = gateNames{k};
    if k <= 8
        x = pos(k,1)+85;
        y = pos(k,2)+10;
    else
        x = 1765;
        y = 340+45*(k-8);
    end
    dm = ['Demux_' sw];
    add(lib.demux,dm,[x y x+5 y+30],struct('Outputs','2'));
    connectS(sw,1,dm,1);
    connectTag(dm,2,['vds_' sw],[x+25 y+5 x+95 y+25]);
end

% Centralized logging area fed only by tags.
logX = 2140;
logY = 40;
signalTags = {'sig_vout','sig_vin','sig_iin','sig_uab','sig_ipri','sig_iaux','sig_vsec', ...
    'sig_ilo1','sig_ilo2','sig_iload','sig_vtop','sig_vbot','ctrl_phase','ctrl_stateA','ctrl_stateB', ...
    'meas_D5','meas_D6'};
variables = {'log_vout','log_vin','log_iin','log_uab','log_ipri','log_iaux','log_vsec', ...
    'log_ilo1','log_ilo2','log_iload','log_vtop','log_vbot','log_phase','log_stateA','log_stateB', ...
    'log_meas_D5','log_meas_D6'};
for k = 1:numel(signalTags)
    addFrom(['LogFrom_' variables{k}],signalTags{k},[logX logY+32*k logX+75 logY+32*k+20]);
    logSignal(['LogFrom_' variables{k}],1,variables{k}, ...
        [logX+95 logY+32*k logX+220 logY+32*k+22]);
end

for k = 1:numel(gateNames)
    addFrom(['GateLogFrom_' gateNames{k}],['gate_' gateNames{k}], ...
        [logX+260 logY+32*k logX+335 logY+32*k+20]);
    logSignal(['GateLogFrom_' gateNames{k}],1,['log_g_' gateNames{k}], ...
        [logX+355 logY+32*k logX+480 logY+32*k+22]);
    addFrom(['VdsLogFrom_' gateNames{k}],['vds_' gateNames{k}], ...
        [logX+520 logY+32*k logX+595 logY+32*k+20]);
    logSignal(['VdsLogFrom_' gateNames{k}],1,['log_vds_' gateNames{k}], ...
        [logX+615 logY+32*k logX+740 logY+32*k+22]);
end

% Scopes are fed from tags and remain editable in the delivered model.
scopeY = 570;
scopeTags = {'sig_vout','sig_uab','sig_ipri','sig_ilo1','sig_ilo2','ctrl_phase'};
add(lib.mux,'Mux_Overview',[2200 scopeY 2205 scopeY+130],struct('Inputs','6'));
add(lib.scope,'Scope_Overview',[2260 scopeY+35 2340 scopeY+95],struct());
for k = 1:numel(scopeTags)
    nm = ['ScopeFrom_' num2str(k)];
    addFrom(nm,scopeTags{k},[2090 scopeY+20*k 2165 scopeY+20*k+18]);
    connectS(nm,1,'Mux_Overview',k);
end
connectS('Mux_Overview',1,'Scope_Overview',1);

note('DERIVED TOPOLOGY: NPC three-level PSFB + DC-blocked auxiliary LC commutation + 9:1 isolation + true current doubler.',[170 15 1430 40]);
note('A=QA2/QA3, B=QB2/QB3, O=Cdc1/Cdc2. Each leg is one four-device series string.',[380 570 1200 595]);
note('Single secondary: S1->Lo1, S2->Lo2; SR1/SR2 return S1/S2 to isolated ground.',[1435 545 2080 570]);
note('Ideal relation: Vo=(Ns/Np)/(2Ts)*integral(abs(uAB)dt); Np:Ns=9:1.',[965 735 1740 765]);

set_param(model,'ZoomFactor','FitSystem');
save_system(model,modelFile);
end

function code = controllerCode()
code = char([ ...
    "function [qa1,qa2,qa3,qa4,qb1,qb2,qb3,qb4,sr1,sr2,stateA,stateB,phase] = ctrl(t,vout,vin,srEnable,iout)" newline ...
"%#codegen" newline ...
    "persistent integ phaseHold lastCycle burstOn ioutFilt lightMode voutPrev" newline ...
"fs = 150e3;" newline ...
"T = 1/fs;" newline ...
"zeroDwell = 0.025;" newline ...
"deadNorm = 220e-9/T;" newline ...
"Nps = 9;" newline ...
"if isempty(lastCycle)" newline ...
    "    integ = 0; phaseHold = 0.05; lastCycle = -1; burstOn = true;" newline ...
    "    ioutFilt = 0; lightMode = false; voutPrev = 0;" newline ...
"end" newline ...
"cycle = floor(t/T);" newline ...
"if cycle ~= lastCycle" newline ...
    "    ramp = min(t/1e-3,1);" newline ...
    "    if t < 1e-3 && vout > 14, ramp = 1; end" newline ...
"    vref = 15*ramp;" newline ...
    "    err = vref-vout;" newline ...
    "    ioutFilt = 0.98*ioutFilt+0.02*max(iout,0);" newline ...
    "    dvCycle = vout-voutPrev;" newline ...
    "    if t > 5e-3" newline ...
    "        if ioutFilt < 5.2 && abs(dvCycle) < 5e-3 && vout > 14.8" newline ...
    "            lightMode = true;" newline ...
    "        end" newline ...
    "        if ioutFilt > 6.0, lightMode = false; end" newline ...
    "    end" newline ...
    "    if ~lightMode || burstOn" newline ...
    "        integ = integ+err*T;" newline ...
    "    end" newline ...
"    integ = min(max(integ,-0.012),0.012);" newline ...
"    gainScale = min(1,350/max(vin,350));" newline ...
"    phaseFF = Nps*vref/max(vin,50)+(10/max(vin,50)+0.004)*ramp;" newline ...
"    cmd = phaseFF+0.0025*gainScale*err+8*gainScale*integ;" newline ...
    "    phaseHold = min(max(cmd,0.03),0.45);" newline ...
    "    if lightMode" newline ...
    "        if vout >= 15.008, burstOn = false; end" newline ...
    "        if vout <= 14.992, burstOn = true; end" newline ...
    "    else" newline ...
    "        burstOn = true;" newline ...
    "    end" newline ...
    "    voutPrev = vout;" newline ...
    "    lastCycle = cycle;" newline ...
    "end" newline ...
    "phase = phaseHold;" newline ...
"if ~burstOn" newline ...
"    qa1=0; qa2=1; qa3=1; qa4=0;" newline ...
"    qb1=0; qb2=1; qb3=1; qb4=0;" newline ...
    "    sr1=0; sr2=0; stateA=0; stateB=0;" newline ...
"    return;" newline ...
"end" newline ...
"pA = t/T-floor(t/T);" newline ...
"pB = pA-phaseHold;" newline ...
"if pB < 0, pB = pB+1; end" newline ...
"[qa1,qa2,qa3,qa4,stateA] = leg_gate(pA,zeroDwell,deadNorm);" newline ...
"[qb1,qb2,qb3,qb4,stateB] = leg_gate(pB,zeroDwell,deadNorm);" newline ...
"delta = stateA-stateB;" newline ...
"if srEnable < 0.5" newline ...
"    sr1=0; sr2=0;" newline ...
"elseif delta > 0.5" newline ...
"    sr1=0; sr2=1;" newline ...
"elseif delta < -0.5" newline ...
"    sr1=1; sr2=0;" newline ...
"else" newline ...
"    sr1=1; sr2=1;" newline ...
"end" newline ...
"end" newline ...
"" newline ...
"function [q1,q2,q3,q4,state] = leg_gate(p,z,td)" newline ...
"q1=0; q2=0; q3=0; q4=0; state=0;" newline ...
"if p < z" newline ...
"    q2=1; q3=1;" newline ...
"elseif p < z+td" newline ...
"    q2=1;" newline ...
"elseif p < 0.5-z" newline ...
"    q1=1; q2=1; state=1;" newline ...
"elseif p < 0.5-z+td" newline ...
"    q2=1;" newline ...
"elseif p < 0.5+z" newline ...
"    q2=1; q3=1;" newline ...
"elseif p < 0.5+z+td" newline ...
"    q3=1;" newline ...
"elseif p < 1-z" newline ...
"    q3=1; q4=1; state=-1;" newline ...
"elseif p < 1-z+td" newline ...
"    q3=1;" newline ...
"else" newline ...
"    q2=1; q3=1;" newline ...
"end" newline ...
"end" newline]);
end

function add(src,name,pos,params)
model = 'npc_tl_psfb_cdr_final';
dst = [model '/' name];
add_block(src,dst,'Position',pos);
if nargin >= 4
    fields = fieldnames(params);
    for k = 1:numel(fields)
        set_param(dst,fields{k},params.(fields{k}));
    end
end
end

function addSwitch(name,pos,ron,coss)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Power Electronics/Mosfet',name,pos,struct( ...
    'Ron',sprintf('%.12g',ron),'Lon','0','Rd','0.02','Vfd','1.8', ...
    'Rs','0.1','Cs',sprintf('%.12g',coss),'Measurements','on'));
set_param([model '/' name],'Orientation','down','BackgroundColor','lightBlue');
end

function addClamp(name,pos,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Power Electronics/Diode',name,pos,struct( ...
    'Ron','0.01','Lon','0','Vf','1.2','UseSnubber','on','Rs','0.1','Cs','60e-12'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','magenta');
end

function addRectDiode(name,pos,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Power Electronics/Diode',name,pos,struct( ...
    'Ron','0.003','Lon','0','Vf','0.45','UseSnubber','on','Rs','0.1','Cs','180e-12'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','magenta');
end

function addC(name,pos,cval,rval,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Passives/Series RLC Branch',name,pos,struct( ...
    'BranchType','RC','Resistance',rval,'Capacitance',cval, ...
    'Setx0','off','InitialVoltage','0','Measurements','None'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','green');
end

function addR(name,pos,rval,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Passives/Series RLC Branch',name,pos,struct( ...
    'BranchType','R','Resistance',rval,'Measurements','None'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','orange');
end

function addRL(name,pos,lval,rval,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Passives/Series RLC Branch',name,pos,struct( ...
    'BranchType','RL','Resistance',rval,'Inductance',lval, ...
    'SetiL0','off','InitialCurrent','0','Measurements','None'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','yellow');
end

function addRLC(name,pos,lval,cval,rval,orientation)
model = 'npc_tl_psfb_cdr_final';
add('sps_lib/Passives/Series RLC Branch',name,pos,struct( ...
    'BranchType','RLC','Resistance',rval,'Inductance',lval,'Capacitance',cval, ...
    'SetiL0','off','InitialCurrent','0','Setx0','off','InitialVoltage','0', ...
    'Measurements','None'));
set_param([model '/' name],'Orientation',orientation,'BackgroundColor','yellow');
end

function connectP(src,srcSide,srcIdx,dst,dstSide,dstIdx)
model = 'npc_tl_psfb_cdr_final';
sp = port(src,srcSide,srcIdx);
dp = port(dst,dstSide,dstIdx);
add_line(model,sp,dp,'autorouting','smart');
end

function connectS(src,srcIdx,dst,dstIdx)
model = 'npc_tl_psfb_cdr_final';
sp = port(src,'Outport',srcIdx);
dp = port(dst,'Inport',dstIdx);
add_line(model,sp,dp,'autorouting','smart');
end

function ph = port(blockName,side,idx)
model = 'npc_tl_psfb_cdr_final';
ports = get_param([model '/' blockName],'PortHandles');
switch side
    case 'L'
        ph = ports.LConn(idx);
    case 'R'
        ph = ports.RConn(idx);
    case 'Inport'
        ph = ports.Inport(idx);
    case 'Outport'
        ph = ports.Outport(idx);
    otherwise
        error('Unknown port side %s.',side);
end
end

function connectTag(src,srcIdx,tag,pos)
name = ['Tag_' tag];
add('simulink/Signal Routing/Goto',name,pos,struct('GotoTag',tag));
connectS(src,srcIdx,name,1);
end

function addFrom(name,tag,pos)
add('simulink/Signal Routing/From',name,pos,struct('GotoTag',tag));
end

function logSignal(src,srcIdx,varName,pos)
add('simulink/Sinks/To Workspace',varName,pos,struct( ...
    'VariableName',varName,'SaveFormat','Structure With Time'));
connectS(src,srcIdx,varName,1);
end

function note(txt,pos)
model = 'npc_tl_psfb_cdr_final';
ann = Simulink.Annotation(model,txt);
ann.Position = pos;
ann.FontSize = 11;
ann.FontWeight = 'bold';
end
