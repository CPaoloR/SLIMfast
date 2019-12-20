classdef ClassSingleCluster < matlab.mixin.Copyable
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent
        Identifier
        
        Data
    end %properties
    properties (Hidden)
        Color
        
        IsSelected = 0; %true, when selected on map
        IsPlotted = 0;
        
        NumPoints
        
        MinData
        MaxData
        
        TotalObsTime
    end %properties
    properties (Hidden, Transient)
        listenerDestruction
    end %properties
    properties (Hidden, SetObservable)
        IsActive = 1;
    end %properties
    
    methods
        %constructor
        function this = ClassSingleCluster(parent,numPnts,data,pntType,pntScore)
            if nargin > 0
                tStart = tic;
                
                %initialize class
                this.Identifier = now;
                
                this.Data = catstruct(struct(...
                    'Cluster_ID', ones(numPnts,1)*this.Identifier,...
                    'Cluster_ID_Hex', num2hex(ones(numPnts,1)*this.Identifier)),...
                    catstruct(data,struct(...
                    'Point_Type', pntType,...
                    'Point_Score', pntScore)));
                
                this.NumPoints = numPnts;
                this.MinData = structfun(@(x) min(x),data,'un',0);
                this.MaxData = structfun(@(x) max(x),data,'un',0);
                
                this.TotalObsTime = this.MaxData.Time-this.MinData.Time+1; %[frames]
                
                set_parent(this,parent)
                
                %this makes sure each cluster gets a unique id (15ms resolution of "now")
                pause(max(0,0.015-toc(tStart)))
            end %if
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %             this.listenerDestruction = ...
            %                 event.listener(parent,'ObjectDestruction',...
            %                 @(src,evnt)delete_object(this));
        end %fun
        
        %%
        function [muX,muY] = get_grouped_center_position(this)
            muX = mean(this.Data.Position_X);
            muY = mean(this.Data.Position_Y);
        end %fun
        
        %%
        function S = saveobj(this)
            S = class2struct(this);
            S.Parent = [];
        end %fun
        function this = reload(this,S)
            this = struct2class(S,this);
        end %fun
        function delete_object(this)
            delete(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@matlab.mixin.Copyable(this);
            
            cpObj.Identifier = now;
            cpObj.Parent = [];
            
            %             cpObj.IsActive = 1;
            cpObj.IsPlotted = 0;
            cpObj.IsSelected = 0;
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ClassSingleCluster;
            
            if isobject(S) %backwards-compatibility
                S = saveobj(S);
            end %if
            
            this = reload(this,S);
        end %fun
    end %methods
end %classdef