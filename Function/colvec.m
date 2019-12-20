function x = colvec(x)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 19.11.2015

if isvector(x)
    if isrow(x)
        x = reshape(x,numel(x),1);
    end
end %if
end %fun