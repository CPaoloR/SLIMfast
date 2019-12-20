function coordinates = set_figure_position(ratio, factor, position)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

scrSize = get(0, 'ScreenSize');
scrRatio = scrSize(3)/scrSize(4);

if  ratio == scrRatio 
    figWidth = factor*scrSize(3);
    figHeight = factor*scrSize(4);
else %height limited
    figWidth = factor*scrSize(3)*ratio/scrRatio;
    figHeight = factor*scrSize(4);
    if figWidth > scrSize(3) %width limited
        figWidth = factor*scrSize(3);
        figHeight = factor*scrSize(4)/ratio*scrRatio;
    end %if
end %if

switch position
    case 'north-west'
        coordinates = [1 scrSize(4)-figHeight figWidth figHeight];
    case 'north-east'
        coordinates = [scrSize(3)-figWidth scrSize(4)-figHeight figWidth figHeight];
    case 'south-east'
        coordinates = [scrSize(3)-figWidth 1 figWidth figHeight];
    case 'south-west'
        coordinates = [1 1 figWidth figHeight];
    case 'center'
        coordinates = [0.5*(scrSize(3)-figWidth) 0.5*(scrSize(4)-figHeight) figWidth figHeight];
end %switch
end %fun
