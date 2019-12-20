function S = class2struct(classObj)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

classInfo = metaclass(classObj);
classProp = classInfo.PropertyList;

take = not([classProp.Dependent] | [classProp.Transient]);
classPropNames = {classProp(take).Name};

for idxProp = 1:numel(classPropNames)
    S.(classPropNames{idxProp}) = ...
        classObj.(classPropNames{idxProp});
end %for
end %fun