function test_run_all_case_filename()
% Regression coverage for run_all's selected-duration rated-case artifact.

paths = project_paths();
source = fileread(which('run_all'));
assert(contains(source,'npc_case_filename(paths.results,740,stopTime)'), ...
    'run_all must derive the rated-case artifact from its stopTime input.');

assert(strcmp(npc_case_filename(paths.results,740,12e-3), ...
    fullfile(paths.results,'case_0740V_12ms.mat')));
assert(strcmp(npc_case_filename(paths.results,740,8e-3), ...
    fullfile(paths.results,'case_0740V_8ms.mat')));

fprintf('PASS: run_all rated-case filenames follow stopTime at 12 ms and 8 ms.\n');
end
