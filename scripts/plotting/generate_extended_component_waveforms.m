function generate_extended_component_waveforms(stopTime)
% Add device voltages and derived output-component currents to the aligned cycle plot.

if nargin < 1, stopTime = 12e-3; end
paths = project_paths();
resultDir = paths.results;
plotDir = paths.figures;

s = load(npc_case_filename(resultDir,740,stopTime));
out = s.out;
t = out.log_vout.time(:);
fs = 150e3;
T = 1/fs;
tStart = floor(7.55e-3/T)*T;
keep = t >= tStart & t <= tStart+T;
tr = (t(keep)-tStart)*1e6;

gateNames = {'QA1','QA2','QA3','QA4','QB1','QB2','QB3','QB4','SR1','SR2'};
G = zeros(numel(t),numel(gateNames));
Vds = zeros(numel(t),numel(gateNames));
for k = 1:numel(gateNames)
    G(:,k) = out.(['log_g_' gateNames{k}]).signals.values(:);
    Vds(:,k) = out.(['log_vds_' gateNames{k}]).signals.values(:);
end

stateA = out.log_stateA.signals.values(:);
stateB = out.log_stateB.signals.values(:);
allStates = [G stateA stateB];
idx = find(keep);
changeRows = idx([true; any(diff(allStates(idx,:),1,1)~=0,2)]);
assert(numel(changeRows)==16,'Expected 16 switching events in the selected period.');
eventTimes = [(t(changeRows)-tStart)*1e6; T*1e6];

bounds = [0 eventTimes(7) eventTimes(9) eventTimes(15) T*1e6];
stageColors = [0.94 0.78 0.34; 0.64 0.84 0.95; 0.96 0.61 0.55; 0.70 0.88 0.76];
stageNames = {'I 正向传能','II 零态续流/换相','III 负向传能','IV 零态续流/换相'};

uab = out.log_uab.signals.values(keep);
vsec = out.log_vsec.signals.values(keep);
ipri = out.log_ipri.signals.values(keep);
iaux = out.log_iaux.signals.values(keep);
iLo1 = out.log_ilo1.signals.values(keep);
iLo2 = out.log_ilo2.signals.values(keep);
vout = out.log_vout.signals.values(keep);
vCdc1 = out.log_vtop.signals.values(keep);
vCdc2 = out.log_vbot.signals.values(keep);
measD5 = squeeze(out.log_meas_D5.signals.values);
measD6 = squeeze(out.log_meas_D6.signals.values);
assert(size(measD5,2) >= 2 && size(measD6,2) >= 2, ...
    'D5/D6 measurement vectors must contain current and voltage.');
iD5 = measD5(keep,1);
iD6 = measD6(keep,1);
iLoad = vout/0.75;
iCo = iLo1+iLo2-iLoad;
voutRipple = (vout-mean(vout))*1e3;
vCdc1Ripple = (vCdc1-mean(vCdc1))*1e3;
vCdc2Ripple = (vCdc2-mean(vCdc2))*1e3;

fig = figure('Visible','off','Color','w','Units','pixels', ...
    'Position',[30 15 1780 2300]);
configure_portable_plot_font(fig);
tiledlayout(fig,11,1,'TileSpacing','compact','Padding','compact');
ax = gobjects(11,1);

ax(1) = nexttile;
plotGates(ax(1),tr,G(keep,1:4),gateNames(1:4),'A桥臂门极');

ax(2) = nexttile;
plotGates(ax(2),tr,G(keep,5:8),gateNames(5:8),'B桥臂门极');

ax(3) = nexttile;
yyaxis(ax(3),'left');
plot(ax(3),tr,uab,'k','LineWidth',1.15,'DisplayName','u_{AB}');
ylabel(ax(3),'u_{AB} (V)');
yyaxis(ax(3),'right');
plot(ax(3),tr,vsec,'Color',[0.48 0.16 0.63],'LineWidth',1.1,'DisplayName','v_{sec}');
ylabel(ax(3),'v_{sec} (V)');
title(ax(3),'原边五电平电压与副边电压');
legend(ax(3),'Location','northeast','NumColumns',2);
grid(ax(3),'on');

ax(4) = nexttile;
hold(ax(4),'on');
for k = 1:4
    plot(ax(4),tr,Vds(keep,k),'LineWidth',1.0,'DisplayName',['Vds-' gateNames{k}]);
end
ylabel(ax(4),'Vds (V)');
title(ax(4),'A桥臂四只MOSFET漏源电压');
legend(ax(4),'Location','northeast','NumColumns',4);
grid(ax(4),'on');

