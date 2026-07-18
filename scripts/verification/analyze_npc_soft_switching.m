function metrics = analyze_npc_soft_switching(matFile,startTime)
% Measure Vds immediately before every main-switch turn-on edge.

if nargin < 2, startTime = 7e-3; end
s = load(matFile);
if isfield(s,'out')
    out = s.out;
elseif isfield(s,'o')
    out = s.o;
else
    error('MAT file does not contain a SimulationOutput named out or o.');
end

names = {'QA1','QA2','QA3','QA4','QB1','QB2','QB3','QB4'};
t = out.log_ipri.time(:);
ipri = out.log_ipri.signals.values(:);
iaux = out.log_iaux.signals.values(:);
vin = mean(out.log_vin.signals.values(t >= startTime));

device = strings(numel(names),1);
edges = zeros(numel(names),1);
medianVds = zeros(numel(names),1);
worstVds = zeros(numel(names),1);
medianIcomm = zeros(numel(names),1);
classification = strings(numel(names),1);

for k = 1:numel(names)
    device(k) = names{k};
    gate = out.(['log_g_' names{k}]).signals.values(:);
    vds = out.(['log_vds_' names{k}]).signals.values(:);
    rise = find(gate(2:end) >= 0.5 & gate(1:end-1) < 0.5)+1;
    rise = rise(t(rise) >= startTime);
    pre = max(rise-1,1);

    edges(k) = numel(rise);
    medianVds(k) = median(abs(vds(pre)));
    worstVds(k) = max(abs(vds(pre)));
    medianIcomm(k) = median(abs(ipri(pre)+iaux(pre)));

    if medianVds(k) <= max(10,0.02*vin/2) && worstVds(k) <= 0.1*vin/2
        classification(k) = "ZVS";
    else
        classification(k) = "Reduced-voltage hard turn-on";
    end
end

metrics = table(device,edges,medianVds,worstVds,medianIcomm,classification, ...
    'VariableNames',{'Device','TurnOnEdges','MedianVdsBeforeTurnOn_V', ...
    'WorstVdsBeforeTurnOn_V','MedianAbsCommutationCurrent_A','Classification'});
end
