function [objCandidate, isOK] = get_parental_object(this,objClass)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

isOK = true;
objCandidate = this.Parent;
while not(any(strcmp(class(objCandidate),objClass)))
    %get parental object 
    objCandidate = objCandidate.Parent;
    if strcmp(class(objCandidate),'SLIMfast')
        %highest object level reached
        if ~strcmp(objClass,'SLIMfast')
            %desired parental object not found
            isOK = false;
            objCandidate = [];
        end %if
        break
    elseif isempty(objCandidate)
        %hierarchy broken
        isOK = false;
        objCandidate = [];
        break
    end %if
end %while
end %fun