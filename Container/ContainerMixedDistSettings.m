classdef ContainerMixedDistSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        NumMix = 2 %final model complexity
        
        UseInfoCrit = true %use model evaluation
        MaxMix = 4 %max model complexity
        Replicates = 5 %start value permutations -> global optimization
        UseCorrMean = false
        MaxIter = 300
        TolFun = -6 %[10^]
        
        IsTruncated = false
        LeftTrunc = -inf
        RightTrunc = inf
                
        Alpha = 0.95 %selection significance
        
        Display = 'off'
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START MixedDistSettings]'
        ProfileEndMarker = '[END MixedDistSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerMixedDistSettings(parent)
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
            this = ContainerMixedDistSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
