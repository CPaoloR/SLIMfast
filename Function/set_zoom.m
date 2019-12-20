function set_zoom(src,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%input validation
objInputParser = inputParser;
addParamValue(objInputParser,...
    'hFig', gcf, @(x)ishandle(x));
addParamValue(objInputParser,...
    'Direction', 'both', @(x)ischar(x));
addParamValue(objInputParser,...
    'RightClickAction', 'InverseZoom', @(x)ischar(x));
parse(objInputParser,varargin{:});
inputs = objInputParser.Results;

hZoom = zoom(inputs.hFig);

switch get(src,'State')
    case 'on'
        set(findobj(get(src,'Parent'),...
            'Tag','Pan','-or','Tag','Rotate'),...
            'State','off')
        set(hZoom,...
            'Enable','on',...
            'Motion', inputs.Direction,...
            'RightClickAction', inputs.RightClickAction)
    case 'off'
        set(hZoom,...
            'Enable','off')
end %fun