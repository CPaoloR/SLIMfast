classdef ContainerMsdCurveFit < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        CutOffMode = 'Relative'
        FitStart = 1 %[%]
        FitEnd = 33 %[%]
        DiffModel = 'Free Diffusion'
        MaxIter = 300
        TolFun = -6 %[10^]
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START MsdCurveFit]'
        ProfileEndMarker = '[END MsdCurveFit]'
    end %properties
    
    methods
        %constructor
        function this = ContainerMsdCurveFit(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassContainer(parent);
        end %fun
        
         function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassContainer(this);
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ContainerMsdCurveFit;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef