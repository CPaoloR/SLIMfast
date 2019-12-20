function [y y0] = add_parameter_to_manager(hFig,y,y0,yNew)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

y0 = y0 + yNew;
y = y + yNew;

scrSize = get(0, 'ScreenSize');
set(hFig,'Position', ...
    [0.5*(scrSize(3)-225) ...
    0.5*(scrSize(4)-y0) 225 y0])

hList = allchild(hFig);
set(hList,{'Position'},...
    cellfun(@(x) x+[0 yNew 0 0], ...
    get(hList,'Position'),'Un',0))
end %fun