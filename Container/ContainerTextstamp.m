classdef ContainerTextstamp < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        String = 'SLIMfast, AG Piehler, University Osnabrück'
        FontSize = 18
        Position = 'South-West'
        Color = [1 1 1] %white
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START Textstamp]'
        ProfileEndMarker = '[END Textstamp]'
    end %properties
    
    methods
        %constructor
        function this = ContainerTextstamp(parent)
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
            this = ContainerTextstamp;
            this = loadobj@SuperclassContainer(this,S);
        end %fun    
    end %methods
end %classdef