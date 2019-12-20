classdef ContainerColormap < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden)
        Colormapping = gray(256);
        
        ProfileStartMarker = '[START Colormap]'
        ProfileEndMarker = '[END Colormap]'
    end %properties
    methods
        %constructor
        function this = ContainerColormap(parent)
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
            this = ContainerColormap;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
