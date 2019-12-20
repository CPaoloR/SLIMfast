classdef ClassComposite < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Created
        
        Parent %Project
        FamilyColor
        Name
        
        ExpNotes
        
        DataCompMode = 0; %(0 = no data)
        hImChannel = {[] [] [] []};
        hClusterChannel = {};
        hTrajChannel = {};
        
        RawImagedata
        FieldOfView %[x0 y0 xEnd yEnd width height] defines working region
        
        ActExp
        Px2nm
        Frame2msec
        Count2photon
        
        objContrastSettings
        objDisplaySettings
        objColormap
        objGrid
        objRoi %Roi Manager
        objScalebar %Scalebar Manager
        objTimestamp %Timestamp Manager
        objColorbar %Colorbar Manager
        objTextstamp %Textstamp Manager
        objCoLocSettings %Colocalization Manager
        
        objPICCS
    end %properties
    properties(Hidden, Dependent)
        LocStart
        LocEnd
        
        NumFrames %total number of frames
        
        SrcExp
        
        ClassIdx
        NumClasses
    end %properties
    properties(Hidden, Transient)
        hImageFig = nan;
        hImageInfoPanel
        hImagePlotPanel
        hImageAx
        hImageToolbar
        jClusterMenu
        hSelectedCluster
        jTrajMenu
        hSelectedTraj
        hImage
        hImageScrollpanel
        
        hImageContextmenu
        
        hImageZoomFig
        
        hCompositeNode
        hChannelNodes = {[] [] [] [] [] []};
        ChannelNames = {...
            'Red',...
            'Green',...
            'Blue',...
            'Grey',...
            'Cluster',...
            'Track'};
        listenerCompositeNodeDestruction
        
        MovProfiles = {...
            'Motion JPEG AVI',...
            'MPEG-4',...
            'Uncompressed AVI'};
        
        %% Tooltips
        ToolTips = struct(...
            'Toolbar', struct(...
            'SaveImage', sprintf('Save Image as TIFF'),...
            'SaveMovie', sprintf('Save Image Sequence as AVI'),...
            'SaveFigure', sprintf('Save Image to various Formats'),...
            'DisplayManager', sprintf('Adjust Image Display Settings'),...
            'Channel', sprintf('Select Data Channel')),...
            'CoLocManager', sprintf('Find Emitter Co-Localization'))
        
        listenerDestruction
    end %properties
    properties(Hidden, SetObservable)
        Frame %actual frame
        Imagedata %image displayed (postprocessed)
    end %properties
    
    events
        ClosingVisualization
        ObjectDestruction
    end %events
    
    methods
        %constructor
        function this = ClassComposite
            this.Created = datestr(now);
            
            this.FamilyColor = min(0.99+rand*eps,1+randn(1,3)*0.1);
            this.Name = 'Nameless';
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %fired when parent (project) gets closed
            this.listenerDestruction = ...
                event.listener(parent,'ObjectDestruction',...
                @(src,evnt)delete_object(this));
        end %fun
        function set_children(this)
            %search all properties for objects and in case assign this instance to
            %their parent property
            
            classInfo = metaclass(this);
            classProp = classInfo.PropertyList;
            
            take = not([classProp.Dependent]);
            propNames = {classProp(take).Name};
            propNames(strcmp(propNames,'Parent')) = [];
            
            for idxProp = 1:numel(propNames)
                if isobject(this.(propNames{idxProp})) %check for class object
                    objChild = this.(propNames{idxProp});
                    
                    for idxObj = 1:numel(objChild)
                        classInfo = metaclass(objChild(idxObj));
                        methodList = {classInfo.MethodList.Name};
                        if any(strcmp(methodList,'set_children'))
                            %invoke grand-child search (chain-search)
                            set_children(objChild(idxObj))
                        end %if
                        if any(strcmp(methodList,'set_parent'))
                            %assign this instance to the parent property of the child
                            set_parent(objChild(idxObj),this)
                        end %if
                    end %if
                elseif iscell(this.(propNames{idxProp})) %cell array of class objects?
                    for idxCell = 1:numel(this.(propNames{idxProp}))
                        if isobject(this.(propNames{idxProp}){idxCell}) %check for class object
                            objChild = this.(propNames{idxProp}){idxCell};
                            
                            for idxObj = 1:numel(objChild)
                                classInfo = metaclass(objChild(idxObj));
                                methodList = {classInfo.MethodList.Name};
                                if any(strcmp(methodList,'set_children'))
                                    %invoke grand-child search (chain-search)
                                    set_children(objChild(idxObj))
                                end %if
                                if any(strcmp(methodList,'set_parent'))
                                    %assign this instance to the parent property of the child
                                    set_parent(objChild(idxObj),this)
                                end %if
                            end %if
                        end %if
                    end %for
                end %if
            end %for
        end %fun
        
        %%
        function display_image(this)
            %update slider
            if this.NumFrames == 1
                set(this.hImageInfoPanel.PlayButton,...
                    'Enable', 'off')
                set(this.hImageInfoPanel.Slider,...
                    'Enable', 'off')
            else
                set(this.hImageInfoPanel.PlayButton,...
                    'Enable', 'on')
                set(this.hImageInfoPanel.Slider,...
                    'Enable', 'on',...
                    'Max', this.NumFrames,...
                    'Value', this.Frame,....
                    'SliderStep', [1 10]./(this.NumFrames-1))
            end %if
            set(this.hImageInfoPanel.FramePosText,...
                'String', sprintf(' %.0f/%.0f',this.Frame,this.NumFrames))
            
            if this.objTimestamp.HasTimestamp
                update_timestamp(this.objTimestamp)
            end %if
            
            cellfun(@(x)update_intensity_data(x.objContrastSettings,x.Imagedata),...
                this.hImChannel(~cellfun('isempty',this.hImChannel)),'Un',0);
            if ishandle(this.objContrastSettings.hFig)
                cellfun(@(x)plot_intensity_data(x.objContrastSettings),...
                    this.hImChannel(~cellfun('isempty',this.hImChannel)),'Un',0);
            end %if
            
            if ishandle(this.hImageFig)
                if ishandle(this.hImageZoomFig)
                    update_zoom_tool(this)
                else
                    set(this.hImage,'CData',this.Imagedata)
                end %if
            end %if
        end %this
        function initialize_visualization(this)
            this.Frame = 1;
            
            %check if image data is contained
            if this.DataCompMode == 0
                waitfor(errordlg(sprintf('Composite/%s \ncontains no data to show',...
                    this.Name),'','modal'))
            elseif any(this.DataCompMode == [1 2 5 6 7 8 9 10])
                %send signal to all image children to go to specified frame
                cellfun(@(x)show_frame(x,this.Frame),...
                    this.hImChannel(~cellfun('isempty',this.hImChannel)));
                [this.Imagedata this.ActExp] = construct_frame(this);
                
                initialize_image_visualization(this)
                
                %check for cluster/trajectory data
                if any(this.DataCompMode == [6 7 8 9 10])
                    if ~isempty(this.hClusterChannel)
                    end %if
                    if ~isempty(this.hTrajChannel)
                        for idxTrajChannel = 1:numel(this.hTrajChannel)
                            this.hTrajChannel{idxTrajChannel}.hImageAx = this.hImageAx;
                            construct_entities(this.hTrajChannel{idxTrajChannel})
                            show_frame(this.hTrajChannel{idxTrajChannel},this.Frame);
                            adjust_traj_exp(this.hTrajChannel{idxTrajChannel},this.ActExp,this.FieldOfView(1:2))
                        end %for
                    end %if
                end %if
            elseif any(this.DataCompMode == [3 4])
                this.ActExp = 1;
                this.Imagedata = zeros(this.FieldOfView(6),...
                    this.FieldOfView(5));
                initialize_image_visualization(this)
                
                if ~isempty(this.hTrajChannel)
                    for idxTrajChannel = 1:numel(this.hTrajChannel)
                        this.hTrajChannel{idxTrajChannel}.hImageAx = this.hImageAx;
                        construct_entities(this.hTrajChannel{idxTrajChannel})
                        show_frame(this.hTrajChannel{idxTrajChannel},this.Frame);
                        adjust_traj_exp(this.hTrajChannel{idxTrajChannel},this.ActExp,this.FieldOfView(1:2))
                    end %for
                end %if
            end %if
            if ishandle(this.hImageFig)
                set(this.hImageFig,'Visible','on')
            end %if
        end %fun
        function initialize_image_visualization(this)
            figPos = set_figure_position(...
                this.FieldOfView(5)/this.FieldOfView(6),0.7,'center');
            
            this.hImageFig = figure(...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Name', this.Name,...
                'Units', 'pixels',...
                'Position', figPos+[0 -10 0 20],...
                'WindowKeypressFcn', @keyboard_actions,...
                'Renderer','zbuffer',...
                'IntegerHandle','off',...
                'Visible','off',...
                'CloseRequestFcn',@(src,evnt)close_object(this));
            
            hPanel = ...
                uipanel(...
                'Parent', this.hImageFig,...
                'Units','pixels',...
                'Position', [1 1 figPos(3) 20],...
                'HitTest', 'off');
            
            icon = getappdata(0,'icon');
            hPlayButton = ...
                uicontrol(...
                'Parent', hPanel,...
                'Style', 'togglebutton',...
                'Units','pixels',...
                'Position', [0 0 18 20],...
                'String', '',...
                'CData', icon.('Playback'),...
                'Callback', @(src,evnt)playback_frames(this,src));
            
            hSlider = ...
                uicontrol(...
                'Parent', hPanel,...
                'Style', 'slider',...
                'Units', 'pixels',...
                'Position', [18 0 0.35*(figPos(3)-18) 20],...
                'Min', 1,...
                'Max', 2,...
                'Value', 1,....
                'SliderStep', [1 1]);
            addlistener(hSlider,'ContinuousValueChange',...
                @(src,event)show_frame(this,src));
            
            hFramePosPanel = ...
                uipanel(...
                'Parent', hPanel,...
                'Units','pixels',...
                'Position', [18+0.35*(figPos(3)-18) 1 ...
                0.5*figPos(3)-(18+0.35*(figPos(3)-18)) 20],...
                'BorderType','etchedout',...
                'HitTest', 'off');
            
            hFramePosText = ...
                uicontrol(...
                'Parent', hFramePosPanel,...
                'Style', 'text',...
                'Units','normalized',...
                'Position', [0 0 1 1],...
                'FontSize', 12,...
                'FontUnits','normalized',...
                'HorizontalAlignment','center');
            
            hInfoTextPanel = ...
                uipanel(...
                'Parent', hPanel,...
                'Units','pixels',...
                'Position', [0.5*figPos(3) 0 0.35*figPos(3) 20],...
                'BorderType','etchedout',...
                'HitTest', 'off');
            
            hInfoText = ...
                uicontrol(...
                'Parent', hInfoTextPanel,...
                'Style', 'text',...
                'Units','normalized',...
                'Position', [0 0 1 1],...
                'FontSize', 12,...
                'FontUnits','normalized',...
                'HorizontalAlignment','center');
            
            hPixelInfoPanel = ...
                uipanel(...
                'Parent', hPanel,...
                'Units','pixels',...
                'Position', [0.85*figPos(3) 0 0.15*figPos(3) 20],...
                'BorderType','etchedout',...
                'HitTest', 'off');
            
            this.hImageInfoPanel = struct(...
                'Panel', hPanel,...
                'PlayButton', hPlayButton,...
                'Slider', hSlider,...
                'FramePosPanel', hFramePosPanel,...
                'FramePosText', hFramePosText,...
                'InfoTextPanel',hInfoTextPanel,...
                'InfoText', hInfoText,...
                'PixelInfoPanel',hPixelInfoPanel);
            
            %update slider
            if this.NumFrames == 1
                set(hPlayButton, 'Enable', 'off')
                set(hSlider, 'Enable', 'off')
            else
                set(hPlayButton, 'Enable', 'on')
                set(hSlider,...
                    'Enable', 'on',...
                    'Max', this.NumFrames,...
                    'Value', this.Frame,....
                    'SliderStep', [1 10]./(this.NumFrames-1))
            end %if
            set(hFramePosText,...
                'String', sprintf('%.0f/%.0f',this.Frame,this.NumFrames))
            
            this.hImagePlotPanel = ...
                uipanel(...
                'BackgroundColor', this.FamilyColor,...
                'Parent', this.hImageFig,...
                'Units','pixels',...
                'Position', [1 20 figPos(3) figPos(4)],...
                'HitTest', 'off');
            set(this.hImagePlotPanel, 'Units','normalized')
            
            this.hImageAx = ...
                axes(...
                'Parent', this.hImagePlotPanel,...
                'Units','normalized',...
                'Position', [0 0 1 1],...
                'NextPlot','add',...
                'HitTest', 'off');
            
            construct_image_toolbar(this) %subclass specific
            construct_image_contextmenu(this)
            
            this.hImage = imshow(this.Imagedata, ...
                'Colormap',this.objColormap.Colormapping, ...
                'Parent', this.hImageAx);
            
            set(this.hImage,  'HitTest', 'off')
            
            hPixelInfo = impixelinfoval(hPixelInfoPanel,this.hImage);
            set(hPixelInfo,...
                'Parent', hPixelInfoPanel,...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'FontSize',12,...
                'HorizontalAlignment','center')
            
            this.hImageScrollpanel = imscrollpanel(this.hImagePlotPanel,this.hImage);
            api = iptgetapi(this.hImageScrollpanel);
            api.setMagnification(0.95*api.findFitMag())
            set([this.hImageScrollpanel; ...
                allchild(this.hImageScrollpanel)], 'HitTest', 'off')
            
            set(this.hImageFig,'ResizeFcn', ...
                @(src,evnt)resize_frame_axes(this))
            
            restore_image_assecoirs(this)
        end %fun
        function construct_image_toolbar(this)
            hToolbar = uitoolbar(...
                'Parent',this.hImageFig);
            icon = getappdata(0,'icon');
            hSaveImage = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('Save_Image'),...
                'TooltipString', this.ToolTips.Toolbar.SaveImage,...
                'ClickedCallback', @(src,evnt)save_image(this));
            hSaveMovie = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Save_Movie'),...
                'TooltipString', this.ToolTips.Toolbar.SaveMovie,...
                'ClickedCallback', @(src,evnt)save_movie(this));
            hSaveFig = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Save_Figure'),...
                'TooltipString', this.ToolTips.Toolbar.SaveFigure,...
                'ClickedCallback', @(src,evnt)print_image(this.hImageAx,...
                this.objColormap.Colormapping,this.objContrastSettings.IntLimits));
            hChannelButton(1) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Red'),...
                'TooltipString', this.ToolTips.Toolbar.Channel,...
                'Separator','on');
            if ~isempty(this.hImChannel{1})
                set(hChannelButton(1),...
                    'ClickedCallback', @(src,evnt)select_data_channel(this,src,this.hImChannel{1}))
            end %if
            hChannelButton(2) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Green'),...
                'TooltipString', this.ToolTips.Toolbar.Channel);
            if ~isempty(this.hImChannel{2})
                set(hChannelButton(2),...
                    'ClickedCallback', @(src,evnt)select_data_channel(this,src,this.hImChannel{2}))
            end %if
            hChannelButton(3) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Blue'),...
                'TooltipString', this.ToolTips.Toolbar.Channel);
            if ~isempty(this.hImChannel{3})
                set(hChannelButton(3),...
                    'ClickedCallback', @(src,evnt)select_data_channel(this,src,this.hImChannel{3}))
            end %if
            hChannelButton(4) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Gray'),...
                'TooltipString', this.ToolTips.Toolbar.Channel);
            if ~isempty(this.hImChannel{4})
                set(hChannelButton(4),...
                    'ClickedCallback', @(src,evnt)select_data_channel(this,src,this.hImChannel{4}))
            end %if
            hChannelButton(5) = ...
                uitogglesplittool(...
                'Parent',hToolbar,...
                'CData', nan(16,16,3),...
                'TooltipString', this.ToolTips.Toolbar.Channel);
            pause(0.05)
            jBin = get(hChannelButton(5),'JavaContainer');
            pause(0.05)
            this.jClusterMenu = get(jBin,'MenuComponent');
            hChannelButton(6) = ...
                uitogglesplittool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Traj'),...
                'TooltipString', this.ToolTips.Toolbar.Channel);
            pause(0.05)
            jBin = get(hChannelButton(6),'JavaContainer');
            pause(0.05)
            this.jTrajMenu = get(jBin,'MenuComponent');
            if ~isempty(this.hTrajChannel)
                numTraj = numel(this.hTrajChannel);
                for trajIdx = 1:numTraj
                    jOption = this.jTrajMenu.add(this.hTrajChannel{trajIdx}.Name);
                    set(jOption, 'ActionPerformedCallback', ...
                        @(src,evnt)select_traj_channel(this,...
                        hChannelButton(6),this.hTrajChannel{trajIdx}));
                end %for
                set(hChannelButton(6),...
                    'ClickedCallback', @(src,evnt)select_data_channel(...
                    this,src,this.hSelectedTraj))
            end %if
            set(hChannelButton(...
                [cellfun('isempty',...
                [this.hImChannel]),...
                isempty(this.hClusterChannel),...
                isempty(this.hTrajChannel)]),...
                'Enable','off')
            hDispMan = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Visualization_2D'),...
                'TooltipString', this.ToolTips.Toolbar.DisplayManager,...
                'Enable','off');
            if this.DataCompMode == 2
                hCoLocMan = ...
                    uipushtool(...
                    'Parent',hToolbar,...
                    'CData', icon.('Co_Localization'),...
                    'ClickedCallback', @(src,evnt)set_parameter(this.objCoLocSettings),...
                    'Separator','on');
                
                uipushtool(...
                    'Parent',hToolbar,...
                    'CData', rand(16,16,3),...
                    'ClickedCallback', @(src,evnt)set_parameter(this.objPICCS),...
                    'Separator','on');
            end %if
            this.hImageToolbar = struct(...
                'Toolbar', hToolbar,...
                'SaveImage', hSaveImage,...
                'SaveMovie', hSaveMovie,...
                'SaveFigure', hSaveFig,...
                'Channel', hChannelButton,...
                'DisplayManager', hDispMan);
        end %fun
        function construct_image_contextmenu(this)
            %construct associated context menu
            hContextmenu = uicontextmenu(...
                'Parent',this.hImageFig);
            %%
            hMenuScalebar = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Scalebar');
            hMenuScalebarActive = ...
                uimenu(...
                'Parent', hMenuScalebar,...
                'Label', 'Activate Bar',...
                'Callback', @(src,evnt)initialize_scalebar(this.objScalebar,src));
            if this.objScalebar.HasScalebar
                set(hMenuScalebarActive,'Checked','on')
            else
                set(hMenuScalebarActive,'Checked','off')
            end %if
            hMenuLabelState = ...
                uimenu(hMenuScalebar,...
                'Label', 'Show Label',...
                'Callback', @(src,evnt)change_labelstate(this.objScalebar,src));
            if this.objScalebar.UseLabel
                set(hMenuLabelState,'Checked','on')
            else
                set(hMenuLabelState,'Checked','off')
            end %if
            uimenu(hMenuScalebar,...
                'Label', 'Set Scale',...
                'Separator','on',...
                'Callback', @(src,evnt)change_scale(this.objScalebar));
            hMenuUnit = ...
                uimenu(hMenuScalebar,...
                'Label', 'Set Unit');
            uimenu(hMenuUnit,...
                'Label', 'nm',...
                'Callback', @(src,evnt)change_units(this.objScalebar,src));
            uimenu(hMenuUnit,...
                'Label', 'µm',...
                'Callback', @(src,evnt)change_units(this.objScalebar,src));
            uimenu(hMenuUnit,...
                'Label', 'mm',...
                'Callback', @(src,evnt)change_units(this.objScalebar,src));
            uimenu(hMenuUnit,...
                'Label', 'cm',...
                'Callback', @(src,evnt)change_units(this.objScalebar,src));
            uimenu(hMenuUnit,...
                'Label', 'px',...
                'Callback', @(src,evnt)change_units(this.objScalebar,src));
            set(findobj(hMenuUnit,'Label',this.objScalebar.Unit),'Checked','on')
            
            hMenuBarsize = ...
                uimenu(hMenuScalebar,...
                'Label', 'Set Barsize');
            for size = 4:2:20
                uimenu(hMenuBarsize,...
                    'Label', num2str(size),...
                    'Callback', @(src,evnt)change_barsize(this.objScalebar,src));
            end %for
            set(findobj(hMenuBarsize,'Label',num2str(this.objScalebar.BarSize)),'Checked','on')
            
            hMenuLabelsize = ...
                uimenu(hMenuScalebar,...
                'Label', 'Set Fontsize');
            for size = 24:2:58
                uimenu(hMenuLabelsize,...
                    'Label', num2str(size),...
                    'Callback', @(src,evnt)change_labelsize(this.objScalebar,src));
            end %for
            set(findobj(hMenuLabelsize,'Label',...
                num2str(this.objScalebar.FontSize)),'Checked','on')
            
            uimenu(hMenuScalebar,...
                'Label', 'Set Color',...
                'Callback', @(src,evnt)change_color(this.objScalebar));
            
            hMenuPosition = ...
                uimenu(hMenuScalebar,...
                'Label', 'Set Position');
            uimenu(hMenuPosition,...
                'Label', 'North-East',...
                'Callback', @(src,evnt)change_position(this.objScalebar,src));
            uimenu(hMenuPosition,...
                'Label', 'South-East',...
                'Callback', @(src,evnt)change_position(this.objScalebar,src));
            uimenu(hMenuPosition,...
                'Label', 'South-West',...
                'Callback', @(src,evnt)change_position(this.objScalebar,src));
            uimenu(hMenuPosition,...
                'Label', 'North-West',...
                'Callback', @(src,evnt)change_position(this.objScalebar,src));
            uimenu(hMenuPosition,...
                'Label', 'Free',...
                'Callback', @(src,evnt)create_dragable_frame(this.objScalebar,src));
            set(findobj(hMenuPosition,'Label',this.objScalebar.Position,...
                '-not', 'Label', 'Free'),'Checked','on')
            
            %%
            hMenuTimestamp = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Timestamp');
            hMenuTimestampActive = ...
                uimenu(...
                'Parent', hMenuTimestamp,...
                'Label', 'Activate',...
                'Callback', @(src,evnt)initialize_timestamp(this.objTimestamp,src));
            if this.objTimestamp.HasTimestamp
                set(hMenuTimestampActive,'Checked','on')
            else
                set(hMenuTimestampActive,'Checked','off')
            end %if
            uimenu(hMenuTimestamp,...
                'Label', 'Set Increment',...
                'Separator','on',...
                'Callback', @(src,evnt)set_increment(this.objTimestamp,src));
            hMenuUnit = ...
                uimenu(hMenuTimestamp,...
                'Label', 'Set Unit');
            uimenu(hMenuUnit,...
                'Label', 'µs',...
                'Callback', @(src,evnt)change_units(this.objTimestamp,src));
            uimenu(hMenuUnit,...
                'Label', 'ms',...
                'Callback', @(src,evnt)change_units(this.objTimestamp,src));
            uimenu(hMenuUnit,...
                'Label', 's',...
                'Callback', @(src,evnt)change_units(this.objTimestamp,src));
            uimenu(hMenuUnit,...
                'Label', 'min',...
                'Callback', @(src,evnt)change_units(this.objTimestamp,src));
            uimenu(hMenuUnit,...
                'Label', 'frame',...
                'Callback', @(src,evnt)change_units(this.objTimestamp,src));
            set(findobj(hMenuUnit,'Label',this.objTimestamp.Unit),'Checked','on')
            
            hMenuTimestampsize = ...
                uimenu(hMenuTimestamp,...
                'Label', 'Set Fontsize');
            for size = 24:2:58
                uimenu(hMenuTimestampsize,...
                    'Label', num2str(size),...
                    'Callback', @(src,evnt)change_timestampsize(this.objTimestamp,src));
            end %for
            set(findobj(hMenuTimestampsize,'Label',...
                num2str(this.objTimestamp.FontSize)),'Checked','on')
            
            uimenu(hMenuTimestamp,...
                'Label', 'Set Color',...
                'Callback', @(src,evnt)change_color(this.objTimestamp));
            
            hMenuPosition = ...
                uimenu(hMenuTimestamp,...
                'Label', 'Set Position');
            uimenu(hMenuPosition,...
                'Label', 'North-East',...
                'Callback', @(src,evnt)change_position(this.objTimestamp,src));
            uimenu(hMenuPosition,...
                'Label', 'South-East',...
                'Callback', @(src,evnt)change_position(this.objTimestamp,src));
            uimenu(hMenuPosition,...
                'Label', 'South-West',...
                'Callback', @(src,evnt)change_position(this.objTimestamp,src));
            uimenu(hMenuPosition,...
                'Label', 'North-West',...
                'Callback', @(src,evnt)change_position(this.objTimestamp,src));
            uimenu(hMenuPosition,...
                'Label', 'Free',...
                'Callback', @(src,evnt)create_dragable_frame(this.objTimestamp,src));
            set(findobj(hMenuPosition,'Label',this.objTimestamp.Position,...
                '-not', 'Label', 'Free'),'Checked','on')
            
            %%
            hMenuTextstamp = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Textstamp');
            hMenuTextstampActive = ...
                uimenu(...
                'Parent', hMenuTextstamp,...
                'Label', 'Activate',...
                'Callback', @(src,evnt)initialize_textstamp(this.objTextstamp,src));
            if this.objTextstamp.HasTextstamp
                set(hMenuTextstampActive,'Checked','on')
            else
                set(hMenuTextstampActive,'Checked','off')
            end %if
            uimenu(hMenuTextstamp,...
                'Label', 'Set Text',...
                'Separator','on',...
                'Callback', @(src,evnt)change_string(this.objTextstamp));
            hMenuTextstampsize = ...
                uimenu(hMenuTextstamp,...
                'Label', 'Set Fontsize');
            for size = 14:2:48
                uimenu(hMenuTextstampsize,...
                    'Label', num2str(size),...
                    'Callback', @(src,evnt)change_textstampsize(this.objTextstamp,src));
            end %for
            set(findobj(hMenuTextstampsize,'Label',...
                num2str(this.objTextstamp.FontSize)),'Checked','on')
            
            uimenu(hMenuTextstamp,...
                'Label', 'Set Color',...
                'Callback', @(src,evnt)change_color(this.objTextstamp));
            
            hMenuPosition = ...
                uimenu(hMenuTextstamp,...
                'Label', 'Set Position');
            uimenu(hMenuPosition,...
                'Label', 'North-East',...
                'Callback', @(src,evnt)change_position(this.objTextstamp,src));
            uimenu(hMenuPosition,...
                'Label', 'South-East',...
                'Callback', @(src,evnt)change_position(this.objTextstamp,src));
            uimenu(hMenuPosition,...
                'Label', 'South-West',...
                'Callback', @(src,evnt)change_position(this.objTextstamp,src));
            uimenu(hMenuPosition,...
                'Label', 'North-West',...
                'Callback', @(src,evnt)change_position(this.objTextstamp,src));
            uimenu(hMenuPosition,...
                'Label', 'Free',...
                'Callback', @(src,evnt)create_dragable_frame(this.objTextstamp,src));
            set(findobj(hMenuPosition,'Label',this.objTextstamp.Position,...
                '-not', 'Label', 'Free'),'Checked','on')
            
            %%
            hMenuColorbar = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Colorbar');
            %%
            hMenuGrid = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Grid');
            hMenuGridRectangular = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Uniform Rectangular',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            hMenuGridHexagon = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Uniform Hexagonal',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            if this.objGrid.UseGrid
                switch this.objGrid.GridMode
                    case 'Uniform Rectangular'
                        set(hMenuGridRectangular,'Checked','on')
                    case 'Uniform Hexagonal'
                        set(hMenuGridHexagon,'Checked','on')
                end %switch
            end %if
            uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Set Line Color',...
                'Separator','on',...
                'Callback', @(src,evnt)set_grid_line_color(this.objGrid));
            hMenuGridLineWidth = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Set Line Width');
            for size = 0.5:0.5:5
                uimenu(hMenuGridLineWidth,...
                    'Label', num2str(size),...
                    'Callback', @(src,evnt)set_grid_line_width(this.objGrid,src));
            end %for
            set(findobj(hMenuGridLineWidth,...
                'Label',num2str(this.objGrid.GridLineWidth)),...
                'Checked','on')
            
            %%
            hMenuContrast = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Contrast Tool',...
                'Separator','on',...
                'Callback', @(src,evnt)adjust_contrast(this.objContrastSettings));
            %%
            hMenuColormap = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Colormap Tool',...
                'Callback', @(src,evnt)adjust_colormap(this.objColormap));
            %%
            hMenuZoom = ...
                uimenu(...
                'Parent', hContextmenu,...
                'Label', 'Zoom Tool',...
                'Callback', @(src,evnt)open_zoom_tool(this));
            
            set(this.hImageFig,'UIContextmenu', hContextmenu)
            this.hImageContextmenu = struct(...
                'ContextMenu',hContextmenu,...
                'Scalebar', struct(...
                'ScalebarMenu',hMenuScalebar),...
                'Timestamp', struct(...
                'TimestampMenu', hMenuTimestamp),...
                'Textstamp', struct(...
                'TextstampMenu', hMenuTextstamp),...
                'Colorbar', struct(...
                'ColorbarMenu', hMenuColorbar),...
                'Grid', struct(...
                'GridMenu', hMenuGrid),...
                'Contrast', struct(...
                'ContrastMenu', hMenuContrast),...
                'Colormap', struct(...
                'ColormapMenu', hMenuColormap),...
                'Zoom', struct(...
                'ZoomMenu', hMenuZoom));
        end %fun
        function restore_image_assecoirs(this)
            if this.objRoi.HasRoi
                restore_roi(this.objRoi)
            end %if
            if this.objScalebar.HasScalebar
                if ishandle(this.objScalebar.hBar)
                    update_bar(this.objScalebar)
                else
                    %when image figure is created
                    construct_scalebar(this.objScalebar)
                end %if
            end %if
            if this.objTimestamp.HasTimestamp
                if ishandle(this.objTimestamp.hTimestamp)
                    update_timestamp(this.objTimestamp)
                else
                    construct_timestamp(this.objTimestamp)
                end %if
            end %if
            if this.objTextstamp.HasTextstamp
                if ishandle(this.objTextstamp.hTextstamp)
                    update_textstamp(this.objTextstamp)
                else
                    construct_textstamp(this.objTextstamp)
                end %if
            end %if
            if this.objGrid.UseGrid
                update_grid(this.objGrid)
            end %if
        end %fun
        
        function isOK = show_frame(this,input)
            %get specific frame
            if isa(input,'uicontrol') %(=slider)
                frame = round(get(input,'Value'));
            else
                frame = input;
            end
            
            %send signal to all children to go to specified frame
            isOK = all(cell2mat(cellfun(@(x)show_frame(x,frame),...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0)));
            
            if isOK
                this.Frame = frame;
                
                %check if image data exists
                if any(~cellfun('isempty',this.hImChannel))
                    [this.Imagedata actExp] = construct_frame(this);
                else
                    actExp = this.ActExp;
                end %if
                display_image(this)
                
                %check if expansion has changed
                if ~isempty(this.ActExp)
                    if this.ActExp ~= actExp
                        set(this.hImageAx,...
                            'Xlim', transform_orig_to_mag(...
                            this.FieldOfView([1 3]),actExp,this.FieldOfView(1)),...
                            'Ylim', transform_orig_to_mag(...
                            this.FieldOfView([2 4]),actExp,this.FieldOfView(2)))
                        restore_image_assecoirs(this)
                    end %if
                    %update
                    this.ActExp = actExp;
                end %if
            end %if
        end %fun
        function isOK = show_next_frame(this,loop)
            %get next frame
            if this.Frame < this.NumFrames
                frame = this.Frame + 1;
            else
                if loop
                    frame = 1;
                else
                    %do nothing
                end %if
            end %if
            
            isOK = show_frame(this,frame);
        end %fun
        function playback_frames(this,src)
            icon = getappdata(0,'icon');
            set(src,'CData', icon.('Pause'))
            while ishandle(this.hImageFig) && ...
                    get(src,'Value')
                %show next frame
                isOK = show_next_frame(this,1);
                if ~isOK
                    set(src,'Value', 0)
                end %if
                
                pause(0.05)
            end %while
            set(src,'CData', icon.('Playback'))
        end %fun
        
        function [frameOut,actExp] = construct_frame(this)
            this.RawImagedata = {};
            
            good = ~cellfun('isempty',this.hImChannel);
            for colorIdx = 4:-1:1
                if good(colorIdx) %(=channel is occupied)
                    imageData{colorIdx} = this.hImChannel{colorIdx}.Imagedata;
                    srcExp(colorIdx) = this.hImChannel{colorIdx}.ActExp;
                    intLimits{colorIdx} = this.hImChannel{colorIdx}.objContrastSettings.IntLimits;
                end %if
            end %for
            
            if numel(unique(srcExp(good))) == 1
                actExp = unique(srcExp(good));
                for colorIdx = 3:-1:1
                    if good(colorIdx) %(=color(rgb) channel is occupied)
                        this.RawImagedata{colorIdx} = imageData{colorIdx};
                        adjust_image_plane_contrast
                        frameOut(:,:,colorIdx) = imageData{colorIdx};
                    else
                        frameOut(:,:,colorIdx) = zeros(...
                            this.FieldOfView(6)*actExp,...
                            this.FieldOfView(5)*actExp);
                    end %if
                end %for
                colorIdx = 4;
                if good(colorIdx) %(=grey channel is occupied)
                    %check if image merge or only gray image is supplied
                    this.RawImagedata{colorIdx} = imageData{colorIdx};
                    adjust_image_plane_contrast
                    if any(good(1:3)) %(=grey + red,green,blue channel)
                        frameOut = max(0,min(1,0.5*frameOut + ...
                            repmat(0.5*imageData{colorIdx},[1 1 3])));
                    else %(=only grey)
                        frameOut = imageData{colorIdx};
                    end %if
                end %if
            else
                %determine maximum expansion
                actExp = max(srcExp);
                for colorIdx = 3:-1:1
                    if good(colorIdx) %(=color(rgb) channel is occupied)
                        if srcExp(colorIdx) == actExp
                            this.RawImagedata{colorIdx} = imageData{colorIdx};
                            adjust_image_plane_contrast
                            frameOut(:,:,colorIdx) = imageData{colorIdx};
                        else %(= smaller than max. expansion -> resize by interpolation)
                            imageData{colorIdx} = imresize(...
                                imageData{colorIdx},actExp/srcExp(colorIdx),...
                                'Method','nearest');
                            this.RawImagedata{colorIdx} = imageData{colorIdx};
                            adjust_image_plane_contrast
                            frameOut(:,:,colorIdx) = imageData{colorIdx};
                        end %if
                    else
                        frameOut(:,:,colorIdx) = zeros(...
                            this.FieldOfView(6)*actExp,...
                            this.FieldOfView(5)*actExp);
                    end %if
                end %for
                colorIdx = 4;
                if good(colorIdx) %(=grey channel is occupied)
                    if srcExp(colorIdx) == actExp
                        this.RawImagedata{colorIdx} = imageData{colorIdx};
                    else %(= smaller than max. expansion -> resize by interpolation)
                        imageData{colorIdx} = imresize(...
                            imageData{colorIdx},actExp/srcExp(colorIdx),...
                            'Method','nearest');
                        this.RawImagedata{colorIdx} = imageData{colorIdx};
                    end %if
                    adjust_image_plane_contrast
                    if any(good(1:3)) %(=grey + red,green,blue channel)
                        frameOut = max(0,min(1,0.5*frameOut + ...
                            repmat(0.5*imageData{colorIdx},[1 1 3])));
                    else %(=only grey)
                        frameOut = imageData{colorIdx};
                    end %if
                end %if
            end %if
            
            %check if expansion has changed
            if ~isempty(this.ActExp)
                if this.ActExp ~= actExp
                    %if there are trajectories, update to match new expansion
                    if ~isempty(this.hTrajChannel)
                        for idxTrajChannel = 1:numel(this.hTrajChannel)
                            adjust_traj_exp(this.hTrajChannel{idxTrajChannel},...
                                actExp,this.FieldOfView(1:2))
                        end %for
                    end %if
                end %if
            end %if
            
            function adjust_image_plane_contrast
                if isempty(intLimits{colorIdx})
                    imageData{colorIdx} = ...
                        normalize_image_range(imageData{colorIdx},[]);
                else
                    %adjust image data to match defined contrast
                    imageData{colorIdx} = min(1,max(0,...
                        (imageData{colorIdx}-intLimits{colorIdx}(1))/...
                        (intLimits{colorIdx}(2)-intLimits{colorIdx}(1))));
                end %if
            end %nested0
        end %fun
        function update_image_plane_contrast(this,srcObj,intLimits)
            %get image plane
            good = find(~cellfun('isempty',this.hImChannel));
            selection = good(cell2mat(cellfun(@(x) eq(srcObj,x), ...
                this.hImChannel(good), 'Un', 0)));
            
            if selection == 4 %(=grey channel selected)
                %check if other channels are occupied
                if numel(good) == 1 %(=only grey channel is occupied)
                    this.Imagedata = max(0,min(1,...
                        (this.RawImagedata{selection}-intLimits(1))/...
                        (intLimits(2)-intLimits(1))));
                else %(=grey + red,green,blue channel)
                    %reset image data (=0)
                    this.Imagedata = this.Imagedata*0;
                    
                    %adjust grey channel
                    imagePlane = max(0,min(1,...
                        (this.RawImagedata{selection}-intLimits(1))/...
                        (intLimits(2)-intLimits(1))));
                    
                    for colorIdx = good(good~=4) %(=color(rgb) channels occupied)
                        intLimits = ...
                            this.hImChannel{colorIdx}.objContrastSettings.IntLimits;
                        %adjust color channel
                        this.Imagedata(:,:,colorIdx) = ...
                            max(0,min(1,...
                            (this.RawImagedata{colorIdx}-intLimits(1))/...
                            (intLimits(2)-intLimits(1))));
                    end %for
                    
                    %merge channels
                    this.Imagedata = max(0,min(1,0.5*this.Imagedata + ...
                        repmat(0.5*imagePlane,[1 1 3])));
                end %if
            else %(=color(rgb) channel selected)
                %adjust image data to match defined contrast
                imagePlane = min(1,max(0,...
                    (this.RawImagedata{selection}-intLimits(1))/...
                    (intLimits(2)-intLimits(1))));
                
                if any(good == 4) %(=grey channel is occupied)
                    %adjust grey channel
                    intLimits = ...
                        this.hImChannel{4}.objContrastSettings.IntLimits;
                    greyPlane = max(0,min(1,...
                        (this.RawImagedata{4}-intLimits(1))/...
                        (intLimits(2)-intLimits(1))));
                    
                    %merge grey & color
                    imagePlane = 0.5*greyPlane+0.5*imagePlane;
                end %if
                
                %update image
                this.Imagedata(:,:,selection) = imagePlane;
            end %if
            
            %update frame
            set(this.hImage,'CData',this.Imagedata)
        end %fun
        
        function resize_frame_axes(this)
            figPos = getpixelposition(this.hImageFig);
            
            %adjust frame panels
            setpixelposition(this.hImagePlotPanel,[1 20 figPos(3) figPos(4)-20],1)
            api = iptgetapi(this.hImageScrollpanel);
            api.setMagnification(0.95*api.findFitMag())
            
            %adjust slider Panel
            setpixelposition(this.hImageInfoPanel.Panel,[1 1 figPos(3) 20],1)
            setpixelposition(this.hImageInfoPanel.PlayButton,[0 0 18 20],1)
            setpixelposition(this.hImageInfoPanel.Slider,[18 0 0.35*(figPos(3)-18) 20],1)
            setpixelposition(this.hImageInfoPanel.FramePosPanel,[18+0.35*(figPos(3)-18) 0 ...
                0.5*figPos(3)-(18+0.35*(figPos(3)-18)) 20],1)
            setpixelposition(this.hImageInfoPanel.InfoTextPanel,[0.5*figPos(3) 0 0.35*figPos(3) 20],1)
            setpixelposition(this.hImageInfoPanel.PixelInfoPanel,[0.85*figPos(3) 0 0.15*figPos(3) 20],1)
            
            if this.objScalebar.HasScalebar
                update_bar(this.objScalebar)
            end %if
            if this.objTimestamp.HasTimestamp
                update_timestamp(this.objTimestamp)
            end %if
            if this.objTextstamp.HasTextstamp
                update_textstamp(this.objTextstamp)
            end %if
        end %fun
        function open_zoom_tool(this)
            this.hImageZoomFig = imoverview(this.hImage);
            %remove toolbar and menubar
            delete(findall(this.hImageZoomFig, 'Type', 'uimenu'))
            hToolBar = findall(this.hImageZoomFig,'Type','uitoolbar');
            standardToggles = findall(hToolBar);
            delete(standardToggles(2))
            
            set(this.hImageZoomFig,...
                'Units', 'pixels',...
                'Position', set_figure_position(...
                this.FieldOfView(5)/this.FieldOfView(6),0.3,'north-west'),...
                'Resize', 'off',...
                'DockControls', 'off',...
                'Name', 'ZOOM TOOL',...
                'CloseRequestFcn', @(src,evnt)close_zoom_tool(this,src))
            
            %correct position for figure frame
            figPosition = get(this.hImageZoomFig,'Position');
            figFrame = get(this.hImageZoomFig,'OuterPosition')-figPosition;
            set(this.hImageZoomFig,...
                'Position', figPosition+[figFrame(3) -figFrame(4) 0 0])
            
            %hide image text
            if this.objScalebar.HasScalebar
                set(this.objScalebar.hBar,'Visible','off')
                if this.objScalebar.UseLabel
                    set(this.objScalebar.hLabel,'Visible','off')
                end %if
            end %if
            if this.objTimestamp.HasTimestamp
                set(this.objTimestamp.hTimestamp,'Visible','off')
            end %if
            if this.objTextstamp.HasTextstamp
                set(this.objTextstamp.hTextstamp,'Visible','off')
            end %if
            
            function close_zoom_tool(this,src)
                %reset magnification to 1x
                api = iptgetapi(this.hImageScrollpanel);
                api.setMagnification(0.95*api.findFitMag())
                delete(src)
                
                %unveil image text
                if this.objScalebar.HasScalebar
                    set(this.objScalebar.hBar,'Visible','on')
                    if this.objScalebar.UseLabel
                        set(this.objScalebar.hLabel,'Visible','on')
                    end %if
                end %if
                if this.objTimestamp.HasTimestamp
                    set(this.objTimestamp.hTimestamp,'Visible','on')
                end %if
                if this.objTextstamp.HasTextstamp
                    set(this.objTextstamp.hTextstamp,'Visible','on')
                end %if
            end %fun
        end %fun
        function update_zoom_tool(this)
            %get imscrollpanel application interface
            api = iptgetapi(this.hImageScrollpanel);
            
            oldLim = [get(this.hImageAx,'XLim') ...
                get(this.hImageAx,'YLim')];
            visRect = api.getVisibleImageRect();
            normVisCtrs = [visRect(1)+visRect(3)/2 ...
                visRect(2)+visRect(4)/2]./[oldLim(2) oldLim(4)];
            visMag = api.getMagnification();
            oldFitMag = api.findFitMag();
            
            api.replaceImage(this.Imagedata,...
                'PreserveView',1)
            %             set(this.hImage,'CData',this.Imagedata)
            
            newFitMag = api.findFitMag();
            newLim = [get(this.hImageAx,'XLim') ...
                get(this.hImageAx,'YLim')];
            api.setMagnificationAndCenter(visMag*(newFitMag/oldFitMag),...
                normVisCtrs(1)*newLim(2),normVisCtrs(2)*newLim(4))
        end %fun
        
        function save_image(this)
            %written by
            %C.P.Richter
            %Division of Biophysics / Group J.Piehler
            %University of Osnabrueck
            
            if any(this.DataCompMode == 1:5)
                answer = questdlg('Image Type?','','Raw','Screenshot','Screenshot');
            else
                answer = 'Screenshot';
            end %if
            
            switch answer
                case ''
                    return
                case 'Raw'
                    scrShot.cdata = this.Imagedata;
                case 'Screenshot'
                    %make screenshot
                    if ishandle(this.hImageZoomFig)
                        hList = get(this.hImageScrollpanel,'Children');
                        set(hList(2:4),'Visible','off')
                        structfun(@(x)set(x,'Visible','off'),this.hImageInfoPanel)
                        
                        position = getpixelposition(this.hImageFig,1);
                    else
                        position = getpixelposition(this.hImageAx,1);
                    end %if
                    
                    try
                        scrShot = getframe(this.hImageAx,[2 2 position(3:4)-1]);
                    catch errMsg
                        if strcmp(errMsg.identifier,...
                                'MATLAB:capturescreen:RectangleMustBeAtLeastPartiallyOnScreen') ||...
                                strcmp(errMsg.identifier,...
                                'matlab:writeVideo:invalidDimensions') ||...
                                strcmp(errMsg.identifier,...
                                'MATLAB:audiovideo:VideoWriter:invalidDimensions')
                            figPos = set_figure_position(...
                                this.FieldOfView(5)/this.FieldOfView(6),1,'center')+[0 -10 0 20];
                            set(this.hImageFig,'Position', figPos)
                        else
                            rethrow(errMsg)
                        end %if
                    end %try
            end %switch
            
            [filename,pathname,isOK] = uiputfile(...
                {'.tif','Uncompressed Tagged Image File Format (*.tif)'} ,'Save to', ...
                [getappdata(0,'searchPath') this.Name]);
            if isOK
                setappdata(0,'searchPath',pathname)
                imwrite(scrShot.cdata,[pathname filename],...
                    'Compression','none',...
                    'Description',sprintf('SLIMfast %s',this.Parent.Build))
                
                waitfor(msgbox(sprintf(...
                    'Image successfully saved to:\n%s',[pathname filename]),'modal'))
            end %if
            
            if ishandle(this.hImageZoomFig)
                set(hList(2:4),'Visible','on')
                structfun(@(x)set(x,'Visible','on'),this.hImageInfoPanel)
            end %if
        end %fun
        function save_movie(this)
            if this.NumFrames < 2
                waitfor(errordlg('At least 2 Frames are needed to create a Movie','','modal'))
                return
            end %if
            
            [filename,pathname,isOK] =...
                uiputfile({...
                '*.avi','Motion JPEG AVI (*.avi)';...
                '*.mp4','MPEG-4 File H.246 (*.mp4)'},...
                'Save to',[getappdata(0,'searchPath') this.Name]);
            if ~isOK
                return
            end %if
            
            setappdata(0,'searchPath',pathname)
            
            hProgressbar = ClassProgressbar(...
                {'Movie Export...'},...
                'IsInterruptable',true);
            
            %create movie file
            movie = VideoWriter(...
                [pathname filename],...
                this.MovProfiles{isOK});
            movie.FrameRate = 32;
            open(movie);
            
            %initial frame
            isOK = show_frame(this,1);
            
            if ishandle(this.hImageZoomFig)
                api = iptgetapi(this.hImageScrollpanel);
                visRect = api.getVisibleLocation();
                hList = get(this.hImageScrollpanel,'Children');
                set(hList(2:4),'Visible','off')
                structfun(@(x)set(x,'Visible','off'),this.hImageInfoPanel)
                position = getpixelposition(this.hImageFig,1);
            else
                position = getpixelposition(this.hImageAx,1);
            end %if
            
            try
                drawnow
                figPos = getpixelposition(this.hImageFig);
                writeVideo(movie,getframe(this.hImageAx,[2 2 position(3:4)-1]));
            catch errMsg
                %check if figure is inside first screen
                if strcmp(errMsg.identifier,...
                        'MATLAB:capturescreen:RectangleMustBeAtLeastPartiallyOnScreen') ||...
                        strcmp(errMsg.identifier,...
                        'matlab:writeVideo:invalidDimensions') ||...
                        strcmp(errMsg.identifier,...
                        'MATLAB:audiovideo:VideoWriter:invalidDimensions')
                    figPos = set_figure_position(...
                        this.FieldOfView(5)/this.FieldOfView(6),1,'center')+[0 -10 0 20];
                    set(this.hImageFig,'Position', figPos)
                else %(=no known solution)
                    rethrow(errMsg)
                end %if
            end %try
            
            for frame = 2:this.NumFrames
                isOK = show_next_frame(this,0);
                
                %temporarly disable user controls
                if ishandle(this.hImageZoomFig)
                    api.setVisibleLocation(visRect);
                    set(hList(2:4),'Visible','off')
                end %if
                
                try
                    drawnow
                    writeVideo(movie,getframe(this.hImageAx,[2 2 position(3:4)-1]));
                catch errMsg
                    %check if figure is inside first screen
                    if strcmp(errMsg.identifier,...
                            'MATLAB:capturescreen:RectangleMustBeAtLeastPartiallyOnScreen') ||...
                            strcmp(errMsg.identifier,...
                            'matlab:writeVideo:invalidDimensions') ||...
                            strcmp(errMsg.identifier,...
                            'MATLAB:audiovideo:VideoWriter:invalidDimensions')
                        set(this.hImageFig,'Position', figPos)
                    else %(=no known solution)
                        rethrow(errMsg)
                    end %if
                end %try
                
                %check if process is to be interrupted
                if check_for_process_interruption(hProgressbar)
                    break
                else
                    update_progressbar(hProgressbar,...
                        {frame/this.NumFrames})
                end %if
            end %for
            
            %close movie
            close(movie);
            close_progressbar(hProgressbar)
            
            %activate user controls
            if ishandle(this.hImageZoomFig)
                set(hList(2:4),'Visible','on')
                structfun(@(x)set(x,'Visible','on'),this.hImageInfoPanel)
            end %if
            
            waitfor(msgbox(sprintf(...
                'Movie successfully saved to:\n%s',[pathname filename]),'modal'))
        end %fun
        
        %%
        function select_data_channel(this,src,dataObj)
            if ~isempty(dataObj)
                switch get(src,'State')
                    case 'on'
                        set(this.hImageToolbar.Channel(...
                            ~eq(this.hImageToolbar.Channel,src)),'State','off')
                        set(this.hImageToolbar.DisplayManager,...
                            'ClickedCallback', @(src,evnt)set_parameter(dataObj.objDisplaySettings),...
                            'Enable','on')
                    case 'off'
                        set(this.hImageToolbar.DisplayManager,...
                            'ClickedCallback','',...
                            'Enable','off')
                        if ishandle(dataObj.objDisplaySettings.hFig)
                            delete(dataObj.objDisplaySettings.hFig)
                        end %if
                end %switch
            else
                set(src,'State','off')
                waitfor(errordlg('No Channel selected','','modal'))
            end %if
        end %fun
        function select_traj_channel(this,src,dataObj)
            this.hSelectedTraj = dataObj;
            if strcmp(get(src,'State'),'on')
                select_data_channel(this,src,dataObj)
            end %if
        end %fun
        
        function determine_composite_mode(this)
            %determine composite case
            numClasses = this.NumClasses;
            if sum(numClasses) == 0
                %no data
                this.DataCompMode = 0;
                this.FieldOfView = [];
                this.Px2nm = [];
                this.Frame2msec = [];
                this.Count2photon = [];
            else
                if ~any(numClasses([2 3 4]) > 0)
                    %multiple raw
                    this.DataCompMode = 1;
                elseif ~any(numClasses([1 3 4]) > 0)
                    %multiple localization
                    this.DataCompMode = 2;
                elseif ~any(numClasses([1 2 4]) > 0)
                    %multiple cluster
                    this.DataCompMode = 3;
                elseif ~any(numClasses([1 2 3]) > 0)
                    %multiple trajectory
                    this.DataCompMode = 4;
                elseif numClasses(1) > 0 && ...
                        numClasses(2) > 0 && ...
                        ~any(numClasses([3 4]) > 0)
                    %raw & localization
                    this.DataCompMode = 5;
                elseif numClasses(1) > 0 && ...
                        numClasses(3) > 0 && ...
                        ~any(numClasses([2 4]) > 0)
                    %raw & cluster
                    this.DataCompMode = 6;
                elseif numClasses(1) > 0 && ...
                        numClasses(4) > 0 && ...
                        ~any(numClasses([2 3]) > 0)
                    %raw & trajectory
                    this.DataCompMode = 7;
                elseif numClasses(2) > 0 && ...
                        numClasses(3) > 0 && ...
                        ~any(numClasses([1 4]) > 0)
                    %localization & cluster
                    this.DataCompMode = 8;
                elseif numClasses(2) > 0 && ...
                        numClasses(4) > 0 && ...
                        ~any(numClasses([1 3]) > 0)
                    %localization & trajectory
                    this.DataCompMode = 9;
                elseif numClasses(1) > 0 && ...
                        numClasses(2) > 0 && ...
                        numClasses(4) > 0 && ...
                        ~numClasses([3])
                    %raw & localization & trajectory
                    this.DataCompMode = 10;
                end %if
            end %if
        end %fun
        
        %         function adjust_traj_exp(this,newExp,oldExp)
        %             hLine = cellfun(@(x)cell2mat(x.hLine),this.hTrajChannel','Un',0);
        %             hSingleLine = vertcat(hLine{:});
        %
        %             xData{:} = get(hSingleLine,'XData');
        %             xData = cellfun(@(x)transform_mag_to_mag(x,...
        %                 newExp,oldExp,this.FieldOfView(1)),xData,'Un',0);
        %             yData = get(hSingleLine,'YData');
        %             yData = cellfun(@(x)transform_mag_to_mag(x,...
        %                 newExp,oldExp,this.FieldOfView(2)),yData,'Un',0);
        %             set(hSingleLine,{'XData' 'YData'},...
        %                 [xData yData])
        %             end %if
        %         end %fun
        
        %%
        function copy_data_to_composite(this,objData,channelName)
            %check if transfer is to color channel
            if any(strcmp(channelName,this.ChannelNames(1:4)))
                %check if source data is allowed to log into color channel
                %(contains image data)
                if any(strcmp(class(objData),...
                        {'ClassRaw','ClassLocalization'}))
                    %check if image dimensions match
                    if check_image_dimensions(this,objData)
                        if check_image_units(this,objData)
                            this.FieldOfView = objData.FieldOfView;
                            this.Px2nm = objData.Px2nm;
                            this.Frame2msec = objData.Frame2msec;
                            this.Count2photon = objData.Count2photon;
                            
                            %generate deep copy of data object
                            objDataClone = clone_object(objData,this);
                            objDataClone.Name = [objDataClone.Name ' (Cloned)'];
                            
                            channelIdx = find(strcmp(channelName,...
                                this.ChannelNames(1:4)));
                            if ~isempty(this.hImChannel{channelIdx})
                                %clear respective color channel
                                delete_object(this.hImChannel{channelIdx})
                            end %if
                            this.hImChannel{channelIdx} = objDataClone;
                            
                            %construct leaf and update Project Explorer
                            objProject = this.Parent;
                            objSLIMfast = objProject.Parent;
                            add_composite_channel_leaf(...
                                objSLIMfast.objProjectExplorer,...
                                objDataClone,channelIdx)
                        else
                            waitfor(errordlg('Images have different Conversion Units','','modal'))
                        end %if
                    else
                        waitfor(errordlg('Images have different Dimensions','','modal'))
                    end %if
                else
                    waitfor(errordlg('Only Raw/Localization Data can log into Image Channels','','modal'))
                end %if
                %check if transfer is to cluster channel
            elseif strcmp(channelName,'Cluster')
                %check if transfer is to trajectory channel
            elseif strcmp(channelName,'Track')
                %check if source data is allowed to log into trajectory channel
                %(contains trajectory data)
                if strcmp(class(objData),'ClassTrajectory')
                    %check if image dimensions match
                    if check_image_dimensions(this,objData)
                        if check_image_units(this,objData)
                            this.FieldOfView = objData.FieldOfView;
                            this.Px2nm = objData.Px2nm;
                            this.Frame2msec = objData.Frame2msec;
                            this.Count2photon = objData.Count2photon;
                            
                            %generate deep copy of data object
                            objDataClone = clone_object(objData,this);
                            objDataClone.Name = [objDataClone.Name ' (Cloned)'];
                            %                             for trajIdx = 1:objDataClone.NumIndividual
                            %                                 objDataClone.objIndividual(trajIdx) = copy(objData.objIndividual(trajIdx));
                            %                                 objDataClone.objIndividual(trajIdx).Parent = objDataClone;
                            %                             end %for
                            
                            this.hTrajChannel = [this.hTrajChannel {objDataClone}];
                            
                            %construct leaf and update Project Explorer
                            objProject = this.Parent;
                            objSLIMfast = objProject.Parent;
                            add_composite_channel_leaf(...
                                objSLIMfast.objProjectExplorer,objDataClone,6)
                        else
                            waitfor(errordlg('Images have different Conversion Units','','modal'))
                        end %if
                    else
                        waitfor(errordlg('Images have different Dimensions','','modal'))
                    end %if
                else
                    waitfor(errordlg('Only Trajectory Data can log into Trajectory Channel','','modal'))
                end %if
            else
                return
            end
            determine_composite_mode(this)
        end %fun
        function remove_data_from_composite(this,objData)
            %check type of data (image vs. trajectory)
            switch class(objData)
                case 'ClassTrajectory';
                    %find respective trajectory data
                    idxBad = cell2mat(cellfun(...
                        @(x)eq(x,objData),this.hTrajChannel,'Un',0));
                    if numel(this.hTrajChannel) == 1
                        this.hTrajChannel = {};
                    else
                        this.hTrajChannel(idxBad) = [];
                    end %if
                    
                    %                     this.hChannelNodes{6} = [];
                case 'ClassCluster'
                otherwise
                    %find respective color channel
                    idxEmpty = cellfun('isempty',this.hImChannel);
                    idxBad = false(1,4);
                    idxBad(~idxEmpty) = cell2mat(cellfun(...
                        @(x)eq(x,objData),this.hImChannel(~idxEmpty),'Un',0));
                    this.hImChannel{idxBad} = [];
            end %switch
            
            %remove respective data object
            delete_object(objData)
            
            %update composite mode
            determine_composite_mode(this)
        end %fun
        
        function flag = check_image_dimensions(this,srcObj)
            if isempty(this.FieldOfView)
                flag = true;
            elseif size(unique([this.FieldOfView;...
                    srcObj.FieldOfView],'rows'),1) == 1
                flag = true;
            else
                flag = false;
            end %if
        end %fun
        function flag = check_image_units(this,srcObj)
            %check px2nm
            if isempty(this.Px2nm)
                flag(1) = true;
            elseif eq(this.Px2nm,srcObj.Px2nm)
                flag(1) = true;
            else
                flag(1) = false;
            end %if
            
            %check frames2msec
            if isempty(this.Frame2msec)
                flag(2) = true;
            elseif eq(this.Frame2msec,srcObj.Frame2msec)
                flag(2) = true;
            else
                flag(2) = false;
            end %if
            
            %check counts2photon
            %             if isempty(this.Count2photon)
            %                 flag(3) = true;
            %             elseif eq(this.Count2photon,srcObj.Count2photon)
            %                 flag(3) = true;
            %             else
            %                 flag(3) = false;
            %             end %if
            
            flag = all(flag);
        end %fun
        
        function imageframesincluded = get_image_frames_covered(this,frame)
            imageframesincluded = ...
                cellfun(@(x)get_image_frames_covered(x,frame),...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0);
            imageframesincluded = unique([imageframesincluded{:}]);
        end %fun
        
        %%
        function objCoLoc = find_co_localization_events(this)
            %close colocalization manager
            if ishandle(this.objCoLocSettings.hFig)
                delete(this.objCoLocSettings.hFig)
            end %if
            
            %get indices of source data
            dataIdx = find(cell2mat(cellfun(@(x)strcmp(class(x),...
                'ClassLocalization'),this.hImChannel,'Un',0)));
            
            for frame = reshape(intersect(this.hImChannel{dataIdx(1)}.Data.Time,...
                    this.hImChannel{dataIdx(2)}.Data.Time),1,[])
                
                idxCh1 = find(this.hImChannel{dataIdx(1)}.Data.Time == frame);
                numCh1 = numel(idxCh1);
                idxCh2 = find(this.hImChannel{dataIdx(2)}.Data.Time == frame);
                numCh2 = numel(idxCh2);
                
                if this.objCoLocSettings.UseFixedDist
                    distThresh = this.objCoLocSettings.DistThresh/...
                        this.hImChannel{dataIdx(1)}.Px2nm; %[px]
                else
                    [precCh1 precCh2] = ndgrid(...
                        this.hImChannel{dataIdx(1)}.Data.Precision(idxCh1).^2/...
                        this.hImChannel{dataIdx(1)}.Px2nm.^2,...
                        this.hImChannel{dataIdx(2)}.Data.Precision(idxCh2).^2/...
                        this.hImChannel{dataIdx(2)}.Px2nm.^2);
                    distThresh = raylinv(1-10^this.objCoLocSettings.ProbMiss,sqrt(precCh1+precCh2)); %fixed 171120
                    %                     distThresh = sqrt(-log(10^this.objCoLocSettings.ProbMiss)*4*(precCh1+precCh2)); %[px]
                end %if
                
                [xCh1 xCh2] = ndgrid(...
                    this.hImChannel{dataIdx(1)}.Data.Position_X(idxCh1),...
                    this.hImChannel{dataIdx(2)}.Data.Position_X(idxCh2));
                %                 xCh2 = xCh2+randn(size(xCh2))*0.01;
                [yCh1 yCh2] = ndgrid(...
                    this.hImChannel{dataIdx(1)}.Data.Position_Y(idxCh1),...
                    this.hImChannel{dataIdx(2)}.Data.Position_Y(idxCh2));
                %                 yCh2 = yCh2+randn(size(yCh2))*0.01;
                
                distMeasure = sqrt((xCh1-xCh2).^2+(yCh1-yCh2).^2); %[px]
                distMeasure(distMeasure > distThresh) = -1;
                %                 isInsideDistThresh = (distMeasure < distThresh);
                
                %add dummy column
                % distMeasure = [distMeasure max(distMeasure,[],2)+1];
                % isInsideDistThresh = [isInsideDistThresh true(numCh1,1)];
                
                %generate cost matrix
                maxCost = 1.05*max(prctile(distMeasure(:),100),eps);
                
                deathBlock = diag(maxCost*ones(numCh1,1)); %upper right
                deathBlock(deathBlock==0) = -1;
                birthBlock = diag(maxCost*ones(numCh2,1)); %lower left
                birthBlock(birthBlock==0) = -1;
                lrBlock = distMeasure';
                lrBlock(lrBlock~=-1) = maxCost;
                
                costMat = [distMeasure deathBlock; birthBlock lrBlock];
                
                %solve linear assignment
                [~,link21] = lap(costMat,-1,0);
                coLocIdxCh2 = find(link21(1:numCh2)<=numCh1);
                coLocIdxCh1 = link21(coLocIdxCh2);
                
                coLocIdx{frame} = ...
                    [idxCh1(coLocIdxCh1) idxCh2(coLocIdxCh2)];
            end %for
            %catenate found events
            coLocIdx = vertcat(coLocIdx{:});
            
            if isempty(coLocIdx)
                waitfor(errordlg('No Co-Localization detected','','modal'))
                return
            end %if
            
            objProject = this.Parent;
            for idxChannel = 1:2
                objLoc = this.hImChannel{dataIdx(idxChannel)};
                objCoLoc(idxChannel) = copy_data_to_project(objProject,objLoc);
                
                good = false(this.hImChannel{dataIdx(idxChannel)}.NumParticles,1);
                good(coLocIdx(:,idxChannel)) = true;
                if strcmp(this.objCoLocSettings.CoLocMode,'exclusive')
                    %inverse selection
                    good = ~good;
                end %if
                objCoLoc(idxChannel).NumParticles = sum(good);
                objCoLoc(idxChannel).Data = ...
                    structfun(@(x)x(good),objCoLoc(idxChannel).Data,'Un',0);
                
                show_frame(objCoLoc(idxChannel),objCoLoc(idxChannel).Frame);
                %                 initialize_visualization(objCoLoc(idxChannel))
            end %for
            
            %             %calculate new center of mass (weighted by respective loc. precision)
            %             [~,good] = max([this.hImChannel{dataIdx(1)}.Data.Precision(coLocIdx(:,1)),...
            %                 this.hImChannel{dataIdx(2)}.Data.Precision(coLocIdx(:,2))],[],2);
            %
            %             % arrange new format
            %             data = struct(...
            %                 'Particle_ID', transpose(1:numCoLoc)*datenum(clock),...
            %                 'Particle_ID_Hex', num2hex(transpose(1:numCoLoc)*datenum(clock)),...
            %                 'Time', this.hImChannel{dataIdx(1)}.Data.Time(coLocIdx(:,1)),...
            %                 'Position_X', (this.hImChannel{dataIdx(1)}.Data.Precision(coLocIdx(:,1)).^2.*...
            %                 this.hImChannel{dataIdx(1)}.Data.Position_X(coLocIdx(:,1))+...
            %                     this.hImChannel{dataIdx(2)}.Data.Precision(coLocIdx(:,2)).^2.*...
            %                 this.hImChannel{dataIdx(2)}.Data.Position_X(coLocIdx(:,2)))./...
            %                 (this.hImChannel{dataIdx(1)}.Data.Precision(coLocIdx(:,1)).^2+...
            %                 this.hImChannel{dataIdx(2)}.Data.Precision(coLocIdx(:,2)).^2),...
            %                 'Position_Y', (this.hImChannel{dataIdx(1)}.Data.Precision(coLocIdx(:,1)).^2.*...
            %                 this.hImChannel{dataIdx(1)}.Data.Position_Y(coLocIdx(:,1))+...
            %                     this.hImChannel{dataIdx(2)}.Data.Precision(coLocIdx(:,2)).^2.*...
            %                 this.hImChannel{dataIdx(2)}.Data.Position_Y(coLocIdx(:,2)))./...
            %                 (this.hImChannel{dataIdx(1)}.Data.Precision(coLocIdx(:,1)).^2+...
            %                 this.hImChannel{dataIdx(2)}.Data.Precision(coLocIdx(:,2)).^2),...
            %                 'Signalpower', max(this.hImChannel{dataIdx(1)}.Data.Signalpower(coLocIdx(:,1)),...
            %                 this.hImChannel{dataIdx(2)}.Data.Signalpower(coLocIdx(:,2))),...
            %                 'Background', (this.hImChannel{dataIdx(1)}.Data.Background(coLocIdx(:,1))+...
            %                 this.hImChannel{dataIdx(2)}.Data.Background(coLocIdx(:,2)))/2,...
            %                 'Noisepower', this.hImChannel{dataIdx(1)}.Data.Noisepower(coLocIdx(:,1))+...
            %                 this.hImChannel{dataIdx(2)}.Data.Noisepower(coLocIdx(:,2)));
        end %fun
        
        function estimate_PICCS(this)
            %close colocalization manager
%             if ishandle(this.objPICCS.hFig)
%                 delete(this.objPICCS.hFig)
%             end %if
            
            %get indices of source data
            dataSrcIdx = find(cell2mat(cellfun(@(x)strcmp(class(x),...
                'ClassLocalization'),this.hImChannel,'Un',0)));
            pxSize = this.hImChannel{dataSrcIdx(1)}.Px2nm; %[nm/px]
            
            switch this.objPICCS.SamplingMode
                case 'Linear'
                    r = linspace(this.objPICCS.CorrStart,...
                        this.objPICCS.CorrEnd,this.objPICCS.CorrSamples)/1000;
                case 'Logarithmic'
                    r = logspace(log10(this.objPICCS.CorrStart),...
                        log10(this.objPICCS.CorrEnd),this.objPICCS.CorrSamples)/1000;
            end %switch
            
            if isempty(this.objPICCS.ROI)
                mask = true(transform_orig_to_mag(this.FieldOfView(6),this.ActExp,0)-0.5,...
                    transform_orig_to_mag(this.FieldOfView(5),this.ActExp,0)-0.5);
                maskArea = this.FieldOfView(6)*this.FieldOfView(5)*pxSize^2/1e6; %[µm^2]
            else
                mask = this.objPICCS.ROI.Mask;
                maskArea = this.objPICCS.ROI.Area/this.ActExp^2*pxSize^2/1e6; %[µm^2]
            end %if
            maskSmall = imerode(mask,strel('disk',ceil(this.objPICCS.CorrEnd/pxSize)));
            
            for idxFrame = this.objPICCS.FrameStart:this.objPICCS.FrameEnd
                take = find(this.hImChannel{dataSrcIdx(1)}.Data.Time == idxFrame);
                A = [this.hImChannel{dataSrcIdx(1)}.Data.Position_X(take) ...
                    this.hImChannel{dataSrcIdx(1)}.Data.Position_Y(take)];
                aROI = SML_inside_mask(A(:,2),A(:,1),mask,this.ActExp,[this.FieldOfView(2) this.FieldOfView(1)]);
                aROISmall = SML_inside_mask(A(:,2),A(:,1),maskSmall,this.ActExp,[this.FieldOfView(2) this.FieldOfView(1)]);
                aDens(idxFrame) = sum(aROI)/maskArea;
                
                take = find(this.hImChannel{dataSrcIdx(2)}.Data.Time == idxFrame);
                B = [this.hImChannel{dataSrcIdx(2)}.Data.Position_X(take) ...
                    this.hImChannel{dataSrcIdx(2)}.Data.Position_Y(take)];
                bROI = SML_inside_mask(B(:,2),B(:,1),mask,this.ActExp,[this.FieldOfView(2) this.FieldOfView(1)]);
                bROISmall = SML_inside_mask(B(:,2),B(:,1),maskSmall,this.ActExp,[this.FieldOfView(2) this.FieldOfView(1)]);
                bDens(idxFrame) = sum(bROI)/maskArea;
                
                CcumAB(idxFrame,:) = calculate_cum_corr(A(aROI,:),B(bROISmall,:),r*1000/pxSize); %[AB]/[B] & [A]
                CcumBA(idxFrame,:) = calculate_cum_corr(B(bROI,:),A(aROISmall,:),r*1000/pxSize); %[BA]/[A] & [B]
            end %for
            evaluate_cross_corr_uniform_bckgrnd(mean(CcumAB,1),r,1)
            evaluate_cross_corr_uniform_bckgrnd(mean(CcumBA,1),r,1)
            
%             for idxFrame = this.objPICCS.FrameStart:this.objPICCS.FrameEnd
%                 [imgHeight,imgWidth] = size(mask);
%                 numA = ceil(aDens(idxFrame)*imgHeight*imgWidth/this.ActExp^2*pxSize^2/1e6);
%                 
%                 rndA = [rand(numA,1)*imgWidth rand(numA,1)*imgHeight];
%                 take = SML_inside_mask(rndA(:,2),rndA(:,1),mask,this.ActExp,[0 0]);
%                 CcumAB(idxFrame,:) = calculate_cum_corr(A(aROI,:),B(bROISmall,:),r*1000/pxSize); %[AB]/[B] & [A]
%                 
%                 [i,j] = find(mask);
%                 
%                 A = (range(i)+1)*(range(j)+1)/this.ActExp^2*pxSize^2/1e6; %[µm^2]
%                 rand(ceil(aDens(idxFrame)*A),1)*(range(i)+1)/this.ActExp
%                 
%                 bROI = SML_inside_mask(B(:,2),B(:,1),mask,this.ActExp,[0 0]);
%             end %for
        end %fun
        
        %%
        function S = saveobj(this)
            S = class2struct(this);
            
            %             for idxColor = 1:4
            %                 if not(isempty(this.hImChannel(idxColor)))
            %                     S.(this.ChannelNames{idxColor}) = ...
            %                         this.hImChannel{idxColor};
            %                 end %if
            %             end %for
            %
            %             for idxTraj = 1:numel(this.hTrajChannel)
            %                 S.(this.ChannelNames{6}){idxTraj} = ...
            %                     this.hTrajChannel{idxTraj};
            %             end %for
            
            S.Parent = [];
            %             S.hImChannel = {[] [] [] []};
            %             S.hClusterChannel = {};
            %             S.hTrajChannel = {};
            %             S = hlp_serialize(S);
        end %fun
        function this = reload(this,S)
            %             S = hlp_deserialize(S);
            
            %             try
            %             for idxColor = 1:4
            %                 if isfield(S,this.ChannelNames{idxColor})
            %                     S.hImChannel{idxColor} = ...
            %                         S.(this.ChannelNames{idxColor});
            % %                     set_parent(S.hImChannel{idxColor},this)
            %                 end %if
            %             end %for
            %
            %             if isfield(S,this.ChannelNames{6})
            %                 for idxTraj = 1:numel(S.(this.ChannelNames{6}))
            %                     S.hTrajChannel{idxTraj} = ...
            %                         S.(this.ChannelNames{6}){idxTraj};
            % %                     set_parent(S.hTrajChannel{idxTraj},this)
            %                 end %for
            %             end %if
            %             end %if
            
            this = struct2class(S,this);
        end %fun
        function close_object(this)
            notify(this,'ClosingVisualization')
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
        end
        function delete_object(this)
            notify(this,'ObjectDestruction')
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
            
            delete(this)
        end
        
        %% getter
        function numclasses = get.NumClasses(this)
            % =[#Raw #Loc #Cluster #Traj]
            numclasses = [...
                sum(cell2mat(cellfun(@(x)strcmp(class(x),...
                'ClassRaw'),this.hImChannel,'Un',0))),...
                sum(cell2mat(cellfun(@(x)strcmp(class(x),...
                'ClassLocalization'),this.hImChannel,'Un',0))),...
                numel(this.hClusterChannel), ...
                numel(this.hTrajChannel)];
        end %fun
        function numframes = get.NumFrames(this)
            numframes = max(cell2mat(cellfun(@(x)x.NumFrames,...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0)));
        end %fun
        function srcexp = get.SrcExp(this)
            srcexp = max(cell2mat(cellfun(@(x)x.ActExp,...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0)));
        end %fun
        function locstart = get.LocStart(this)
            locstart = min(cell2mat(cellfun(@(x)x.LocStart,...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0)));
        end %fun
        function locend = get.LocEnd(this)
            locend = max(cell2mat(cellfun(@(x)x.LocEnd,...
                [this.hImChannel(~cellfun('isempty',this.hImChannel)) ...
                this.hClusterChannel this.hTrajChannel],'Un',0)));
        end %fun
        
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ClassComposite;
            
            if isobject(S)
                S = saveobj(S);
            end %if
            
            this = reload(this,S);
            
            if isempty(this.objPICCS)
                this.objPICCS = ManagerPICCS(this);
            end %if
        end %fun
    end %methods
end %classdef