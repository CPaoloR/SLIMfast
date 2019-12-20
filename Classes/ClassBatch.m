classdef ClassBatch < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties(Hidden)
        Parent %SLIMfast
        %         Identifier
        FamilyColor = get(0,'DefaultUIControlBackgroundColor');
        
        %         hData
        
        Px2nm
        Frame2msec
        Count2photon
        FieldOfView = [0 0 1 1 1 1]
        
        objUnitConvFac
        objLocSettings
        objTrackSettings
        objClusterSettings
    end %properties
    properties(Hidden,Transient)
        objData
        NumData
        listenerDestruction
    end %properties
    
    events
        ClosingVisualization
        ObjectDestruction
    end %events
    
    methods
        %constructor
        function this = ClassBatch(parent)
            set_parent(this,parent)
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %fired when parent (SLIMfast) gets closed
            this.listenerDestruction = ...
                event.listener(parent,'ObjectDestruction',...
                @(src,evnt)delete_object(this));
        end %fun
        
        function set_conversion_factors(this)
            [objData,isOK] = get_data_objects(this,'ClassRaw',1);
            if isOK
                this.objData = objData;
                this.NumData = numel(objData);
            else
                %error
                return
            end %if
            
            this.objUnitConvFac = ManagerUnitConvFac;
            set_parent(this.objUnitConvFac,this)
            this.objUnitConvFac.SrcContainer = ContainerUnitConvFac;
            this.objUnitConvFac.SrcContainer.Px2nm = this.Px2nm;
            this.objUnitConvFac.SrcContainer.Frame2msec = this.Frame2msec;
            this.objUnitConvFac.SrcContainer.Count2photon = this.Count2photon;
            
            this.objUnitConvFac.TargetContainer = ContainerUnitConvFac.empty;
            for idxData = 1:this.NumData
                this.objUnitConvFac.TargetContainer(idxData) = ...
                    objData(idxData).objUnitConvFac.SrcContainer;
                
                this.objUnitConvFac.TargetContainer(idxData).Px2nm = this.Px2nm;
                this.objUnitConvFac.TargetContainer(idxData).Frame2msec = this.Frame2msec;
                this.objUnitConvFac.TargetContainer(idxData).Count2photon = this.Count2photon;
            end %for
            
            set_parameter(this.objUnitConvFac)
        end %fun
        
        function particle_localization(this)
            [objData,isOK] = get_data_objects(this,'ClassRaw');
            if isOK
                this.objData = objData;
                this.NumData = numel(objData);
            else
                %error
                return
            end %if
            
            this.objLocSettings = ManagerLocSettings;
            set_parent(this.objLocSettings,this)
            this.objLocSettings.SrcContainer = ContainerLocSettings;
            this.objLocSettings.TargetContainer = ContainerLocSettings.empty;
            for idxData = 1:this.NumData
                this.objLocSettings.TargetContainer(idxData) = ...
                    objData(idxData).objLocSettings.SrcContainer;
            end %for
            
            set_parameter(this.objLocSettings)
            set([this.objLocSettings.hProfilePopup,...
                this.objLocSettings.hLocTestButton],...
                'Enable','off')
        end %fun
        function single_localization(this)
            if ishandle(this.objLocSettings.hFig)
                delete(this.objLocSettings.hFig)
            end %if
            
            for idxData = 1:this.NumData
                single_localization(this.objData(idxData))
            end %for
        end %fun
        
        function particle_tracking(this)
            [objData isOK] = get_data_objects(this,'ClassLocalization');
            if isOK
                this.objData = objData;
                this.NumData = numel(objData);
            else
                %error
                return
            end %if
            
            this.objTrackSettings = ManagerTrackSettings;
            set_parent(this.objTrackSettings,this)
            this.objTrackSettings.SrcContainer = ContainerTrackSettings;
            this.objTrackSettings.TargetContainer = ContainerTrackSettings.empty;
            for idxData = 1:this.NumData
                this.objTrackSettings.TargetContainer(idxData) = ...
                    objData(idxData).objTrackSettings.SrcContainer;
            end %for
            
            set_parameter(this.objTrackSettings)
            set([this.objTrackSettings.hProfilePopup],...
                'Enable','off')
        end %fun
        function reconstruct_trajectories(this)
            if ishandle(this.objTrackSettings.hFig)
                delete(this.objTrackSettings.hFig)
            end %if
            
            for idxData = 1:this.NumData
                reconstruct_trajectories(this.objData(idxData))
            end %for
        end %fun
        
        function filter_immobile(this)
            [objData isOK] = get_data_objects(this,'ClassLocalization');
            if isOK
                this.objData = objData;
                this.NumData = numel(objData);
            else
                %error
                return
            end %if
            
            this.objClusterSettings = ManagerClusterSettings;
            set_parent(this.objClusterSettings,this)
            this.objClusterSettings.SrcContainer = ContainerClusterSettings;
            this.objClusterSettings.TargetContainer = ContainerClusterSettings.empty;
            for idxData = 1:this.NumData
                this.objClusterSettings.TargetContainer(idxData) = ...
                    objData(idxData).objClusterSettings.SrcContainer;
            end %for
            
            set_parameter(this.objClusterSettings,1)
            set([this.objClusterSettings.hProfilePopup,...
                this.objClusterSettings.hEvalButton],...
                'Enable','off')
        end %fun
        function construct_density_based_cluster(this)
            if ishandle(this.objClusterSettings.hFig)
                delete(this.objClusterSettings.hFig)
            end %if
            
            for idxData = 1:this.NumData
                initialize_data(this.objData(idxData).objClusterSettings)
                dbscan(this.objData(idxData).objClusterSettings)
                objCluster = construct_density_based_cluster(this.objData(idxData));
                %deactivate first cluster (=exclusive clustering)
                objCluster.objIndividual(1).IsActive = 0;
                %get filtered localization set
                objCluster.SubsetMode = 'Inactive Subset';
                objLocFiltered = transform_to_image(objCluster);
                objLocFiltered.Name = ...
                    [objLocFiltered.Name '_Filtered'];
                set(objLocFiltered.hExplorerLeaf,...
                    'Name',objLocFiltered.Name)
            end %for
            update_project_tree(this.Parent.objProjectExplorer)
        end %fun
        
        %         function jumpseries_analysis(this)
        %             [objData isOK] = get_data_objects(this,'ClassTrajectory');
        %             if ~isOK
        %                 %error
        %                 return
        %             end %if
        %
        %             objJumpseries = ManagerJumpSeries(this);
        %             initialize_jumpsize_series(objJumpseries,objData)
        %         end %fun
        function pool_trajectories(this)
            [objData, isOK] = get_data_objects(this,'ClassTrajectory');
            if ~isOK
                %error
                return
            end %if
            
            %generate new pooled trajectory object
            objProject = ClassProject;
            objSLIMfast = this.Parent;
            set_parent(objProject,objSLIMfast)
            log_in_project(objSLIMfast,objProject)
            
            objTraj = clone_object(objData(1),objProject,...
                'CloneIndividualList',1);
            objTraj.ExportBin = [];
            add_data_to_project(objProject,objTraj)
            
            for idxObj = 2:numel(objData)
                cloneList = ...
                    clone_individual_list(objData(idxObj),...
                    objTraj,'All');
                
                %append to the list
                objTraj.objIndividual = ...
                    [objTraj.objIndividual cloneList];
                objTraj.NumIndividual = numel(objTraj.objIndividual);
            end %for
        end %fun
        function pool_clusters(this)
            [objData, isOK] = get_data_objects(this,'ClassCluster');
            if ~isOK
                %error
                return
            end %if
            
            %generate new pooled trajectory object
            objProject = ClassProject;
            objSLIMfast = this.Parent;
            set_parent(objProject,objSLIMfast)
            log_in_project(objSLIMfast,objProject)
            
            objCluster = clone_object(objData(1),objProject,...
                'CloneIndividualList',1);
            objCluster.ExportBin = [];
            add_data_to_project(objProject,objCluster)
            
            for idxObj = 2:numel(objData)
                cloneList = ...
                    clone_individual_list(objData(idxObj),...
                    objCluster,'All');
                
                %append to the list
                objCluster.objIndividual = ...
                    [objCluster.objIndividual cloneList];
                objCluster.NumIndividual = numel(objCluster.objIndividual);
            end %for
        end %fun
        function dualview_colocalization(this)
            [objData isOK] = get_data_objects(this,'ClassLocalization');
            if isOK && numel(objData) == 2
                this.objData = objData;
                this.NumData = 2;
            else
                %error
                return
            end %if
            
            objProject = get_parental_object(objData(1),'ClassProject');
            objComposite = create_composite_data(objProject);
            channelNames = {'Red','Green'};
            for idxData = 1:2
                copy_data_to_composite(...
                    objComposite,objData(idxData),channelNames{idxData})
            end %for
            set_parameter(objComposite.objCoLocSettings)
        end %fun
        
        %%
        function [objData,isOK] = get_data_objects(this,dataType,ignoreUnits)
            if nargin < 3
                ignoreUnits = false;
            end %if
            
            selection = this.Parent.objProjectExplorer.hProjectTree.getSelectedNodes;
            numSelected = numel(selection);
            
            objData = [];
            
            isLeaf = 1;
            isDataType = 1;
            for idxLeaf = 1:numSelected
                %check if selection is leaf
                if ~strcmp(get(selection(idxLeaf),'Value'),'IsLeaf')
                    isLeaf = 0;
                end %if
                %check if selection is proper data type
                if strcmp(class(get(selection(idxLeaf),...
                        'UserData')),dataType)
                    objData = [objData;...
                        get(selection(idxLeaf),'UserData')];
                    
                    px2nm(idxLeaf,1) = objData(end,1).Px2nm;
                    frame2msec(idxLeaf,1) = objData(end,1).Frame2msec;
                    count2photon(idxLeaf,1) = objData(end,1).Count2photon;
                else
                    isDataType = 0;
                end %if
            end %for
            
            if isLeaf && isDataType
                if ignoreUnits || (all(eq(px2nm,px2nm(1))) && ...
                        all(eq(frame2msec,frame2msec(1))) && ...
                        all(eq(count2photon,count2photon(1))))
                    isOK = 1;
                    
                    this.Px2nm = px2nm(1);
                    this.Frame2msec = frame2msec(1);
                    this.Count2photon = count2photon(1);
                else
                    %unit error
                    isOK = 0;
                end %if
            else
                %selection error
                isOK = 0;
            end %if
        end %fun
        
        function delete_object(this)
            notify(this,'ObjectDestruction')
            
            delete(this)
        end %fun
    end %methods
end %classdef