classdef ContainerGrid < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        UseGrid = false
        GridMode = 'Uniform Hexagonal'
        GridLineColor = [0 1 0] %green
        GridLineWidth = 1
        GridRectWidth = 1
        GridRectHeight = 1
        GridHexArea = 1 %[µm^2]
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START GridSettings]'
        ProfileEndMarker = '[END GridSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerGrid(parent)
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
            this = ContainerGrid;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
