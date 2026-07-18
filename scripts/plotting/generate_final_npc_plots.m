function generate_final_npc_plots(stopTime)
% Generate report figures only from the final saved device-level simulations.

if nargin < 1, stopTime = 12e-3; end
paths = project_paths();
resultDir = paths.results;
plotDir = paths.figures;
caseFile = @(vin) npc_case_filename(resultDir,vin,stopTime);

vinCases = [350 740 1000];
colors = [0.10 0.38 0.65; 0.12 0.58 0.37; 0.82 0.30 0.18];

%% Closed-loop startup and final regulation.
fig = figure('Color','w','Position',[80 80 1500 900]);
configure_portable_plot_font(fig);
tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');
ax1 = nexttile;
hold(ax1,'on');
for k = 1:numel(vinCases)
    out = loadOutput(caseFile(vinCases(k)));
    t = out.log_vout.time(:)*1e3;
    v = out.log_vout.signals.values(:);
    plot(ax1,t,v,'LineWidth',1.35,'Color',colors(k,:), ...
        'DisplayName',sprintf('%d V input',vinCases(k)));
end
yline(ax1,15,'k--','15 V reference','LineWidth',1.1,'HandleVisibility','off');
yline(ax1,15*1.03,':','+3%','Color',[0.4 0.4 0.4],'HandleVisibility','off');
yline(ax1,15*0.97,':','-3%','Color',[0.4 0.4 0.4],'HandleVisibility','off');
xlabel(ax1,'Time (ms)');
ylabel(ax1,'Output voltage (V)');
title(ax1,'Closed-loop startup across the full input range');
legend(ax1,'Location','southeast');
grid(ax1,'on');
xlim(ax1,[0 stopTime*1e3]);

summary = readtable(fullfile(resultDir,'summary.csv'));
ax2 = nexttile;
yyaxis(ax2,'left');
plot(ax2,summary.Vin_V,summary.VoutAvg_V,'o-','LineWidth',1.8, ...
    'MarkerSize',8,'Color',[0.08 0.42 0.62]);
yline(ax2,15,'k--','HandleVisibility','off');
yline(ax2,15*1.03,':','Color',[0.45 0.45 0.45],'HandleVisibility','off');
yline(ax2,15*0.97,':','Color',[0.45 0.45 0.45],'HandleVisibility','off');
ylabel(ax2,'Steady output voltage (V)');
ylim(ax2,[14.5 15.5]);
yyaxis(ax2,'right');
bar(ax2,summary.Vin_V,summary.Ripple_mVpp,0.26, ...
    'FaceColor',[0.91 0.55 0.16],'FaceAlpha',0.72);
yline(ax2,50,'r--','50 mVpp limit','LineWidth',1.1,'HandleVisibility','off');
ylabel(ax2,'Output ripple (mVpp)');
ylim(ax2,[0 60]);
xlabel(ax2,'Input voltage (V)');
title(ax2,'Final regulation and ripple metrics (300 W load)');
grid(ax2,'on');
exportFigure(fig,plotDir,'01_closed_loop_full_input.png');

%% Eight gate commands and corresponding power-stage waveforms at 740 V.
out = loadOutput(caseFile(740));
t = out.log_vout.time(:);
Tsw = 1/150e3;
t0 = 7.55e-3;
keep = t >= t0 & t <= t0+2*Tsw;
tw = (t(keep)-t0)*1e6;

fig = figure('Color','w','Position',[60 35 1650 1150]);
configure_portable_plot_font(fig);
tiledlayout(fig,6,1,'TileSpacing','compact','Padding','compact');
plotGateGroup(nexttile,out,keep,tw,{'QA1','QA2','QA3','QA4'},'A-leg four series MOSFET gate commands');
plotGateGroup(nexttile,out,keep,tw,{'QB1','QB2','QB3','QB4'},'B-leg four series MOSFET gate commands');

ax = nexttile;
yyaxis(ax,'left');
stairs(ax,tw,out.log_stateA.signals.values(keep),'LineWidth',1.15,'DisplayName','state A');
hold(ax,'on');
stairs(ax,tw,out.log_stateB.signals.values(keep),'LineWidth',1.15,'DisplayName','state B');
ylabel(ax,'P/O/N state');
yticks(ax,[-1 0 1]); yticklabels(ax,{'N','O','P'});
yyaxis(ax,'right');
plot(ax,tw,out.log_uab.signals.values(keep),'k','LineWidth',1.05,'DisplayName','u_{AB}');
ylabel(ax,'u_{AB} (V)');
title(ax,'P-O-N states and transformer-primary applied voltage');
legend(ax,'Location','eastoutside');
grid(ax,'on'); xlim(ax,[tw(1) tw(end)]);

