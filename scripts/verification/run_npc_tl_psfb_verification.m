function summary = run_npc_tl_psfb_verification(stopTime,saveArtifacts)
% Sweep the final physical model across the required input-voltage range.

if nargin < 1, stopTime = 8e-3; end
if nargin < 2, saveArtifacts = false; end

[modelFile,model] = build_npc_tl_psfb_cdr_final();
load_system(modelFile);
vinCases = [350 740 1000];
summary = table('Size',[numel(vinCases) 8], ...
    'VariableTypes',repmat({'double'},1,8), ...
    'VariableNames',{'Vin_V','VoutAvg_V','Ripple_mVpp','Pout_W', ...
    'PhaseShift','DeqMeasured','CapMismatch_V','MaxMainVds_V'});

for k = 1:numel(vinCases)
    vin = vinCases(k);
    set_param([model '/Vdc_input'],'Amplitude',num2str(vin));
    set_param(model,'StopTime',num2str(stopTime,'%.12g'),'ReturnWorkspaceOutputs','on');
    out = sim(model);

    [t,vout] = unpack(out.log_vout);
    [~,phi] = unpack(out.log_phase);
    [~,uab] = unpack(out.log_uab);
    [~,vtop] = unpack(out.log_vtop);
    [~,vbot] = unpack(out.log_vbot);
    keep = t >= max(0,stopTime-0.8e-3);

    vavg = mean(vout(keep));
    ripple = max(vout(keep))-min(vout(keep));
    deq = mean(abs(uab(keep)))/vin;
    capMismatch = abs(mean(vtop(keep))-mean(vbot(keep)));
    maxVds = 0;
    names = {'QA1','QA2','QA3','QA4','QB1','QB2','QB3','QB4'};
    for n = 1:numel(names)
        [tv,vds] = unpack(out.(['log_vds_' names{n}]));
        maxVds = max(maxVds,max(abs(vds(tv >= max(0,stopTime-0.8e-3)))));
    end

    summary{k,:} = [vin vavg ripple*1e3 vavg^2/0.75 mean(phi(keep)) ...
        deq capMismatch maxVds];

    fprintf(['Vin=%4g V: Vout=%.6f V, ripple=%.3f mVpp, phase=%.6f, ' ...
        'Deq=%.6f, max|Vds|=%.3f V\n'],vin,vavg,ripple*1e3, ...
        mean(phi(keep)),deq,maxVds);

    assert(vavg >= 14.55 && vavg <= 15.45, ...
        'Output regulation failed at Vin=%g V.',vin);
    assert(ripple <= 50e-3, ...
        'Output ripple exceeds 50 mVpp at Vin=%g V.',vin);
    assert(capMismatch <= max(8,0.02*vin), ...
        'Split-link balance failed at Vin=%g V.',vin);
    stressLimit = min(0.8*vin+15,650);
    assert(maxVds <= stressLimit, ...
        'A main switch exceeds the dynamic clamp envelope at Vin=%g V.',vin);

    if saveArtifacts
        saveCase(out,vin,stopTime);
    end
end

if saveArtifacts
    write_npc_verification_summary(summary);
end

disp(summary);
close_system(model,0);
end

function saveCase(out,vin,stopTime)
paths = project_paths();
save(npc_case_filename(paths.results,vin,stopTime), ...
    'out','vin','stopTime','-v7.3');
end

function [t,y] = unpack(s)
t = s.time(:);
y = squeeze(s.signals.values);
y = y(:);
end
