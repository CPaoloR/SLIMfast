classdef ClassCluster < SuperclassData
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        DetectionMap
        
        VisMode = 'List';
        SubsetMode = 'Complete Set';
        
        NumIndividual
        objIndividual = ClassSingleCluster.empty
    end %properties
    properties (Hidden, Dependent)
        NumActive
        ActiveIdx
    end %properties
    properties (Hidden, Transient)
        hListFig = nan;
        hListAx
        hListToolbar
        hListContextmenu
        hListTitle
        hListLine
        hListSlider
        
        hDetailFig = nan;
        hDetailAx
        hDetailToolbar
        hDetailContextmenu
        
        IndividualSelectIdx
        
        Header = struct(...
            'Particle_ID', 'Unique Emitter Identifier',...
            'Particle_ID_Hex', 'Unique Emitter Identifier Hexadecimal',...
            'Time', 'Time of Emitter Localization [frame]',...
            'Position_X', 'X-Coordinate of Emitter Center [px]',...
            'Position_Y', 'Y-Coordinate of Emitter Center [px]',...
            'Signalpower', 'Emitters'' Signalpower [counts^2]',...
            'Background', 'Average Backgroundlevel around Emitter [counts]',...
            'Noisepower', 'Emitters'' Noisepower [counts^2]',...
            'Photons', 'Emitters'' Signal [photons]',...
            'PSFradius', 'Std of Emitters'' PSF [px]',...
            'Precision', 'Emitter Localization Precision [nm]',...
            'SNR', 'Emitters'' Signal to Noise Ratio [db]',...
            'NN', 'Emitter Distance to next nearest Emitter [�m]',...
            'PSFradius_Y', 'X-Std of Emitters'' PSF [px]',...
            'PSFradius_X', 'Y-Std of Emitters'' PSF [px]',...
            'PSFcov', 'Cov of Emitters'' PSF [px^2]',...
            'Cluster_ID', 'Unique Cluster Identifier',...
            'Cluster_ID_Hex', 'Unique Cluster Identifier Hexadecimal',...
            'Cluster_Position_X', 'X-Coordinate of Cluster Center [px]',...
            'Cluster_Position_Y', 'Y-Coordinate of Cluster Center [px]',...
            'Point_Type', '',...
            'Point_Score','');
        
        %% Tooltips
        ToolTips = struct(...
            'Toolbar', struct(...
            'SaveImage', sprintf('Save Image as TIFF'),...
            'SaveMovie', sprintf('Save Image Sequence as AVI'),...
            'SaveFigure', sprintf('Save Image to various Formats'),...
            'SaveData', sprintf('Save Data as ASCII'),...
            'SwitchListMap', sprintf('Switch to Map View'),...
            'SwitchMapList', sprintf('Switch to List View'),...
            'DisplayManager', sprintf('Adjust Cluster Display Settings'),...
            'CloneData', sprintf('Duplicate actual Data'),...
            'Trans2Image', sprintf('Generate Image from Data'),...
            'ClusterLifeDist', sprintf('Show Cluster Lifetime Distribution'),...
            'RoiManager', sprintf('Create/Load Region of Interest')))
    end %properties
    
    methods
        %constructor
        function this = ClassCluster
            %initialize parental class
            this = this@SuperclassData;
        end %fun
        
        %%
        function initialize_list_visualization(this)
            scrSize = get(0, 'ScreenSize');
            
            this.hListFig =...
                figure(...
                'Units', 'pixels',...
                'Position', [0.5*(scrSize(3)-650) ...
                0.5*(scrSize(4)-500) 650 500],...
                'MenuBar', 'none',...
                'Toolbar', 'none',...
                'DockControls', 'off',...
                'Resize', 'off',...
                'NumberTitle', 'off',...
                'NextPlot', 'add',...
                'Color', this.FamilyColor,...
                'Name', this.Name,...
                'WindowScrollWheelFcn', @(src,evnt)scroll_wheel_actions(this,evnt),...
                'IntegerHandle','off',...
                'CloseRequestFcn',@(src,evnt)close_object(this));
            
            %construct associated toolbar
            construct_list_toolbar(this)
            
            %construct associated context menu
            this.hListContextmenu = uicontextmenu(...
                'Parent',this.hListFig);
            uimenu(this.hListContextmenu,...
                'Label', 'Activate All',...
                'Callback',@(src,evnt)change_ensemble_state(this,src))
            uimenu(this.hListContextmenu,...
                'Label', 'Deactivate All',...
                'Callback',@(src,evnt)change_ensemble_state(this,src))
            set(this.hListFig, ...
                'UIContextmenu', this.hListContextmenu)
            
            numActive = this.NumActive;
            good = 1:20 <= numActive;
            
            this.hListAx = [];
            pos = [repmat((0:0.2:0.8)-0.01,1,4);...
                reshape(repmat((0.8:-0.25:0)-0.02,5,1),1,[])];
            
            activeIdx = find(this.ActiveIdx);
            for idx = 1:20
                this.hListAx(idx) =...
                    axes(...
                    'Parent', this.hListFig,...
                    'Units', 'normalized',...
                    'Position', [0 0 1 1],...
                    'OuterPosition', [pos(1,idx) pos(2,idx) 0.2 0.2],...
                    'Color', this.FamilyColor,...
                    'XColor',this.FamilyColor,...
                    'YColor',this.FamilyColor,...
                    'DataAspectRatio', [1 1 1],...
                    'XTickLabel', '',...
                    'YTickLabel', '');
                
                if good(idx)
                    clusterIdx = activeIdx(idx);
                    
                    set(this.hListAx(idx),...
                        'ButtonDownFcn', @(src,evnt)initialize_individual_details(...
                        this,this.objIndividual(idx)))
                    
                    this.hListTitle(idx) = ...
                        title(this.hListAx(idx),...
                        ['ID: ' sprintf('%bx',this.objIndividual(clusterIdx).Identifier)],...
                        'Fontsize', 8,...
                        'ButtonDownFcn', @(src,evnt)change_state(...
                        this,src,this.objIndividual(idx)));
                    switch this.objIndividual(idx).IsActive
                        case 1
                            set(this.hListTitle(idx),...
                                'BackgroundColor',[0.5 1 0.5])
                        case 0
                            set(this.hListTitle(idx),...
                                'BackgroundColor',[1 0.5 0.5])
                    end %switch
                    
                    this.hListLine(idx,1) =...
                        line('Parent', this.hListAx(idx),...
                        'XData',this.objIndividual(clusterIdx).Data.Position_X,...
                        'YData',this.objIndividual(clusterIdx).Data.Position_Y,...
                        'Marker', '.',...
                        'Color', [0 0 0],...
                        'LineStyle', 'none',...
                        'ButtonDownFcn', ...
                        @(src,evnt)initialize_individual_details(...
                        this,this.objIndividual(idx)));
                    
                    minx = this.objIndividual(clusterIdx).MinData.Position_X-0.5;
                    maxx = this.objIndividual(clusterIdx).MaxData.Position_X+0.5;
                    miny = this.objIndividual(clusterIdx).MinData.Position_Y-0.5;
                    maxy = this.objIndividual(clusterIdx).MaxData.Position_Y+0.5;
                    
                    this.hListLine(idx,2) =...
                        line('Parent', this.hListAx(idx),...
                        'XData',[minx,minx+1],...
                        'YData',[miny,miny]-(maxy-miny)/10,...
                        'Color', [1 0 0],...
                        'LineWidth', 4,...
                        'Hittest', 'off');
                    axis(this.hListAx(idx),...
                        [minx maxx ...
                        miny-(maxy-miny)/5 maxy], 'ij')
                else
                    this.hListTitle(idx) = ...
                        title(this.hListAx(idx),...
                        '','Fontsize', 8);
                    
                    this.hListLine(idx,1) =...
                        line(...
                        'Parent',this.hListAx(idx),...
                        'XData',[0 1],...
                        'YData',[0 1],...
                        'Marker', '.',...
                        'Color', [0 0 0],...
                        'LineStyle', 'none',...
                        'Hittest', 'off',...
                        'Visible','off');
                    
                    this.hListLine(idx,2) =...
                        line(...
                        'Parent',this.hListAx(idx),...
                        'XData',[0 1],...
                        'YData',[0 1],...
                        'Color', [1 0 0],...
                        'LineWidth', 4,...
                        'Visible','off');
                end %if
            end %for
            
            this.hListSlider = ...
                uicontrol(...
                'Parent', this.hListFig,...
                'Style', 'slider',...
                'Tag', 'trajectoryListSlider',...
                'Units', 'normalized',...
                'Position', [0.98 0 0.02 1],...
                'Min', 1,...
                'Max', 2,...
                'Callback', @(src,evnt)update_list_visualization(this));
            if numActive > 20
                set(this.hListSlider,...
                    'Min', 1,...
                    'Max', ceil(numActive/20),...
                    'Value', ceil(numActive/20),....
                    'SliderStep', [min(1/(ceil(numActive/20)-1),1)...
                    min(5/(ceil(numActive/20)-1),1)],...
                    'Visible','on',...
                    'Enable','on')
            else
                set(this.hListSlider,...
                    'Value', 1,...
                    'Visible','off',...
                    'Enable','off')
            end %if
            
            if isempty(this.ExportBin)
                fields = fieldnames(this.objIndividual(1).Data);
                dataIndividual = [this.objIndividual.Data];
                data = this.objIndividual(1).Data;
                for fieldIdx = 1:numel(fields)
                    data.(fields{fieldIdx}) = vertcat(dataIndividual.(fields{fieldIdx}));
                end %for
                
                for idxCluster = 1:this.NumIndividual
                    [data.Cluster_Position_X(idxCluster,1),...
                        data.Cluster_Position_Y(idxCluster,1)] = ...
                        get_grouped_center_position(this.objIndividual(idxCluster));
                end %for
                
                this.ExportBin = struct(...
                    'Header', this.Header,...
                    'Data', data);
            end %if
        end %fun
        function construct_list_toolbar(this)
            hToolbar = uitoolbar('Parent',this.hListFig);
            icon = getappdata(0,'icon');
            hSaveData = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('Save_Data'),...
                'TooltipString', this.ToolTips.Toolbar.SaveData,...
                'ClickedCallback', @(src,evnt)write_variable_to_ascii(this));
            hSwitchListMap = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('Trajectory_Map'),...
                'TooltipString', this.ToolTips.Toolbar.SwitchListMap,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)initialize_image_visualization(this),...
                'Enable','off');
            setMode = {'Complete Set','Active Subset','Inactive Subset'};
            hCloneData = ...
                uisplittool(...
                'Parent', hToolbar,...
                'Tag', setMode{1},...
                'CData', icon.('Generate_Subset'),...
                'TooltipString', this.ToolTips.Toolbar.CloneData,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)generate_filtered_data_set(this));
            pause(0.05)
            jBin = get(hCloneData,'JavaContainer');
            pause(0.05)
            jMenu = get(jBin,'MenuComponent');
            for mode = 1:numel(setMode)
                jOption = jMenu.add(setMode{mode});
                set(jOption, 'ActionPerformedCallback', ...
                    @(src,evnt)set_individual_subset(this));
            end %for
            hTrans2Image = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('Generate_Image'),...
                'TooltipString', this.ToolTips.Toolbar.Trans2Image,...
                'ClickedCallback', @(src,evnt)transform_to_image(this));
                            
            hClusterLifeDist = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Cluster_Lifetime_Distribution'),...
                'TooltipString', this.ToolTips.Toolbar.ClusterLifeDist,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,...
                'Cluster Lifetime Distribution',this));
            
            this.hListToolbar = struct(...
                'Toolbar', hToolbar,...
                'SaveData', hSaveData,...
                'SwitchListMap', hSwitchListMap,...
                'Trans2Image', hTrans2Image,...
                'CloneData', hCloneData,...
                'ClusterLifeDist', hClusterLifeDist);
        end %fun
        function update_list_visualization(this)
            %check that set has at least one element
            numActive = this.NumActive;
            if numActive == 0
                set(cell2mat(allchild(this.hListAx)),...
                    'Visible', 'off')
                set(this.hListAx,'HitTest','off')
            else
                page = (ceil(numActive/20)-...
                    round(get(this.hListSlider,'Value')))*20;
                idxs = 1:20;
                good = idxs+page <= numActive;
                set(cell2mat(allchild(this.hListAx)),...
                    'Visible', 'off')
                set(this.hListAx(~good),'HitTest','off')
                
                if sum(good) == 1
                    set(allchild(this.hListAx(good)),...
                        'Visible', 'on',...
                        'HitTest','on')
                else
                    set(cell2mat(allchild(this.hListAx(good))),...
                        'Visible', 'on',...
                        'HitTest','on')
                end %if
                
                activeIdx = find(this.ActiveIdx);
                for idx = idxs(good)
                    clusterIdx = activeIdx(idx+page);
                    
                    set(this.hListAx(idx), 'ButtonDownFcn', ...
                        @(src,evnt)initialize_individual_details(this,...
                        this.objIndividual(clusterIdx)));
                    
                    set(this.hListTitle(idx), 'String',...
                        ['ID: ' sprintf('%bx',this.objIndividual(clusterIdx).Identifier)],...
                        'ButtonDownFcn', @(src,evnt)change_state(...
                        this,src,this.objIndividual(clusterIdx)))
                    switch this.objIndividual(clusterIdx).IsActive
                        case 1
                            set(this.hListTitle(idx),...
                                'BackgroundColor',[0.5 1 0.5])
                        case 0
                            set(this.hListTitle(idx),...
                                'BackgroundColor',[1 0.5 0.5])
                    end %switch
                    
                    set(this.hListLine(idx,1),...
                        'XData', this.objIndividual(clusterIdx).Data.Position_X,...
                        'YData',this.objIndividual(clusterIdx).Data.Position_Y,...
                        'Marker', '.',...
                        'LineStyle', 'none',...
                        'ButtonDownFcn', ...
                        @(src,evnt)initialize_individual_details(this,...
                        this.objIndividual(clusterIdx)))
                    
                    minx = this.objIndividual(clusterIdx).MinData.Position_X-0.5;
                    maxx = this.objIndividual(clusterIdx).MaxData.Position_X+0.5;
                    miny = this.objIndividual(clusterIdx).MinData.Position_Y-0.5;
                    maxy = this.objIndividual(clusterIdx).MaxData.Position_Y+0.5;
                    
                    set(this.hListLine(idx,2),...
                        'XData', [minx,minx+1],...
                        'YData',[miny,miny]-(maxy-miny)/10)
                    
                    axis(this.hListAx(idx), [minx maxx ...
                        miny-(maxy-miny)/5 maxy], 'ij')
                end %for
            end %if
        end %fun
        function change_state(this,src,objIndividual)
            if objIndividual.IsActive
                objIndividual.IsActive = 0;
                set(src,'BackgroundColor',[1 0.5 0.5])
            else
                objIndividual.IsActive = 1;
                set(src,'BackgroundColor',[0.5 1 0.5])
            end %if
            switch this.SubsetMode
                case {'Active Subset' 'Inactive Subset'}
                    %adjust slider
                    if this.NumActive > 20
                        set(this.hListSlider,...
                            'Min', 1,...
                            'Max', ceil(this.NumActive/20),...
                            'Value', min(ceil(this.NumActive/20),...
                            get(this.hListSlider,'Value')),....
                            'SliderStep', [min(1/(ceil(this.NumActive/20)-1),1)...
                            min(5/(ceil(this.NumActive/20)-1),1)],...
                            'Visible','on',...
                            'Enable','on')
                    else
                        set(this.hListSlider,...
                            'Value', 1,...
                            'Visible','off',...
                            'Enable','off')
                    end %if
                    
                    update_list_visualization(this)
            end %switch
        end %fun
        function scroll_wheel_actions(this,evnt)
            maxSlider = get(this.hListSlider,'Max');
            actValue = get(this.hListSlider,'Value');
            newValue = max(1,min(maxSlider,actValue-...
                evnt.VerticalScrollCount));
            if newValue ~= actValue
                set(this.hListSlider,'Value',newValue)
                update_list_visualization(this)
            end %if
        end %fun
        
        %%
        function initialize_individual_details(this,objIndividual)
        end %fun
        
        %%
        function set_individual_subset(this)
            this.SubsetMode = get(gcbo,'Text');
            
            %adjust slider
            if this.NumActive > 20
                set(this.hListSlider,...
                    'Min', 1,...
                    'Max', ceil(this.NumActive/20),...
                    'Value', ceil(this.NumActive/20),....
                    'SliderStep', [min(1/(ceil(this.NumActive/20)-1),1)...
                    min(5/(ceil(this.NumActive/20)-1),1)],...
                    'Visible','on',...
                    'Enable','on')
            else
                set(this.hListSlider,...
                    'Value', 1,...
                    'Visible','off',...
                    'Enable','off')
            end %if
            
            update_list_visualization(this)
        end %fun
        
        function change_ensemble_state(this,src)
            switch get(src,'Label')
                case 'Activate All'
                    for clusterIdx = 1:this.NumIndividual
                        if ~this.objIndividual(clusterIdx).IsActive
                            this.objIndividual(clusterIdx).IsActive = 1;
                        end %if
                    end %for
                case 'Deactivate All'
                    for clusterIdx = 1:this.NumIndividual
                        if this.objIndividual(clusterIdx).IsActive
                            this.objIndividual(clusterIdx).IsActive = 0;
                        end %if
                    end %for
            end %switch
            
            switch this.VisMode
                case 'List'
                    %adjust slider
                    if this.NumActive > 20
                        set(this.hListSlider,...
                            'Min', 1,...
                            'Max', ceil(this.NumActive/20),...
                            'Value', ceil(this.NumActive/20),....
                            'SliderStep', [min(1/(ceil(this.NumActive/20)-1),1)...
                            min(5/(ceil(this.NumActive/20)-1),1)],...
                            'Visible','on',...
                            'Enable','on')
                    else
                        set(this.hListSlider,...
                            'Value', 1,...
                            'Visible','off',...
                            'Enable','off')
                    end %if
                    
                    update_list_visualization(this)
                case 'Map'
                    display_frame(this)
            end %switch
        end %fun
        %%
        function objLoc = transform_to_image(this)
            %check that set has at least one element
            objProject = this.Parent;
            objLoc = ClassLocalization;
            set_parent(objLoc,objProject)
            objLoc.Name = this.Name;
            objLoc.DetectionMap = this.DetectionMap;
            
            objLoc.objImageFile = copy(this.objImageFile);
            set_parent(objLoc.objImageFile,objLoc)
            objLoc.objUnitConvFac = copy(this.objUnitConvFac);
            set_parent(objLoc.objUnitConvFac,objLoc)
            objLoc.objLocSettings = copy(this.objLocSettings);
            set_parent(objLoc.objLocSettings,objLoc)
            objLoc.objTrackSettings = copy(this.objTrackSettings);
            set_parent(objLoc.objTrackSettings,objLoc)
            
            objLoc.objContrastSettings = ManagerContrastSettings(objLoc);
            objLoc.objDisplaySettings = ManagerDisplaySettings(objLoc);
            objLoc.objClusterSettings = ManagerClusterSettings(objLoc);
            
            objLoc.objColormap = ManagerColormap(objLoc);
            objLoc.objGrid = ManagerGrid(objLoc);
            objLoc.objRoi = ManagerRoi(objLoc);
            objLoc.objScalebar = ManagerScalebar(objLoc);
            objLoc.objTimestamp = ManagerTimestamp(objLoc);
            objLoc.objTextstamp = ManagerTextstamp(objLoc);
            objLoc.objLineProfile = ManagerLineProfile(objLoc);
            
            if this.objRoi.CropRoi
                objLoc.FieldOfView = this.MaskRect;
            else
                objLoc.FieldOfView = this.FieldOfView;
            end %if
            
            fieldName = fieldnames(this.objIndividual(1).Data);
            if this.NumActive > 0
                data = vertcat(this.objIndividual(this.ActiveIdx).Data);
                %must sort for subsequent tracking
                [~,sortIdx] = sort(vertcat(data.Time));
                for fieldIdx = 1:numel(fieldName)
                    if ~any(strcmp(fieldName{fieldIdx},...
                            {'Cluster_ID','Cluster_ID_Hex','Point_Type','Point_Score'}))
                        unsortedData = vertcat(data.(fieldName{fieldIdx}));
                        objLoc.Data.(fieldName{fieldIdx}) = ...
                            unsortedData(sortIdx);
                    end %if
                end
                objLoc.NumParticles = sum([this.objIndividual(this.ActiveIdx).NumPoints]);
                
                isOK = show_frame(objLoc,1);
                
                add_data_to_project(...
                    get_parental_object(this,'ClassProject'),objLoc)
                
                %check if actual data object is visualized
                if ishandle(this.hImageFig) || ...
                        ishandle(this.hListFig)
                    initialize_visualization(objLoc)
                end %if
            else
                objLoc.NumParticles = 0;
                for fieldIdx = 1:numel(fieldName)
                    if ~any(strcmp(fieldName{fieldIdx},...
                            {'Cluster_ID','Cluster_ID_Hex','Point_Type','Point_Score'}))
                        objLoc.Data.(fieldName{fieldIdx}) = [];
                    end %if
                end
                objLoc.NumParticles = 0;
                
                add_data_to_project(...
                    get_parental_object(this,'ClassProject'),objLoc)
                
                %                 errordlg('No Data found','')
            end %if
        end %fun
        
        %%
        function cloneObj = clone_object(this,parent,varargin)
            %validate input
            input = inputParser;
            addRequired(input,'parent',@isobject);
            addOptional(input,'CloneIndividualList',1,@isnumeric)
            parse(input,parent,varargin{:});
            
            %invoke shared clone process (superclass)
            cloneObj = clone_object@SuperclassData(...
                this,input.Results.parent);
            
            %individual clone process
            if input.Results.CloneIndividualList
                [cloneList,flag] = ...
                    clone_individual_list(this,cloneObj,'All');
                cloneObj.objIndividual = cloneList;
            else
            end %if
        end %fun
        function [cloneList,flag] = ...
                clone_individual_list(this,parent,mode,idxGood)
            %initialize output
            flag = 1;
            switch mode
                case 'All'
                    numClone = this.NumIndividual;
                    cloneList = ClassSingleCluster.empty(0,numClone);
                    idxGood = 1:numClone;
                case 'Input'
                    if islogical(idxGood)
                        idxGood = find(idxGood); %transform to index
                    end %if
                    idxGood = reshape(idxGood,1,[]); %force row vector
            end %switch
            
            %clone single trajectories
            idxCloneList = 0;
            for idxList = idxGood
                idxCloneList = idxCloneList + 1;
                
                %deep copy (matlab.mixin.Copyable)
                cloneList(idxCloneList) = ...
                    copy(this.objIndividual(idxList));
                %update associated parent
                set_parent(cloneList(idxCloneList),parent)
            end %for
        end %fun
        
        function generate_filtered_data_set(this)
            %apply time filter and spatial mask
            good = this.ActiveIdx; %& this.IsInsideRoi;
            
            generate_new_data_set(this,good)
        end %fun
        function generate_new_data_set(this,good)
            objClone = clone_object(this,this.Parent,...
                'CloneIndividualList',0);
            objClone.SubsetMode = 'Complete Set';
            
            %reset roi list
            objClone.objRoi.SrcContainer.RoiList = [];
            
            cnt = 0;
            for clusterIdx = 1:this.NumIndividual
                if good(clusterIdx)
                    cnt = cnt + 1;
                    objClone.objIndividual(cnt) = ...
                        copy(this.objIndividual(clusterIdx));
                    set_parent(objClone.objIndividual(cnt),objClone)
                end %if
            end %for
            objClone.NumIndividual = sum(good);
            
            if this.objRoi.CropRoi
                objClone.FieldOfView = this.MaskRect;
            else
                objClone.FieldOfView = [0.5 0.5 ...
                    this.objImageFile.ChannelWidth*this.ActExp+0.5 ...
                    this.objImageFile.ChannelHeight*this.ActExp+0.5 ...
                    this.objImageFile.ChannelWidth*this.ActExp ...
                    this.objImageFile.ChannelHeight*this.ActExp];
            end %if
            
            add_data_to_project(...
                get_parental_object(this,'ClassProject'),objClone)
            
            if ishandle(this.hImageFig) || ...
                    ishandle(this.hListFig)
                initialize_visualization(objClone)
            end %if
        end %fun
        
        %%
        function numactive = get.NumActive(this)
            switch this.SubsetMode
                case 'Complete Set'
                    numactive = this.NumIndividual;
                case 'Active Subset'
                    numactive = sum([this.objIndividual(:).IsActive]);
                case 'Inactive Subset'
                    numactive = sum(~[this.objIndividual(:).IsActive]);
            end %switch
        end %fun
        function activeidx = get.ActiveIdx(this)
            switch this.SubsetMode
                case 'Complete Set'
                    activeidx = true(1,this.NumActive);
                case 'Active Subset'
                    activeidx = logical([this.objIndividual(:).IsActive]);
                case 'Inactive Subset'
                    activeidx = logical(~[this.objIndividual(:).IsActive]);
            end %switch
        end %fun
        
        %%
        function saveObj = saveobj(this)
%             objIndividual = this.objIndividual;
%             this.objIndividual =[];
%             for idxIndividual = 1:numel(objIndividual)
%                 this.objIndividual{idxIndividual} = objIndividual(idxIndividual);
%             end %for
            
            saveObj = saveobj@SuperclassData(this);
        end %fun
        function close_object(this)
            close_object@SuperclassData(this)
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
            if ishandle(this.hListFig)
                delete(this.hListFig)
            end %if
            if ishandle(this.hDetailFig)
                delete(this.hODetailFig)
            end %if
        end %fun
        function delete_object(this)
            delete_object@SuperclassData(this)
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
            if ishandle(this.hListFig)
                delete(this.hListFig)
            end %if
            if ishandle(this.hDetailFig)
                delete(this.hODetailFig)
            end %if
            
            delete(this)
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
%             if iscell(S.objIndividual)
%             objIndividual = S.objIndividual;
%             S.objIndividual = ClassSingleCluster;
%             for idxIndividual = 1:numel(objIndividual)
%                 S.objIndividual(idxIndividual) = objIndividual{idxIndividual};
%             end %for
%             end %if
            
            this = ClassCluster;
            this = loadobj@SuperclassData(this,S);
        end %fun
    end %methods
end %classdef