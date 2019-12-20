classdef ContainerCoLocSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        UseFixedDist = false
        DistThresh = 50 %[nm]
        ProbMiss = -3 %[10^]
        InterMolDist = 0 %[nm]
        CoLocMode = 'inclusive'
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START CoLocSettings]'
        ProfileEndMarker = '[END CoLocSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerCoLocSettings(parent)
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
            this = ContainerCoLocSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef