classdef ContainerImageFile < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    methods
        %constructor
        function obj = ContainerImageFile(parent)
            if nargin == 0
                parent = [];
            end %if
            obj = obj@SuperclassContainer(parent);
        end %fun
        
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassContainer(this);
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ContainerImageFile;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