ax = nexttile;
yyaxis(ax,'left');
plot(ax,tw,out.log_vsec.signals.values(keep),'Color',[0.55 0.15 0.62], ...
    'LineWidth',1.1,'DisplayName','v_{sec}');
ylabel(ax,'Secondary voltage (V)');
yyaxis(ax,'right');
plot(ax,tw,out.log_ipri.signals.values(keep),'LineWidth',1.1,'DisplayName','i_p');
hold(ax,'on');
plot(ax,tw,out.log_iaux.signals.values(keep),'LineWidth',1.1,'DisplayName','i_{aux}');
ylabel(ax,'Current (A)');
title(ax,'Isolation transformer voltage and commutation currents');
legend(ax,'Location','eastoutside'); grid(ax,'on'); xlim(ax,[tw(1) tw(end)]);

ax = nexttile;
plot(ax,tw,out.log_ilo1.signals.values(keep),'LineWidth',1.1,'DisplayName','i_{Lo1}');
hold(ax,'on');
plot(ax,tw,out.log_ilo2.signals.values(keep),'LineWidth',1.1,'DisplayName','i_{Lo2}');
plot(ax,tw,out.log_ilo1.signals.values(keep)+out.log_ilo2.signals.values(keep), ...
    'k','LineWidth',1.2,'DisplayName','i_o=i_{Lo1}+i_{Lo2}');
ylabel(ax,'Current (A)');
title(ax,'True current-doubler inductor currents');
legend(ax,'Location','eastoutside'); grid(ax,'on'); xlim(ax,[tw(1) tw(end)]);

ax = nexttile;
vout = out.log_vout.signals.values(keep);
plot(ax,tw,(vout-mean(vout))*1e3,'Color',[0.80 0.22 0.18],'LineWidth',1.25);
xlabel(ax,'Time in selected window (us)');
ylabel(ax,'Vout AC component (mV)');
title(ax,sprintf('Output switching ripple around %.4f V',mean(vout)));
grid(ax,'on'); xlim(ax,[tw(1) tw(end)]);
exportFigure(fig,plotDir,'02_eight_gates_and_power_waveforms_740V.png');

gateTable = table(tw, ...
    out.log_g_QA1.signals.values(keep),out.log_g_QA2.signals.values(keep), ...
    out.log_g_QA3.signals.values(keep),out.log_g_QA4.signals.values(keep), ...
    out.log_g_QB1.signals.values(keep),out.log_g_QB2.signals.values(keep), ...
    out.log_g_QB3.signals.values(keep),out.log_g_QB4.signals.values(keep), ...
    out.log_stateA.signals.values(keep),out.log_stateB.signals.values(keep), ...
    out.log_uab.signals.values(keep),out.log_vsec.signals.values(keep), ...
    out.log_ipri.signals.values(keep),out.log_iaux.signals.values(keep), ...
    out.log_ilo1.signals.values(keep),out.log_ilo2.signals.values(keep),vout, ...
    'VariableNames',{'time_us','gQA1','gQA2','gQA3','gQA4','gQB1','gQB2', ...
    'gQB3','gQB4','stateA','stateB','uAB_V','vsec_V','ipri_A','iaux_A', ...
    'iLo1_A','iLo2_A','vout_V'});
writetable(gateTable,fullfile(resultDir,'waveform_window_740V.csv'));

