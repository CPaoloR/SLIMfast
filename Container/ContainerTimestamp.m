classdef ContainerTimestamp < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Unit = 's'
        FontSize = 36
        Position = 'North-East'
        Color = [1 1 1] %white
        
        UserIncrement = false
        Increment = 1
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START Timestamp]'
        ProfileEndMarker = '[END Timestamp]'
    end %properties
    
    methods
        %constructor
        function this = ContainerTimestamp(parent)
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
            this = ContainerTimestamp;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef