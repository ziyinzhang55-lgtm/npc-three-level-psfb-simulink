function metrics = verify_npc_bridge_stage()
% Verify the final model's bridge states, flux balance, and switch stress.

[modelFile,model] = build_npc_tl_psfb_cdr_final();
load_system(modelFile);
set_param(model,'StopTime','8e-3','ReturnWorkspaceOutputs','on');
out = sim(model);

[t,~] = unpack(out.log_uab);
[~,uab] = unpack(out.log_uab);
[~,vtop] = unpack(out.log_vtop);
[~,vbot] = unpack(out.log_vbot);
[~,stateA] = unpack(out.log_stateA);
[~,stateB] = unpack(out.log_stateB);

vao = zeros(size(stateA));
vao(stateA > 0.5) = vtop(stateA > 0.5);
vao(stateA < -0.5) = -vbot(stateA < -0.5);
vbo = zeros(size(stateB));
vbo(stateB > 0.5) = vtop(stateB > 0.5);
vbo(stateB < -0.5) = -vbot(stateB < -0.5);

keep = t >= 7e-3;
metrics.vaP = median(vao(keep & stateA > 0.5));
metrics.vaO = median(vao(keep & abs(stateA) < 0.5));
metrics.vaN = median(vao(keep & stateA < -0.5));
metrics.vbP = median(vbo(keep & stateB > 0.5));
metrics.vbO = median(vbo(keep & abs(stateB) < 0.5));
metrics.vbN = median(vbo(keep & stateB < -0.5));
metrics.uabMean = mean(uab(keep));
metrics.capMismatch = abs(mean(vtop(keep))-mean(vbot(keep)));

assert(abs(metrics.vaP-370) < 18, 'Leg A P level is not +Vin/2.');
assert(abs(metrics.vaO) < 18, 'Leg A O level is not neutral clamped.');
assert(abs(metrics.vaN+370) < 18, 'Leg A N level is not -Vin/2.');
assert(abs(metrics.vbP-370) < 18, 'Leg B P level is not +Vin/2.');
assert(abs(metrics.vbO) < 18, 'Leg B O level is not neutral clamped.');
assert(abs(metrics.vbN+370) < 18, 'Leg B N level is not -Vin/2.');
assert(abs(metrics.uabMean) < 5, 'Bridge output contains excessive DC voltage.');
assert(metrics.capMismatch < 8, 'Split DC-link capacitor voltage is unbalanced.');

names = {'QA1','QA2','QA3','QA4','QB1','QB2','QB3','QB4'};
metrics.maxAbsVds = zeros(1,numel(names));
for k = 1:numel(names)
    sig = out.(['log_vds_' names{k}]);
    [tv,vds] = unpack(sig);
    metrics.maxAbsVds(k) = max(abs(vds(tv >= 7e-3)));
end
assert(all(metrics.maxAbsVds < 460), ...
    'At least one main device is exposed to substantially more than Vin/2.');

fprintf(['PASS: physical NPC bridge; VA=[%.2f %.2f %.2f] V, ' ...
    'VB=[%.2f %.2f %.2f] V, mean(uAB)=%.3f V, max|Vds|=%.2f V\n'], ...
    metrics.vaP,metrics.vaO,metrics.vaN,metrics.vbP,metrics.vbO,metrics.vbN, ...
    metrics.uabMean,max(metrics.maxAbsVds));
bdclose(model);
end

function [t,y] = unpack(s)
t = s.time(:);
y = squeeze(s.signals.values);
y = y(:);
end