%% Nanosecond soft-switching zoom: two outer devices and one inner device.
devices = {'QA1','QB1','QA2'};
descriptions = {'A-leg outer: near-ZVS','B-leg outer: ZVS','A-leg inner: clamped reduced-voltage turn-on'};
fig = figure('Color','w','Position',[150 30 1300 1200]);
configure_portable_plot_font(fig);
tiledlayout(fig,6,1,'TileSpacing','compact','Padding','compact');
icom = out.log_ipri.signals.values(:)+out.log_iaux.signals.values(:);
for d = 1:numel(devices)
    name = devices{d};
    gate = out.(['log_g_' name]).signals.values(:);
    vds = abs(out.(['log_vds_' name]).signals.values(:));
    rise = find(gate(2:end)>=0.5 & gate(1:end-1)<0.5)+1;
    rise = rise(t(rise)>=7e-3);
    preV = vds(rise-1);
    target = median(preV);
    [~,ix] = min(abs(preV-target));
    edge = rise(ix);
    w = t >= t(edge)-320e-9 & t <= t(edge)+220e-9;
    tx = (t(w)-t(edge))*1e9;

    ax = nexttile;
    yyaxis(ax,'left');
    plot(ax,tx,vds(w),'LineWidth',1.35,'Color',[0.08 0.39 0.68]);
    ylabel(ax,'Vds (V)');
    yyaxis(ax,'right');
    stairs(ax,tx,gate(w),'LineWidth',1.25,'Color',[0.82 0.24 0.16]);
    ylabel(ax,'Gate'); ylim(ax,[-0.1 1.2]);
    xline(ax,0,'k--','Turn-on');
    title(ax,sprintf('%s, %s: Vds just before gate = %.2f V', ...
        name,descriptions{d},vds(edge-1)));
    grid(ax,'on'); xlim(ax,[tx(1) tx(end)]);

    ax = nexttile;
    plot(ax,tx,icom(w),'Color',[0.14 0.56 0.33],'LineWidth',1.25);
    yline(ax,0,'k:'); xline(ax,0,'k--');
    ylabel(ax,'i_p+i_{aux} (A)');
    if d == numel(devices), xlabel(ax,'Time relative to gate rising edge (ns)'); end
    grid(ax,'on'); xlim(ax,[tx(1) tx(end)]);
end
exportFigure(fig,plotDir,'03_soft_switching_zoom_740V.png');

%% Input-output relationship and measured effective duty.
fig = figure('Color','w','Position',[100 90 1500 720]);
configure_portable_plot_font(fig);
tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
ax = nexttile;
fill(ax,[350 1000 1000 350],[14.55 14.55 15.45 15.45], ...
    [0.88 0.94 0.90],'EdgeColor','none','DisplayName','15 V +/-3%');
hold(ax,'on');
plot(ax,summary.Vin_V,summary.VoutAvg_V,'o-','LineWidth',2,'MarkerSize',9, ...
    'Color',[0.05 0.40 0.64],'DisplayName','Device-level simulation');
yline(ax,15,'k--','15 V','HandleVisibility','off');
xlabel(ax,'Vin (V)'); ylabel(ax,'Vout (V)');
title(ax,'Closed-loop input-output characteristic');
legend(ax,'Location','best'); grid(ax,'on'); ylim(ax,[14.4 15.6]);

ax = nexttile;
vinLine = linspace(350,1000,300);
deqIdeal = 270./vinLine;
plot(ax,vinLine,deqIdeal,'k--','LineWidth',1.5,'DisplayName','Ideal D_{eq}=270/Vin');
hold(ax,'on');
plot(ax,summary.Vin_V,summary.DeqMeasured,'s-','LineWidth',2,'MarkerSize',8, ...
    'Color',[0.78 0.27 0.17],'DisplayName','Measured D_{eq}');
xlabel(ax,'Vin (V)'); ylabel(ax,'Effective volt-second duty D_{eq}');
title(ax,{'Current-doubler conversion law', ...
    'Vout=(Ns/Np)(D_{eq}/2)Vin, Np:Ns=9:1'});
legend(ax,'Location','northeast'); grid(ax,'on');
exportFigure(fig,plotDir,'04_input_output_relationship.png');

fprintf('PLOT_DIR=%s\n',plotDir);
end

function out = loadOutput(file)
s = load(file);
if isfield(s,'out')
    out = s.out;
elseif isfield(s,'o')
    out = s.o;
else
    error('No SimulationOutput found in %s.',file);
end
end

function plotGateGroup(ax,out,keep,tw,names,titleText)
hold(ax,'on');
offset = 1.35;
for k = 1:numel(names)
    gate = out.(['log_g_' names{k}]).signals.values(keep);
    stairs(ax,tw,gate+(k-1)*offset,'LineWidth',1.15,'DisplayName',names{k});
end
yticks(ax,(0:numel(names)-1)*offset+0.5);
yticklabels(ax,names);
ylim(ax,[-0.15 (numel(names)-1)*offset+1.15]);
ylabel(ax,'Gate state');
title(ax,titleText);
grid(ax,'on'); xlim(ax,[tw(1) tw(end)]);
end

function exportFigure(fig,plotDir,name)
file = fullfile(plotDir,name);
exportgraphics(fig,file,'Resolution',220);
close(fig);
end
