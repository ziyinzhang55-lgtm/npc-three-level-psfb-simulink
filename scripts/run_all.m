function summary = run_all(stopTime)
if nargin < 1, stopTime = 12e-3; end
paths = project_paths();
addpath(genpath(fullfile(paths.root,'scripts')));
summary = run_npc_tl_psfb_verification(stopTime,true);
verify_npc_soft_switching(npc_case_filename(paths.results,740,stopTime));
generate_final_npc_plots(stopTime);
generate_extended_component_waveforms(stopTime);
fprintf('Results: %s\nFigures: %s\n',paths.results,paths.figures);
end
