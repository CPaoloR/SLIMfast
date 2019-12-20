classdef SuperclassData < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Created %date of creation
        
        Parent %Project
        FamilyColor %unique color
        Name %user specified name
        
        ExpNotes %associated experimental notes
        
        Dim %data dimensionality (2 or 3)
        
        Channel %image channel identifier
        FieldOfView %[x0 y0 xEnd yEnd width height] defines working region
        
        Frame %actual frame idx
        Imagedata %image displayed (postprocessed)
        RawImagedata %unprocessed frame data
        FrameBin %actually binned image frames
        NumFrames %total number of frames
        
        objImageFile %File Information Manager
        objDisplaySettings %Display Manager
        objContrastSettings %Contrast Manager
        objUnitConvFac %Unit Conversion Manager
        objLocSettings %Localization Manager
        objTrackSettings %Tracking Manager
        objClusterSettings %Cluster (DBSCAN) Manager
        objDiffCoeffFit %Diffusion Coefficient Estimator
        objJumpSeries
        objConfManager
        
        objColormap
        objGrid %Grid Manager
        objRoi %ROI Manager
        objScalebar %Scalebar Manager
        objTimestamp %Timestamp Manager
        objColorbar %Colorbar Manager
        objTextstamp %Textstamp Manager
        objLineProfile
    end %properties
    properties (Hidden, Dependent)
        Px2nm
        Frame2msec
        Count2photon
        
        ActExp %actual displayed image expansion
        
        LocStart
        LocEnd
        TrackStart
        TrackEnd
        
        Maskdata
        MaskRect %[x0 y0 xEnd yEnd width height] rectangle enclosing all rois
    end %properties
    properties (Hidden, Transient)
        hExplorerLeaf
        listenerExplorerLeafDestruction
        
        hImageFig = nan;
        hImageToolbar
        hImagePlotPanel
        hImageAx
        hImageScrollpanel
        hImage
        hImageContextmenu
        hImageInfoPanel
        
        hMenuAdjustDisplay
        hMenuScalebar
        hMenuTimestamp
        hMenuTextstamp
        hMenuGrid
        
        hImageZoomFig
        
        MovProfiles = {...
            'Motion JPEG AVI',...
            'MPEG-4',...
            'Uncompressed AVI'};
        
        ExportBin %Container for ASCII Export
        
        listenerDestruction
    end %properties
    
    events
        ClosingVisualization
        ObjectDestruction
    end %events
    
    methods
        %% constructors
        function this = SuperclassData
            this.FamilyColor = min(0.99+rand*eps,1+randn(1,3)*0.1);
            
            this.Created = datestr(now);
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
        function display_frame(this)
            if ishandle(this.hImageFig)
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
                
                %check for timestamp
                if this.objTimestamp.HasTimestamp
                    update_timestamp(this.objTimestamp)
                end %if
                
                %check for dynamic grid
                if this.objGrid.UseGrid
                    if any(strcmp(this.objGrid.GridMode,...
                            {'Delaunay Triangulation' 'Voronoi Cell'}))
                        update_grid(this.objGrid)
                    end %if
                end %if
                
                %update frame visualization
                if any(strcmp(class(this),...
                        {'ClassRaw','ClassLocalization','ClassCalibration'}))
                    if ishandle(this.hImageZoomFig)
                        update_zoom_tool(this)
                    else
                        set(this.hImage,...
                            'CData',this.Imagedata)
                        
                        %check, that clims are not equal within 1e-12 tolerance
                        if diff(this.objContrastSettings.IntLimits) < 1e-12
                            this.objContrastSettings.IntLimits(2) = ...
                                this.objContrastSettings.IntLimits(1) +...
                                (1e-12 - diff(this.objContrastSettings.IntLimits));
                        end %if
                        
                        set(this.hImageAx,...
                            'Xlim', transform_orig_to_mag(...
                            this.FieldOfView([1 3]),this.ActExp,this.FieldOfView(1)),...
                            'Ylim', transform_orig_to_mag(...
                            this.FieldOfView([2 4]),this.ActExp,this.FieldOfView(2)),...
                            'CLim', this.objContrastSettings.IntLimits)
                    end %if
                end %if
            end %if
        end %fun
        function initialize_visualization(this)
            switch class(this)
                case {'ClassRaw' 'ClassLocalization'}
                    %check if project is already open
                    if ishandle(this.hImageFig)
                        waitfor(msgbox('Project already open','INFO','help','modal'))
                        figure(this.hImageFig)
                    else
                        initialize_image_visualization(this)
                    end %if
                case {'ClassTrajectory' 'ClassCluster'}
                    %check if project is already open
                    if ishandle(this.hListFig)
                        waitfor(msgbox('Project already open','INFO','help','modal'))
                        figure(this.hListFig)
                    elseif ishandle(this.hImageFig)
                        waitfor(msgbox('Project already open','INFO','help','modal'))
                        figure(this.hImageFig)
                    else
                        switch this.VisMode
                            case 'List'
                                initialize_list_visualization(this)
                            case 'Map'
                                initialize_image_visualization(this)
                        end %switch
                    end %if
            end %switch
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
                'WindowKeypressFcn', @(src,evnt)keyboard_actions(this,evnt),...
                'PaperPositionMode','auto',...
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
                @(src,event)respond_to_frame_slider(this,src));
            
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
                'Position', [1 20 figPos(3) figPos(4)-20],...
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
                'DisplayRange',this.objContrastSettings.IntLimits, ...
                'Parent', this.hImageAx);
            
            set(this.hImage,  'HitTest', 'off')
            
            hPixelInfo = impixelinfoval(hPixelInfoPanel,this.hImage);
            set(hPixelInfo,...
                'Parent', hPixelInfoPanel,...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'FontSize',12,...
                'HorizontalAlignment','center')
            
            this.hImageScrollpanel = imscrollpanel(...
                this.hImagePlotPanel,this.hImage);
            api = iptgetapi(this.hImageScrollpanel);
            api.setMagnification(0.95*api.findFitMag())
            set([this.hImageScrollpanel; ...
                allchild(this.hImageScrollpanel)], 'HitTest', 'off')
            
            set(this.hImageFig,'ResizeFcn', ...
                @(src,evnt)resize_frame_axes(this))
            
            restore_image_assecoirs(this)
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
            hGridRectangular = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Uniform Rectangular',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            hGridHexagon = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Uniform Hexagonal',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            hGridDelaunay = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Delaunay Triangulation',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            hGridVoronoi = ...
                uimenu(...
                'Parent', hMenuGrid,...
                'Label', 'Voronoi Cell',...
                'Callback', @(src,evnt)show_grid(this.objGrid,src));
            if this.objGrid.UseGrid
                switch this.objGrid.GridMode
                    case 'Uniform Rectangular'
                        set(hGridRectangular,'Checked','on')
                    case 'Uniform Hexagonal'
                        set(hGridHexagon,'Checked','on')
                    case 'Delaunay Triangulation'
                        set(hGridDelaunay,'Checked','on')
                    case 'Voronoi Cell'
                        set(hGridVoronoi,'Checked','on')
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
                'GridMenu', hMenuGrid,...
                'Rectangular', hGridRectangular,...
                'Hexagonal', hGridHexagon,...
                'Delaunay', hGridDelaunay,...
                'Voronoi', hGridVoronoi),...
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
                if ishandle(this.objScalebar.hBar)
                    update_bar(this.objScalebar)
                end %if
            end %if
            if this.objTimestamp.HasTimestamp
                if ishandle(this.objTimestamp.hTimestamp)
                    update_timestamp(this.objTimestamp)
                end %if
            end %if
            if this.objTextstamp.HasTextstamp
                if ishandle(this.objTextstamp.hTextstamp)
                    update_textstamp(this.objTextstamp)
                end %if
            end %if
        end %fun
        function open_zoom_tool(this)
            %check if gui already open
            if ishandle(this.hImageZoomFig)
                waitfor(msgbox('ZOOM TOOL already open','INFO','help','modal'))
                figure(this.hImageZoomFig)
                return
            end %if
            
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
            
            %             set(this.hImage,'CData',this.Imagedata)
            api.replaceImage(this.Imagedata,...
                'PreserveView',1,...
                'Colormap',this.objColormap.Colormapping,...
                'DisplayRange', this.objContrastSettings.IntLimits)
            
            newFitMag = api.findFitMag();
            newLim = [get(this.hImageAx,'XLim') ...
                get(this.hImageAx,'YLim')];
            api.setMagnificationAndCenter(visMag*(newFitMag/oldFitMag),...
                normVisCtrs(1)*newLim(2),normVisCtrs(2)*newLim(4))
        end %fun
        
        function isOK = respond_to_frame_slider(this,src)
            frame = round(get(src,'Value'));
            isOK = show_frame(this,frame);
        end %fun
        
        function isOK = show_frame(this,frame)
            if (frame < 1) || ...
                    (frame > this.NumFrames)
                isOK = 1;
                return
            end %if
            
            imgFrameWin = get_image_frames_covered(this,frame);
            
            isOK = get_frame(this,imgFrameWin,...
                this.objDisplaySettings.WinMode);
            if isOK
                this.Frame = frame;
                display_frame(this)
            end %if
        end %fun
        function flag = show_previous_frame(this,loop)
            %flag = 0 -> error
            %flag = -1 -> endpoint reached
            if this.Frame > 1
                frame = this.Frame - 1;
            else
                if loop
                    frame = this.NumFrames;
                else
                    flag = -1;
                    return
                end %if
            end %if
            
            flag = show_frame(this,frame);
        end %fun
        function flag = show_next_frame(this,loop)
            %get next frame
            if this.Frame < this.NumFrames
                frame = this.Frame + 1;
            else
                if loop
                    frame = 1;
                else
                    flag = -1;
                    return
                end %if
            end %if
            
            flag = show_frame(this,frame);
        end %fun
        function playback_frames(this,src)
            icon = getappdata(0,'icon');
            set(src,'CData', icon.('Pause'))
            while ishandle(this.hImageFig) && ...
                    get(src,'Value') %play-button is pushed
                %show next frame
                isOK = show_next_frame(this,1);
                if ~isOK
                    %stop playback
                    set(src,'Value', 0)
                end %if
                
                pause(0.05)
            end %while
            set(src,'CData', icon.('Playback'))
        end %fun
        
        function [frameOut, isOK] = construct_frame(this,imgFrameWin)
            switch this.objDisplaySettings.RenderMode
                case 'Normal'
                    [frameOut, isOK] = get_frame(this,imgFrameWin,...
                        this.objDisplaySettings.WinMode);
                    if ~isOK
                        return
                    end %if
                    
                    %update framebin
                    this.FrameBin = imgFrameWin;
                case 'Differential'
                    frameOut = this.RawImagedata;
                    [exSet,addIdx,delIdx] = setxor(imgFrameWin,this.FrameBin);
                    
                    %caclulate new frame
                    if isempty(exSet)
                        %=no change
                        isOK = 1;
                        return
                    end %if
                    if ~isempty(addIdx)
                        [frameAdd, isOK] = get_frame(this,imgFrameWin(addIdx),...
                            this.objDisplaySettings.WinMode);
                        if isOK
                            frameOut = frameOut + frameAdd;
                        else
                            return
                        end %if
                    end %if
                    if ~isempty(delIdx)
                        [frameDel, isOK] = get_frame(this,this.FrameBin(delIdx),...
                            this.objDisplaySettings.WinMode);
                        if isOK
                            frameOut = frameOut - frameDel;
                        else
                            return
                        end %if
                    end %if
                    
                    %update framebin
                    delIdx_ = false(1,numel(this.FrameBin));
                    delIdx_(delIdx) = true;
                    delIdx = delIdx_;
                    this.FrameBin = [this.FrameBin(~delIdx) imgFrameWin(addIdx)];
                    
                    isOK = 1;
            end %switch
        end %fun
        
        %%
        function objDataClone = clone_object(this,parent)
            %initialize new data object
            objDataClone = feval(class(this));
            set_parent(objDataClone,parent)
            
            classInfo = metaclass(this);
            %copy class properties
            classProp = classInfo.PropertyList;
            numProp = numel(classProp);
            for propIdx = 1:numProp
                fieldName = classProp(propIdx).Name;
                %check if property should be copied
                if ~classProp(propIdx).Dependent &&...
                        ~classProp(propIdx).Transient &&...
                        ~any(strcmp(fieldName,...
                        {'Created','Parent','FamilyColor'}))
                    %check if property must be deep copied
                    if isobject(this.(fieldName))
                        if regexp(class(this.(fieldName)),'Manager')
                            %deep copy manager objects
                            objDataClone.(fieldName) = copy(this.(fieldName));
                            set_parent(objDataClone.(fieldName),objDataClone)
                        end %if
                    else
                        %copy value
                        objDataClone.(fieldName) = this.(fieldName);
                    end %if
                end %if
            end %for
        end %fun
        
        function save_image(this)
            %written by
            %C.P.Richter
            %Division of Biophysics / Group J.Piehler
            %University of Osnabrueck
            
            answer = questdlg('Image Type?','','Raw','Screenshot','Screenshot');
            
            switch answer
                case ''
                    return
                case 'Raw'
                    scrShot.cdata = uint16((this.Imagedata-min(this.Imagedata(:)))/...
                        (max(this.Imagedata(:))-min(this.Imagedata(:)))*2^16);
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
        function keyboard_actions(this,event)
            obj = get(this.hImageFig,'CurrentObject');
            
            % current object is a roi
            if strcmp(get(obj,'Type'),'patch')
                %identify roi
                roiIdx = eq([this.objRoi.RoiList(:).hPatch],obj);
                if any(roiIdx)
                    pos = getPosition(this.objRoi.RoiList(roiIdx).hRoi);
                    switch event.Key
                        case 'leftarrow'
                            pos(:,1) = pos(:,1) - 1 ;
                        case 'uparrow'
                            pos(:,2) = pos(:,2) - 1 ;
                        case 'rightarrow'
                            pos(:,1) = pos(:,1) + 1 ;
                        case 'downarrow'
                            pos(:,2) = pos(:,2) + 1 ;
                        case 'add'
                            pos(:,end-1:end) =  pos(:,end-1:end) + 1 ;
                        case 'subtract'
                            pos(:,end-1:end) =  pos(:,end-1:end) - 1 ;
                        case '0'
                            switch event.Character
                                case '+'
                                    pos(:,end-1:end) =  pos(:,end-1:end) + 1 ;
                            end %switch
                        case 'hyphen'
                            switch event.Character
                                case '-'
                                    pos(:,end-1:end) =  pos(:,end-1:end) - 1 ;
                            end %switch
                    end %switch
                    setConstrainedPosition(...
                        this.objRoi.RoiList(roiIdx).hRoi,pos)
                end %if
            end %if
        end %fun
        
        %% getter
        function px2nm = get.Px2nm(this)
            px2nm = this.objUnitConvFac.Px2nm;
        end %fun
        function frame2msec = get.Frame2msec(this)
            frame2msec = this.objUnitConvFac.Frame2msec;
        end %fun
        function count2photon = get.Count2photon(this)
            count2photon = this.objUnitConvFac.Count2photon;
        end %fun
        
        function actexp = get.ActExp(this)
            actexp = this.objDisplaySettings.ActExp;
        end %fun
        
        function locstart = get.LocStart(this)
            locstart = this.objLocSettings.LocStart;
        end %fun
        function locend = get.LocEnd(this)
            locend = this.objLocSettings.LocEnd;
        end %fun
        function tarckstart = get.TrackStart(this)
            tarckstart = this.objTrackSettings.TrackStart;
        end %fun
        function trackend = get.TrackEnd(this)
            trackend = this.objTrackSettings.TrackEnd;
        end %fun
        
        function maskdata = get.Maskdata(this)
            %if there is no roi -> roi equals actual FieldOfView
            vertices = [...
                this.FieldOfView(1) this.FieldOfView(2);...
                this.FieldOfView(1) this.FieldOfView(4);...
                this.FieldOfView(3) this.FieldOfView(4);...
                this.FieldOfView(3) this.FieldOfView(2)];
            
            fun = @(x)(x-0.5)*this.ActExp+0.5;
            maskdata = poly2mask(...
                fun(vertices(:,1)),...
                fun(vertices(:,2)),...
                this.objImageFile.ChannelHeight*this.ActExp,...
                this.objImageFile.ChannelWidth*this.ActExp);
            
            %check if any ROI is present
            if this.objRoi.HasRoi
                %preallocate mask matrix
                mask = zeros(...
                    this.objImageFile.ChannelHeight*this.ActExp,...
                    this.objImageFile.ChannelWidth*this.ActExp,...
                    this.objRoi.NumRoi);
                
                %construct binary mask for individual rois
                for roiIdx = 1:this.objRoi.NumRoi
                    %get rois polygon data
                    %                                         vertices = get(this.objRoi.RoiList(roiIdx).hPatch,'Vertices');  %changed 140809 CPR
                    
                    vertices = this.objRoi.RoiList(roiIdx).VerticesRel;
                    switch this.objRoi.RoiList(roiIdx).Shape
                        case 'Rectangle'
                            vertices = [[vertices(1);vertices(1);vertices(1)+vertices(3);vertices(1)+vertices(3)],...
                                [vertices(2);vertices(2)+vertices(4);vertices(2)+vertices(4);vertices(2)]];
                        case 'Ellipse'
                            ctrs = [(vertices(1)+vertices(1)+vertices(3))/2 (vertices(2)+vertices(2)+vertices(4))/2];
                            phi = linspace(0,2*pi,1000);
                            vertices = [(vertices(3)/2)*cos(phi(:))+ctrs(1),(vertices(4)/2)*sin(phi(:))+ctrs(2)];
                    end %if
                    
                    %construct pixelated binary map from polygon
                    % mask(:,:,roiIdx) = roipoly(mask(:,:,roiIdx),vertices(:,1),vertices(:,2));
                    mask(:,:,roiIdx) = poly2mask(...
                        (fun(this.FieldOfView(1))-0.5+vertices(:,1)-0.5)+0.5,...
                        (fun(this.FieldOfView(2))-0.5+vertices(:,2)-0.5)+0.5,...
                        this.objImageFile.ChannelHeight*this.ActExp,...
                        this.objImageFile.ChannelWidth*this.ActExp);
                end %for
                
                %check for rois type
                isInclusive = strcmp({this.objRoi.RoiList(:).Type},'inclusive');
                %combine single rois to final mask
                if any(isInclusive)
                    %combine inclusive rois
                    positivemask = any(mask(:,:,isInclusive),3);
                else
                    %there are only exclusive rois
                    %-> whole image is inclusive roi
                    positivemask = true(...
                        this.objImageFile.ChannelHeight*this.ActExp,...
                        this.objImageFile.ChannelWidth*this.ActExp);
                end %if
                %combine exclusive rois
                negativemask = any(mask(:,:,~isInclusive),3);
                
                %final binary mask
                maskdata = maskdata & positivemask & ~negativemask;
            end %if
        end %fun
        function maskrect = get.MaskRect(this)
            %check if there are rois
            if this.objRoi.HasRoi
                %check for roi type
                isInclusive = strcmp({this.objRoi.RoiList(:).Type},'inclusive');
                if any(isInclusive)
                    %rectangle including all inclusive rois
                    borderrect = vertcat(this.objRoi.RoiList(isInclusive).Borderrect);
                    
                    maskrect = [...
                        min(borderrect(:,1)) ...
                        min(borderrect(:,2)) ...
                        max(borderrect(:,3)) ...
                        max(borderrect(:,4))];
                    maskrect = [maskrect ...
                        maskrect(3)-maskrect(1) maskrect(4)-maskrect(2)];
                else
                    maskrect = this.FieldOfView;
                end %if
            else
                %equals current field of view
                maskrect = this.FieldOfView;
            end %if
        end %fun
        
        function imageframesincluded = ...
                get_image_frames_covered(this,frame)
            if this.objDisplaySettings.IsCumulative
                imageframesincluded = ...
                    this.objDisplaySettings.DisplayStart:...
                    this.objDisplaySettings.DisplayStart+...
                    this.objDisplaySettings.DisplayWin-1+...
                    (frame-1)*this.objDisplaySettings.DisplayStep;
            else
                imageframesincluded = ...
                    (frame-1)*this.objDisplaySettings.DisplayStep+...
                    ((1:this.objDisplaySettings.DisplayWin)+...
                    this.objDisplaySettings.DisplayStart-1);
            end %if
            
            %make sure calculated frames lie within stack limits
            imageframesincluded = imageframesincluded(...
                imageframesincluded > 0 & ...
                imageframesincluded <= sum(this.objImageFile.NumImageFrames));
        end %fun
        
        %%
        function S = saveobj(this)
            S = class2struct(this);
            S.Parent = []; %remove to avoid self-references
        end %fun
        function this = reload(this,S)
            this = struct2class(S,this);
        end %fun
        function close_object(this)
            notify(this,'ClosingVisualization')
        end %fun
        function delete_object(this)
            notify(this,'ObjectDestruction')
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(this,S)
            if isobject(S) %backwards-compatibility
                S = saveobj(S);
            end %if
            this = reload(this,S);
        end %fun
    end %methods
end %classdef