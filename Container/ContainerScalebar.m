classdef ContainerScalebar < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Scale = 1
        Unit = 'µm'
        FontSize = 36
        BarSize = 4
        Position = 'North-East'
        UseLabel = true
        Color = [1 1 1] %white
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START Scalebar]'
        ProfileEndMarker = '[END Scalebar]'
    end %properties
    
    methods
        %constructor
        function this = ContainerScalebar(parent)
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
            this = ContainerScalebar;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef