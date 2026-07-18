function fontName = preferred_plot_font()
fontName = '';
if ~ispc, return; end

fontFile = fullfile(getenv('WINDIR'),'Fonts','msyh.ttc');
if exist(fontFile,'file') == 2
    fontName = 'Microsoft YaHei';
end
end
