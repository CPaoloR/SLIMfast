classdef ContainerRoi < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        FocusRoi = false
        HighlightRoi = true
        CropRoi = true
    end %properties    
    properties (Hidden)
        Shape = 'Rectangle';        
        RoiList   
    end %properties
    properties (Transient,Hidden)
        ProfileStartMarker = '[START Roi]'
        ProfileEndMarker = '[END Roi]'
    end %properties
    
    methods
        %constructor
        function this = ContainerRoi(parent)
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
            this = ContainerRoi;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef