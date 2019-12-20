classdef ContainerDisplaySettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        DisplayStart = -inf
        DisplayEnd = inf
        DisplayWin = 1
        DisplayStep = 1
        WinMode = 'Cumulative'
        RenderMode = 'Normal'        
        IsCumulative = false
        
        UseFilter = false
        FilterModel = 'Hypothesis Map'
        
        UseCalRawImage = false

        ActExp = 5 %actual displayed image expansion
        KernelModel = 'Fixed Radius'
        RadWeight = 1
        
        HideLapsedTraj = false
        TrajUserColor = [1 1 1] %white
        TrajColorCode = 'Random'
        TrajColorRangeStart = -inf
        TrajColorRangeEnd = inf
        TrajLineWidth = 1
        TrajLineStyle = '-'
    end %properties
    properties (Hidden)
        FilterSettings
        ProfileStartMarker = '[START DisplaySettings]'
        ProfileEndMarker = '[END DisplaySettings]'
    end %properties

    methods
        %constructor
        function this = ContainerDisplaySettings(parent)
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
            this = ContainerDisplaySettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
