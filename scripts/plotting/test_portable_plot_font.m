function test_portable_plot_font()
% Regression coverage for non-interactive, figure-local font selection.

rootAxesFont = get(groot,'defaultAxesFontName');
rootTextFont = get(groot,'defaultTextFontName');
fig = figure('Visible','off');
cleanup = onCleanup(@()closeIfValid(fig));
axesDefaultBefore = get(fig,'DefaultAxesFontName');
textDefaultBefore = get(fig,'DefaultTextFontName');

configure_portable_plot_font(fig);
fontName = preferred_plot_font();
if isempty(fontName)
    assert(isequal(get(fig,'DefaultAxesFontName'),axesDefaultBefore));
    assert(isequal(get(fig,'DefaultTextFontName'),textDefaultBefore));
else
    assert(strcmp(get(fig,'DefaultAxesFontName'),fontName));
    assert(strcmp(get(fig,'DefaultTextFontName'),fontName));
    ax = axes(fig);
    titleHandle = title(ax,'font probe');
    assert(strcmp(get(ax,'FontName'),fontName));
    assert(strcmp(get(titleHandle,'FontName'),fontName));
end

assert(isequal(get(groot,'defaultAxesFontName'),rootAxesFont));
assert(isequal(get(groot,'defaultTextFontName'),rootTextFont));
fprintf('PASS: figure-local font configuration leaves groot defaults unchanged.\n');
end

function closeIfValid(fig)
if isgraphics(fig), close(fig); end
end
