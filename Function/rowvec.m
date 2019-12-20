function x = rowvec(x)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 19.11.2015

if isvector(x)
    if iscolumn(x)
        x = reshape(x,1,numel(x));
    end
end %if
end %fun