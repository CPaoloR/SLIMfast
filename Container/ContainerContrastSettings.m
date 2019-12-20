classdef ContainerContrastSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        LowSat = 50
        HighSat = 0.5
        FixedSat = true
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START ContrastSettings]'
        ProfileEndMarker = '[END ContrastSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerContrastSettings(parent)
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
            this = ContainerContrastSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
