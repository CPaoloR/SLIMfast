classdef ContainerClusterSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        SigSpat = 50 %[nm]
        TempWeight = false
        SigTemp = 300 %[ms]
        
        CritScore = 3
        UseProbScore = false
        Alpha = 0.95
        UseLocAlpha = false
        BoxSpat = 1000
        BoxTemp = 1000
        
        SearchRad = 50 %[nm]
        ObsProb = 75
        ScaleT = 'log'
        MinT = 30
        MaxT = inf
        NumT = 10
        UniqueCorrespondance = 1
    end %properties
    properties(Hidden)
        ProfileStartMarker = '[START ClusterSettings]'
        ProfileEndMarker = '[END ClusterSettings]'
    end %properties
    methods
        %constructor
        function this = ContainerClusterSettings(parent)
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
            this = ContainerClusterSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef