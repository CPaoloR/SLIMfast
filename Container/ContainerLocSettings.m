classdef ContainerLocSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        ErrRate = -6 %[10^]
        WinX = 9
        WinY = 9
        NumDeflat = inf
        MinInt = 0
        LocModel = 'Fixed'
        LowerBoundPSF = 50
        UpperBoundPSF = 200
        MaxIter = 100
        TermTol = -3 %[10^]
        MaxPosRef = 1.5
        LocPar = false
        nCores = 'all'
        LocLive = false
        NA = 1.45
        EmWavelength = 595 %[nm]
        CorrFactor = 1.2
        Chromophor = 'User Supplied'
        UserEmWavelength = 600 %[nm]
        SrcDiameter = 0
        TypePSF = 'theoretical'
        UserRadiusPSF = 1 %[px]
    end %properties
    properties (Hidden)
        LocStart = -inf
        LocEnd = inf

        RadiusPSF

        PSF %[nm]
        R0 %[nm]
        SpatCorrMat
        objBeads
        EstRadii
        hEditEmWavelengthState = 'off';
        
        Radius = 1:500; %[nm]
        
        ProfileStartMarker = '[START LocSettings]'
        ProfileEndMarker = '[END LocSettings]'
    end %properties
    
    methods
        %constructor
        function this = ContainerLocSettings(parent)
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
            this = ContainerLocSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
