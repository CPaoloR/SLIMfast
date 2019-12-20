classdef ContainerUnitConvFac < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Px2nm = 107 %[nm]
        Frame2msec = 32 %[ms]
        Count2photon = 0.05 %[photon]
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START UnitConvFac]'
        ProfileEndMarker = '[END UnitConvFac]'
    end %properties
    
    methods
        %constructor
        function this = ContainerUnitConvFac(parent)
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
            this = ContainerUnitConvFac;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
