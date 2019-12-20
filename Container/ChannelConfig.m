classdef ChannelConfig < matlab.mixin.Copyable
    properties
        IsMultiColor = 0;
        UseCatenate = 0;
        
        NumParallelChannels = 1;%number of parallel aquisition channels
        NumAlternatingChannels = 1; %number of channels in alternating aquisition mode
        
        ChannelRegionNorm = [0 0 1 1 1 1] %[x0 y0 xEnd yEnd ImageWidth ImageHeight] normalized region of aquisition channel
        ChannelRegionPx %[x0 y0 xEnd yEnd ImageWidth ImageHeight] pixel region of aquisition channel
        
        HasCalMatrix = 0;
        CalMatrix = []%transformation matrix
    end %properties
    
    methods
        function this = ChannelConfig
        end %fun
        
        function S = saveobj(this)
            S = class2struct(this);
        end %fun
        function this = reload(this,S)
            this = struct2class(S,this);
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ChannelConfig;
             if isobject(S) %backwards-compatibility
                    S = saveobj(S);                    
                end %if
                this = reload(this,S);
        end %fun
    end %methods
end %classdef
