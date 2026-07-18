function paths = project_paths()
scriptsDir = fileparts(mfilename('fullpath'));
paths.root = fileparts(scriptsDir);
paths.model = fullfile(paths.root,'model','npc_tl_psfb_cdr_final.slx');
paths.results = fullfile(paths.root,'results','generated');
paths.figures = fullfile(paths.root,'figures','generated');
if ~exist(paths.results,'dir'), mkdir(paths.results); end
if ~exist(paths.figures,'dir'), mkdir(paths.figures); end
end