ax(5) = nexttile;
hold(ax(5),'on');
for k = 5:8
    plot(ax(5),tr,Vds(keep,k),'LineWidth',1.0,'DisplayName',['Vds-' gateNames{k}]);
end
ylabel(ax(5),'Vds (V)');
title(ax(5),'B桥臂四只MOSFET漏源电压');
legend(ax(5),'Location','northeast','NumColumns',4);
grid(ax(5),'on');

ax(6) = nexttile;
yyaxis(ax(6),'left');
stairs(ax(6),tr,G(keep,9),'LineWidth',1.25,'DisplayName','gSR1');
hold(ax(6),'on');
stairs(ax(6),tr,G(keep,10)+1.4,'LineWidth',1.25,'DisplayName','gSR2');
yticks(ax(6),[0.5 1.9]);
yticklabels(ax(6),{'SR1','SR2'});
ylim(ax(6),[-0.15 2.55]);
ylabel(ax(6),'门极');
yyaxis(ax(6),'right');
plot(ax(6),tr,iD5,'LineWidth',1.05,'DisplayName','iD5');
plot(ax(6),tr,iD6,'LineWidth',1.05,'DisplayName','iD6');
yline(ax(6),0,':','Color',[0.3 0.3 0.3],'HandleVisibility','off');
ylabel(ax(6),'二极管电流 (A)');
title(ax(6),'同步整流门极与D5/D6实测换相电流');
legend(ax(6),'Location','northeast','NumColumns',4);
grid(ax(6),'on');

ax(7) = nexttile;
plot(ax(7),tr,Vds(keep,9),'LineWidth',1.15,'DisplayName','Vds-SR1');
hold(ax(7),'on');
plot(ax(7),tr,Vds(keep,10),'LineWidth',1.15,'DisplayName','Vds-SR2');
yline(ax(7),0,'k:','HandleVisibility','off');
ylabel(ax(7),'Vds (V)');
title(ax(7),'SR1/SR2漏源电压：与上一行门极直接对照');
legend(ax(7),'Location','northeast','NumColumns',2);
grid(ax(7),'on');

ax(8) = nexttile;
plot(ax(8),tr,ipri,'LineWidth',1.15,'DisplayName','i_p');
hold(ax(8),'on');
plot(ax(8),tr,iaux,'LineWidth',1.15,'DisplayName','i_{aux}');
yline(ax(8),0,'k:','HandleVisibility','off');
ylabel(ax(8),'电流 (A)');
title(ax(8),'变压器原边电流与辅助LC换流电流');
legend(ax(8),'Location','northeast','NumColumns',2);
grid(ax(8),'on');

ax(9) = nexttile;
plot(ax(9),tr,iLo1,'LineWidth',1.15,'DisplayName','i_{Lo1}');
hold(ax(9),'on');
plot(ax(9),tr,iLo2,'LineWidth',1.15,'DisplayName','i_{Lo2}');
plot(ax(9),tr,iLoad,'k','LineWidth',1.1,'DisplayName','i_{load}=Vout/R');
ylabel(ax(9),'电流 (A)');
title(ax(9),'两只输出电感与负载电流');
legend(ax(9),'Location','northeast','NumColumns',3);
grid(ax(9),'on');

ax(10) = nexttile;
yyaxis(ax(10),'left');
plot(ax(10),tr,iCo,'Color',[0.10 0.50 0.36],'LineWidth',1.2,'DisplayName','i_{Co}');
yline(ax(10),0,':','Color',[0.25 0.25 0.25],'HandleVisibility','off');
ylabel(ax(10),'i_{Co} (A)');
yyaxis(ax(10),'right');
plot(ax(10),tr,voutRipple,'Color',[0.82 0.24 0.17],'LineWidth',1.15,'DisplayName','Vout纹波');
ylabel(ax(10),'Vout纹波 (mV)');
title(ax(10),'输出电容电流与输出电压纹波');
legend(ax(10),'Location','northeast','NumColumns',2);
grid(ax(10),'on');

ax(11) = nexttile;
plot(ax(11),tr,vCdc1Ripple,'LineWidth',1.15,'DisplayName','Cdc1电压交流分量');
hold(ax(11),'on');
plot(ax(11),tr,vCdc2Ripple,'LineWidth',1.15,'DisplayName','Cdc2电压交流分量');
yline(ax(11),0,'k:','HandleVisibility','off');
ylabel(ax(11),'电压 (mV)');
xlabel(ax(11),'相对周期起点时间 (us)');
title(ax(11),sprintf('母线分压电容电压纹波（均值 %.3f V / %.3f V）',mean(vCdc1),mean(vCdc2)));
legend(ax(11),'Location','northeast','NumColumns',2);
grid(ax(11),'on');

