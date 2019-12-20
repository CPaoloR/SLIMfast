classdef ContainerLineProfile < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        NumSegments = 5
        LineInterval = 20 %[nm]
        LateralInterval = 5 %[nm]
        NumLateralPnts = 5
        
        AvDirection = 'Orthogonal';
        InterpType = 'Linear'
        Weighting = 'Mean'
        SigmaWeight = 10 %[nm]
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START LineProfile]'
        ProfileEndMarker = '[END LineProfile]'
    end %properties
    
    methods
        %constructor
        function this = ContainerLineProfile(parent)
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
            this = ContainerLineProfile;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
