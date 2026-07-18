function configure_portable_plot_font(fig)
fontName = preferred_plot_font();
if isempty(fontName), return; end
set(fig,'DefaultAxesFontName',fontName);
set(fig,'DefaultTextFontName',fontName);
end