for k = 1:numel(ax)
    xlim(ax(k),[0 T*1e6]);
    shadeStages(ax(k),bounds,stageColors);
    addEventLines(ax(k),eventTimes);
end
linkaxes(ax,'x');

% Shared event and stage labels on the first row.
yl = ylim(ax(1));
for k = 1:numel(eventTimes)
    x = min(max(eventTimes(k),0.015),T*1e6-0.015);
    y = yl(2)-(0.035+0.13*mod(k-1,2))*(yl(2)-yl(1));
    if k == 1
        ha = 'left';
    elseif k == numel(eventTimes)
        ha = 'right';
    else
        ha = 'center';
    end
    text(ax(1),x,y,sprintf('t%d',k-1),'FontSize',8, ...
        'Color',[0.25 0.25 0.25],'HorizontalAlignment',ha,'VerticalAlignment','top');
end
for k = 1:4
    text(ax(1),mean(bounds(k:k+1)),yl(1)+0.04*(yl(2)-yl(1)),stageNames{k}, ...
        'FontSize',8.5,'FontWeight','bold','HorizontalAlignment','center', ...
        'VerticalAlignment','bottom','Color',[0.12 0.18 0.24]);
end

sgtitle(fig,'740 V稳态单周期扩展元件波形（全部与t0-t16时间轴对齐）', ...
    'FontSize',16,'FontWeight','bold');

name = '07_740V单周期扩展元件波形_t0-t16.png';
plotFile = fullfile(plotDir,name);
exportgraphics(fig,plotFile,'Resolution',400);
close(fig);

stage = ones(sum(keep),1);
stage(tr >= bounds(2)) = 2;
stage(tr >= bounds(3)) = 3;
stage(tr >= bounds(4)) = 4;
tbl = table(tr,stage,uab,vsec, ...
    Vds(keep,1),Vds(keep,2),Vds(keep,3),Vds(keep,4), ...
    Vds(keep,5),Vds(keep,6),Vds(keep,7),Vds(keep,8), ...
    G(keep,9),G(keep,10),Vds(keep,9),Vds(keep,10), ...
    iD5,iD6, ...
    ipri,iaux,iLo1,iLo2,iLoad,iCo,voutRipple,vCdc1Ripple,vCdc2Ripple, ...
    'VariableNames',{'time_us','stage','uAB_V','vsec_V', ...
    'vds_QA1_V','vds_QA2_V','vds_QA3_V','vds_QA4_V', ...
    'vds_QB1_V','vds_QB2_V','vds_QB3_V','vds_QB4_V', ...
    'gSR1','gSR2','vds_SR1_V','vds_SR2_V', ...
    'iD5_A','iD6_A', ...
    'ipri_A','iaux_A','iLo1_A','iLo2_A','iLoad_A','iCo_A', ...
    'voutRipple_mV','vCdc1Ripple_mV','vCdc2Ripple_mV'});
writetable(tbl,fullfile(resultDir,'extended_one_cycle_740V.csv'));
fprintf('EXTENDED_COMPONENT_FIGURE=%s\n',plotFile);
end

function plotGates(ax,t,G,names,titleText)
hold(ax,'on');
offset = 1.35;
for k = 1:numel(names)
    stairs(ax,t,G(:,k)+(k-1)*offset,'LineWidth',1.1,'DisplayName',names{k});
end
yticks(ax,(0:numel(names)-1)*offset+0.5);
yticklabels(ax,names);
ylim(ax,[-0.15 (numel(names)-1)*offset+1.15]);
ylabel(ax,'门极');
title(ax,titleText);
grid(ax,'on');
end

function shadeStages(ax,bounds,colors)
yl = ylim(ax);
for k = 1:4
    p = patch(ax,[bounds(k) bounds(k+1) bounds(k+1) bounds(k)], ...
        [yl(1) yl(1) yl(2) yl(2)],colors(k,:), ...
        'FaceAlpha',0.065,'EdgeColor','none','HandleVisibility','off');
    p.PickableParts = 'none';
end
ylim(ax,yl);
end

function addEventLines(ax,eventTimes)
for k = 1:numel(eventTimes)
    xline(ax,eventTimes(k),':','Color',[0.74 0.74 0.74], ...
        'LineWidth',0.5,'HandleVisibility','off');
end
end
