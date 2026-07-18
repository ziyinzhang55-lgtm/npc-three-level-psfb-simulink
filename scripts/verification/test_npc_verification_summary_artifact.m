function test_npc_verification_summary_artifact()
% Regression coverage for the summary artifact consumed by final plots.

source = fileread(which('run_npc_tl_psfb_verification'));
assert(contains(source,'write_npc_verification_summary(summary);'), ...
    'Artifact-producing verification must write the completed summary table.');
tempDir = tempname;
mkdir(tempDir);
cleanup = onCleanup(@()removeTempDir(tempDir));
summaryFile = fullfile(tempDir,'summary.csv');

summary = table([350; 740; 1000],[15.01; 15.00; 14.99], ...
    [10; 12; 14],[300.4; 300.0; 299.6],[0.18; 0.12; 0.09], ...
    [0.36; 0.35; 0.34],[0.2; 0.1; 0.2],[382; 382; 382], ...
    'VariableNames',{'Vin_V','VoutAvg_V','Ripple_mVpp','Pout_W', ...
    'PhaseShift','DeqMeasured','CapMismatch_V','MaxMainVds_V'});

writtenFile = write_npc_verification_summary(summary,summaryFile);
assert(strcmp(writtenFile,summaryFile));
assert(isfile(summaryFile),'Artifact-producing verification did not write summary.csv.');

actual = readtable(summaryFile);
assert(isequal(actual.Properties.VariableNames,summary.Properties.VariableNames));
assert(isequaln(table2array(actual),table2array(summary)));

fprintf('PASS: verification summary artifact preserves all columns and values.\n');
end

function removeTempDir(dirPath)
if exist(dirPath,'dir'), rmdir(dirPath,'s'); end
end
