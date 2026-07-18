function summary = run_load_efficiency_sweep(stopTime)
% Verify 740 V regulation across required loads and estimate system efficiency.

if nargin < 1, stopTime = 8e-3; end
paths = project_paths();
modelFile = paths.model;
resultDir = paths.results;
model = 'npc_tl_psfb_cdr_final';
load_system(modelFile);

vin = 740;
pTargets = [20 25 50 70 150 300]';
requiredEta = [92 93 92 92 91 NaN]';
summary = table('Size',[numel(pTargets) 11], ...
    'VariableTypes',repmat({'double'},1,11), ...
    'VariableNames',{'Ptarget_W','Rload_ohm','VoutAvg_V','Ripple_mVpp', ...
    'PinPowerStage_W','Pout_W','EtaPowerStage_pct','AuxOverhead_W', ...
    'EtaSystemEst_pct','RequiredEta_pct','Pass'});

set_param([model '/Vdc_input'],'Amplitude',num2str(vin));
set_param([model '/Co_4700uF'],'Setx0','on','InitialVoltage','15');
set_param(model,'StopTime',num2str(stopTime,'%.12g'),'ReturnWorkspaceOutputs','on');
for k = 1:numel(pTargets)
    pTarget = pTargets(k);
    rload = 15^2/pTarget;
    set_param([model '/Rload_0p75ohm'],'Resistance',num2str(rload,'%.12g'));
    out = sim(model);

    t = out.log_vout.time(:);
    vout = out.log_vout.signals.values(:);
    iin = out.log_iin.signals.values(:);
    keep = t >= max(0,stopTime-0.8e-3);
    vavg = mean(vout(keep));
    ripple = max(vout(keep))-min(vout(keep));
    pin = vin*mean(iin(keep));
    pout = mean(vout(keep).^2/rload);
    etaStage = 100*pout/pin;

    % Gate-drive/control power is not represented by Specialized Power
    % Systems. Light-load points assume burst operation and disabled idle
    % gate drivers; higher loads use continuous 150 kHz operation.
    qgPrimary = 43e-9;
    qgSecondary = 73e-9;
    gateDynamic = 8*qgPrimary*18*150e3 + 2*qgSecondary*10*150e3;
    if pTarget <= 70
        burstRatio = max(0.16,pTarget/70);
    else
        burstRatio = 1;
    end
    overhead = 0.25 + burstRatio*gateDynamic;
    etaSystem = 100*pout/(pin+overhead);
    pass = isnan(requiredEta(k)) || etaSystem >= requiredEta(k);

    summary{k,:} = [pTarget rload vavg ripple*1e3 pin pout etaStage ...
        overhead etaSystem requiredEta(k) double(pass)];
    fprintf(['P=%g W R=%.4f ohm Vout=%.5f V ripple=%.3f mV ' ...
        'etaStage=%.3f%% etaSystemEst=%.3f%%\n'],pTarget,rload,vavg, ...
        ripple*1e3,etaStage,etaSystem);
    assert(vavg >= 14.55 && vavg <= 15.45,'Load regulation failed at %g W.',pTarget);
    assert(ripple <= 50e-3,'Ripple failed at %g W.',pTarget);
end

writetable(summary,fullfile(resultDir,'load_efficiency_740V.csv'));
disp(summary);
set_param([model '/Co_4700uF'],'Setx0','off','InitialVoltage','0');
close_system(model,0);
end
