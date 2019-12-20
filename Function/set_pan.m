function set_pan(src,varargin)
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
parse(objInputParser,varargin{:});
inputs = objInputParser.Results;

hPan = pan(inputs.hFig);

switch get(src,'State')
    case 'on'
        set(findobj(get(src,'Parent'),...
            'Tag','Zoom','-or','Tag','Rotate'),...
            'State','off')
        set(hPan,...
            'Enable','on',...
            'Motion', inputs.Direction,...
            'UIContextMenu',[])
    case 'off'
        set(hPan,...
            'Enable','off')
end %fun