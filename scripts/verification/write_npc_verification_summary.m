function file = write_npc_verification_summary(summary,outputFile)
if nargin < 2
    paths = project_paths();
    outputFile = fullfile(paths.results,'summary.csv');
end

file = outputFile;
writetable(summary,file);
end
