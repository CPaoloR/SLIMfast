function set_rotate(src,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%input validation
objInputParser = inputParser;
addParamValue(objInputParser,...
    'hAx', gca, @(x)ishandle(x));
addParamValue(objInputParser,...
    'Dim', 3, @(x)isinteger(x));
addParamValue(objInputParser,...
    'RotateStyle', 'orbit', @(x)ischar(x));
parse(objInputParser,varargin{:});
inputs = objInputParser.Results;

switch inputs.Dim
    case 2
    case 3
        hRot = rotate3d(inputs.hAx);
end %switch

switch get(src,'State')
    case 'on'
        set(findobj(get(src,'Parent'),...
            'Tag','Pan','-or','Tag','Zoom'),...
            'State','off')
        set(hRot,...
            'Enable','on',...
            'RotateStyle', inputs.RotateStyle)
    case 'off'
        set(hRot,...
            'Enable','off')
end %fun