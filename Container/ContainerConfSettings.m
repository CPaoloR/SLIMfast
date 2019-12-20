classdef ContainerConfSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        ExpDiffCoeff = 0.1; %[µm^2 s^-1]
        ConfAlgorithm = 'Meilhac et al.'
        TimeWindow = 11; %[frames]
        ConfThresh = 4; 
        MinConfTime = 7; %[frames]
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START ConfSettings]'
        ProfileEndMarker = '[END ConfSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerConfSettings(parent)
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
            this = ContainerConfSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
