function boxPos = get_screen_box_position
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

scrSize = get(0,'ScreenSize');

if scrSize(3) > scrSize(4) %wide-screen
    x0 = (scrSize(3)-scrSize(4))/2;
    y0 = 1;
    boxSize = scrSize(4);
    boxPos = [x0 y0 boxSize boxSize];
elseif scrSize(3) < scrSize(4) 
    x0 = 1;
    y0 = (scrSize(4)-scrSize(3))/2;
    boxSize = scrSize(3);
    boxPos = [x0 y0 boxSize boxSize];
else %quadratic screen
    boxPos = scrSize;
end %if
end %fun