function set_contextmenu_state(src,exclusive)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

if strcmp(get(src, 'Checked'),'on')
    if ~exclusive        
        set(src, 'Checked', 'off')
    end %if
else
    if exclusive
        %check all execpted the selected off
        hList = get(get(src, 'Parent'),'Children');
        set(hList, 'Checked', 'off')
    end %if
    set(src, 'Checked', 'on')
end %if
end %fun