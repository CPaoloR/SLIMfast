function classObj = struct2class(S,classObj)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

classInfo = metaclass(classObj);
classProp = classInfo.PropertyList;

take = not([classProp.Dependent] | [classProp.Transient]);
classPropNames = {classProp(take).Name};

loadedPropNames = fieldnames(S);
for idxProp = 1:numel(loadedPropNames)
    %check if the loaded property exists in the class
    if any(strcmp(loadedPropNames{idxProp},classPropNames))
        classObj.(loadedPropNames{idxProp}) = ...
            S.(loadedPropNames{idxProp});
    end %if
end %for
end %fun