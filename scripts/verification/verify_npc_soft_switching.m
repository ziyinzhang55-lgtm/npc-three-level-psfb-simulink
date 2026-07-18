function metrics = verify_npc_soft_switching(matFile)
% Verify the soft-switching claims made for the 740 V rated operating point.

if nargin < 1
    paths = project_paths();
    matFile = fullfile(paths.results,'case_0740V_12ms.mat');
end

metrics = analyze_npc_soft_switching(matFile,7e-3);
outer = ismember(metrics.Device,{'QA1','QA4','QB1','QB4'});
inner = ~outer;

assert(all(metrics.MedianVdsBeforeTurnOn_V(outer) < 5), ...
    'At least one outer switch does not achieve nominal-point ZVS.');
assert(all(metrics.WorstVdsBeforeTurnOn_V(outer) < 40), ...
    'An outer switch exceeds the 10%% half-bus near-ZVS envelope.');
assert(all(metrics.MedianVdsBeforeTurnOn_V(inner) > 50), ...
    'The test no longer distinguishes the non-ZVS inner-switch behavior.');
assert(all(metrics.Classification(outer) == "ZVS"), ...
    'Outer-switch classification is inconsistent with measured Vds.');
assert(all(metrics.Classification(inner) == "Reduced-voltage hard turn-on"), ...
    'Inner switches must not be mislabeled as ZVS.');

disp(metrics);
end
