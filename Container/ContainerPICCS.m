classdef ContainerPICCS < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        FrameStart = 1
        FrameEnd = 1
        CorrStart = 10 %[nm]
        CorrEnd = 300 %[nm]
        CorrSamples = 30
        SamplingMode = 'Linear'
    end %properties
    properties (Hidden)
        ProfileStartMarker = '[START PiccsSettings]'
        ProfileEndMarker = '[END PiccsSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerPICCS(parent)
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
            this = ContainerPICCS;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef