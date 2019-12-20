classdef ContainerTrackSettings < SuperclassContainer
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties        
        Dim = 1
        ResLimit = 1.3 %Resolution limit in pixels, to be used in calculating the merge/split search radius
        LocDensWin = 10 %Number of past frames used in nearest neighbor calculation
        GapPenalty = 1.5 %Gap length penalty (disappearing for n frames gets a penalty of gapPenalty^n)
        %Note that a penalty = 1 implies no penalty, while a penalty < 1 implies that longer gaps are favored
        
        %step1
        InitMinSearchRad = 0.5 %Search radius lower limit
        InitMaxSearchRad = 5 %Search radius upper limit
        InitUseLocDens = false %Flag for using local density in search radius estimation
        %         UseInitGapClosure
        %         InitMaxGap
        %step2
        MinCompoundLength = 3 %Minimum track segment length used in the gap closing, merging and splitting step
        MinSearchRad = 1 %Search radius lower limit
        MaxSearchRad = 10 %Search radius upper limit
        UseLocDens = false %Flag for using local density in search radius estimation
        FreeScaleFast = 0.5 %power for scaling the Brownian search radius with time
        FreeScaleSlow = 0.01 %power for scaling the Brownian search radius with time
        FreeScaleTrans = 3
        UseGapClosure = true
        MaxGap = 5
        UseMergeSplit = false %Flag for merging and splitting
        MinAmpRatio = 0.5 %Amplitude ratio lower limit
        MaxAmpRatio = 1.5 %Amplitude ratio upper limit
                
        UseLinModel = false %Flag for linear motion
        LinClassifyLength = 5 %Minimum length (frames) for track segment analysis
        LinScaleFast = 0.5 %power for scaling the linear search radius with time
        LinScaleSlow = 0.01 %power for scaling the linear search radius with time
        LinScaleTrans = 5
        LinMaxAngle = 45 %Maximum angle between the directions of motion of two linear track segments that are allowed to get linked
    end %properties
    properties(Hidden)
        TrackStart = -inf
        TrackEnd = inf

        InitSearchExpFac = 3; %Standard deviation multiplication factor
        SearchExpFac = 3; %Standard deviation multiplication factor
        LinSearchExpFac = 3 %Standard deviation multiplication factor along preferred direction of motion
        
        ProfileStartMarker = '[START TrackSettings]'
        ProfileEndMarker = '[END TrackSettings]'
    end %fun
    methods
        %constructor
        function this = ContainerTrackSettings(parent)
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
            this = ContainerTrackSettings;
            this = loadobj@SuperclassContainer(this,S);
        end %fun
    end %methods
end %classdef
