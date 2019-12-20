function subS = get_cross_field_value(S,i)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 13.11.2014

fn = fieldnames(S);

for idxField = 1:numel(fn)
    subS.(fn{idxField}) = S.(fn{idxField})(i);
end %for
end %fun