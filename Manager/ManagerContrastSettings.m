classdef ManagerContrastSettings < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        ImageData
        
        ECDF
        X
        MinX
        MaxX
        
        IntLimits
    end %properties
    properties (Hidden,Dependent)
        LowSat
        HighSat
        FixedSat
    end %properties
    properties (Hidden,Transient)
        hFig = nan;
        hAx
        hToolbar
        hColormap
        
        hSettingsPanel
        hHistPanel
        hFrame = nan;
        
        ChannelColor
        
        hLowSatEdit
        hHighSatEdit
        hFixedSatCheckbox
        
        hArea = nan;
        
        LogScaleFac
    end %properties
    
    methods
        %constructor
        function this = ManagerContrastSettings(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %fun
        
        function adjust_contrast(this)
            if strcmp(class(this.Parent),'ClassTrajectory')
                waitfor(errordlg('Contrast Tool not supported for Trajectory Data','','modal'))
                return
            end %if
            
            %check if gui already open
            if ishandle(this.hFig)
                waitfor(msgbox('CONTRAST MANAGER already open','INFO','help','modal'))
                figure(this.hFig)
                return
            end %if
            
            %build figure
            this.hFig = figure(...
                'Color',  this.FamilyColor,...
                'Name', 'CONTRAST MANAGER',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Units', 'pixels',...
                'Position', set_figure_position(2,0.3,'north-west'),...
                'IntegerHandle','off',...
                'Resize','off',...
                'CloseRequestFcn',@(src,evnt)close_object(this));
            
            %correct position for figure frame
            figPosition = get(this.hFig,'Position');
            figFrame = get(this.hFig,'OuterPosition')-figPosition;
            set(this.hFig,...
                'Position', figPosition+[figFrame(3) -figFrame(4) 0 0])
            
            this.hSettingsPanel = ...
                uipanel(...
                'Parent', this.hFig,...
                'Units','normalized',...
                'Position', [0 0.8 1 0.2],...
                'BackgroundColor', this.FamilyColor,...
                'HitTest', 'off');
            
            uicontrol(...
                'Style', 'text',...
                'Parent', this.hSettingsPanel,...
                'Units','normalized',...
                'Position', [0.01 0.1 0.48 0.8],...
                'FontSize', 19,...
                'String', 'Pixel Saturation [%]:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            this.hLowSatEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Parent', this.hSettingsPanel,...
                'Units','normalized',...
                'Position', [0.49 0.1 0.15 0.8],...
                'FontSize', 14,...
                'FontUnits', 'normalized',...
                'BackgroundColor', [1 1 1]);
            
            this.hHighSatEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Parent', this.hSettingsPanel,...
                'Units','normalized',...
                'Position', [0.65 0.1 0.15 0.8],...
                'FontSize', 14,...
                'FontUnits', 'normalized',...
                'BackgroundColor', [1 1 1]);
            
            this.hFixedSatCheckbox = ...
                uicontrol(...
                'Style', 'checkbox',...
                'Parent', this.hSettingsPanel,...
                'Units','normalized',...
                'Position', [0.81 0.1 0.19 0.8],...
                'FontSize', 18,...
                'BackgroundColor', this.FamilyColor,...
                'String', 'fixed');
            
            this.hHistPanel = ...
                uipanel(...
                'Parent', this.hFig,...
                'Units','normalized',...
                'Position', [0 0 1 0.8],...
                'BackgroundColor', this.FamilyColor,...
                'HitTest', 'off');
            
            axes(...
                'Parent', this.hHistPanel,...
                'Units', 'normalized',...
                'Position',[0.1 0.2 0.8 0.7],...
                'XLim',[0 1],...
                'XTick',[0 1],...
                'XTickLabel','',...
                'YLim',[0 1],...
                'YTick',[0 1],...
                'TickLength',[0 0],...
                'YTickLabel','',...
                'Box','on');
            
            if strcmp(class(this.Parent),'ClassComposite')
                %true color mode
                construct_image_toolbar(this,this.Parent.hImChannel)
                
                color = [1 0 0; 0 1 0; 0 0 1; 0.5 0.5 0.5];
                for chIdx = 1:4
                    if ~isempty(this.Parent.hImChannel{chIdx})
                        this.Parent.hImChannel{chIdx}.objContrastSettings.hToolbar = ...
                            this.hToolbar;
                        this.Parent.hImChannel{chIdx}.objContrastSettings.hHistPanel = ...
                            this.hHistPanel;
                        this.Parent.hImChannel{chIdx}.objContrastSettings.hLowSatEdit = ...
                            this.hLowSatEdit;
                        this.Parent.hImChannel{chIdx}.objContrastSettings.hHighSatEdit = ...
                            this.hHighSatEdit;
                        this.Parent.hImChannel{chIdx}.objContrastSettings.ChannelColor = ...
                            color(chIdx,:);
                        
                        update_intensity_data(this,this.Parent.hImChannel{chIdx}.Imagedata)
                        plot_intensity_data(this.Parent.hImChannel{chIdx}.objContrastSettings)
                    end %if
                end %for
            else
                %intensity mode
                this.ChannelColor = [0.5 0.5 0.5];
                update_intensity_data(this,this.Parent.Imagedata)
                plot_intensity_data(this)
                
                set(this.hAx,...
                    'XGrid','on',...
                    'YGrid','on')
                
                set(this.hFrame,'Visible','on')
                if all(this.X==0)
                    set(this.hLowSatEdit,...
                        'String',sprintf('%.2f',this.LowSat),...
                        'Callback', @(src,evnt)set_LowSat(this,src))
                    set(this.hHighSatEdit,...
                        'String',sprintf('%.2f',this.HighSat),...
                        'Callback', @(src,evnt)set_HighSat(this,src))
                else
                    set(this.hLowSatEdit,...
                        'String',sprintf('%.2f',...
                        get_saturation(this,this.IntLimits(1))),...
                        'Callback', @(src,evnt)set_LowSat(this,src))
                    set(this.hHighSatEdit,...
                        'String',sprintf('%.2f',...
                        100-get_saturation(this,this.IntLimits(2))),...
                        'Callback', @(src,evnt)set_HighSat(this,src))
                end %if
                set(this.hFixedSatCheckbox,...
                    'Value', this.FixedSat,...
                    'Callback', @(src,evnt)set_FixedSat(this,src))
            end %if
        end %fun
        function construct_image_toolbar(this,imdataObj)
            hToolbar = uitoolbar('Parent',this.hFig);
            icon = getappdata(0,'icon');
            hChannelButton(1) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Red'),...
                'Separator','on',...
                'Enable','off');
            if ~isempty(imdataObj{1})
                set(hChannelButton(1),...
                    'UserData',imdataObj{1},...
                    'ClickedCallback', @(src,evnt)select_channel(this,src),...
                    'Enable','on');
            end %if
            hChannelButton(2) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Green'),...
                'Enable','off');
            if ~isempty(imdataObj{2})
                set(hChannelButton(2),...
                    'UserData',imdataObj{2},...
                    'ClickedCallback', @(src,evnt)select_channel(this,src),...
                    'Enable','on');
            end %if
            hChannelButton(3) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Blue'),...
                'Enable','off');
            if ~isempty(imdataObj{3})
                set(hChannelButton(3),...
                    'UserData',imdataObj{3},...
                    'ClickedCallback', @(src,evnt)select_channel(this,src),...
                    'Enable','on');
            end %if
            hChannelButton(4) = ...
                uitoggletool(...
                'Parent',hToolbar,...
                'CData', icon.('Channel_Gray'),...
                'Enable','off');
            if ~isempty(imdataObj{4})
                set(hChannelButton(4),...
                    'UserData',imdataObj{4},...
                    'ClickedCallback', @(src,evnt)select_channel(this,src),...
                    'Enable','on');
            end %if
            
            this.hToolbar = struct(...
                'Toolbar', hToolbar,...
                'Channel', hChannelButton);
        end %fun
        
        function update_intensity_data(this,imageData)
            this.ImageData = imageData(imageData>0);
            
            if all(this.ImageData==0) %(=black image, no localizations)
                this.ECDF = 1;
                this.X = 0;
                
                this.MinX = 0;
                this.MaxX = 1e-12;
                
                if this.FixedSat
                    this.IntLimits = [0 1e-12];
                end %if
                
                if isempty(this.IntLimits)
                    this.IntLimits = [0 1e-12];
                end %if
            else
                [this.ECDF,this.X] = ecdf(this.ImageData);
                [this.X,good] = unique(this.X,'first');
                this.ECDF = this.ECDF(good);
                
                this.MinX = min(this.X);
                this.MaxX = max(this.X);
                
                %adjust limits to match respective saturation
                if this.FixedSat
                    this.IntLimits = [...
                        get_intensity_limit(this,this.LowSat) ...
                        get_intensity_limit(this,100-this.HighSat)];
                end %if
                
                %if no limits are give use complete intensity range
                if isempty(this.IntLimits)
                    this.IntLimits = [this.MinX this.MaxX];
                end %if
            end %if
        end %fun
        function plot_intensity_data(this)
            [x y] = calculate_log_log_hist(this);
            
            if ishandle(this.hArea)                
                %check, that clims are not equal within 1e-12 tolerance
                set(this.hAx,...
                    'XTick',transform_lin_to_log(this,linspace(...
                    min(this.MinX,this.IntLimits(1)),...
                    max(this.MaxX,this.IntLimits(2)),25)))
                
                %update graph
                set(this.hArea,...
                    'XData',x,...
                    'YData',y)
                
                %update frame (=imrect)
                logIntLimits = ...
                    transform_lin_to_log(this,this.IntLimits);
                setPosition(this.hFrame,...
                    [logIntLimits(1) 0 ...
                    range(logIntLimits) 1])
                fcn = makeConstrainToRectFcn('imrect',...
                    transform_lin_to_log(this,...
                    [min(this.MinX,this.IntLimits(1)) ...
                    max(this.MaxX,this.IntLimits(2))]),[0 1]);
                setPositionConstraintFcn(this.hFrame,fcn);
            else
                %create
                this.hAx = ...
                    axes(...
                    'Parent', this.hHistPanel,...
                    'Units', 'normalized',...
                    'Position',[0.1 0.2 0.8 0.7],...
                    'XTick',transform_lin_to_log(this,linspace(...
                    min(this.MinX,this.IntLimits(1)),...
                    max(this.MaxX,this.IntLimits(2)),25)),...
                    'XTickLabel','',...
                    'YTick', log10(linspace(1,10,25)),...
                    'YTickLabel','',...
                    'LineWidth', 1,...
                    'Box','on',...
                    'Color','none',...
                    'TickLength',[0 0],...
                    'GridLineStyle','-',...
                    'FontSize',14,...
                    'FontWeight','bold',...
                    'NextPlot', 'add');
                xlabel(this.hAx, 'Pixel Intensity lg[count]')
                ylabel(this.hAx, 'Norm. Freq. lg[count]')
                
                this.hArea = area(this.hAx, x, y, ...
                    'EdgeColor', 'none',...
                    'FaceColor', this.ChannelColor,...
                    'Hittest','off');
                set(get(this.hArea,'children'),'FaceAlpha',0.5)
                
                construct_frame(this)
            end %if
            xlim(this.hAx, transform_lin_to_log(this,...
                [min(this.MinX,this.IntLimits(1)) ...
                max(this.MaxX,this.IntLimits(2))]))
        end %fun
        function [x y] = calculate_log_log_hist(this)
            switch class(this.Parent)
                case 'ClassRaw'
                    data = this.ImageData;
                case 'ClassLocalization'
                    data = nonzeros(this.ImageData);
                    if isempty(data) %(=black image, no localizations)
                        this.LogScaleFac = 0;
                        x = [0 1e-12];
                        y = [1 1];
                        
                        return
                    end %if
            end %switch
            
            this.LogScaleFac = min(min(data),this.IntLimits(1));
            logData = transform_lin_to_log(this,data);
            nbins = calcnbins(logData,'fd',10,500);
            [cnt bin] = ksdensity(logData,...
                linspace(min(logData),max(logData),nbins));
            logCnt = log10(cnt-min(cnt)+1);
            [x y] = stairs(bin,logCnt/max(logCnt));
        end %fun
        
        function construct_frame(this)
            if ishandle(this.hFrame)
                delete(this.hFrame)
            end %if
            
            logIntLimits = ...
                transform_lin_to_log(this,this.IntLimits);
            this.hFrame = imrect(this.hAx, ...
                [logIntLimits(1) 0 ...
                range(logIntLimits) 1]);
            fcn = makeConstrainToRectFcn('imrect',...
                transform_lin_to_log(this,...
                [this.MinX this.MaxX]),[0 1]);
            setPositionConstraintFcn(this.hFrame,fcn);
            hList = get(this.hFrame,'Children');
            set(hList([1 2 3 5 6 7]),...
                'Marker','none',...
                'LineStyle','none',...
                'ButtonDownFcn',[])
            set(hList([4 8]),...
                'MarkerSize',15,...
                'MarkerFaceColor', this.ChannelColor,...
                'MarkerEdgeColor', this.ChannelColor)
            set(hList([9 11]),...
                'LineStyle','none',...
                'ButtonDownFcn',[])
            set(hList([10 12]),...
                'LineWidth',3,...
                'LineStyle','-','Color',this.ChannelColor)
            set(hList([14 15]),...
                'LineStyle','none')
            set(hList([13]),...
                'UIContextMenu',[])
            addNewPositionCallback(...
                this.hFrame,@(position)set_intensity_limits(this,position));
            set(this.hFrame,...
                'Visible','off')
        end %fun
        function set_intensity_limits(this,position)
            intLimits = [position(1) position(1)+position(3)];
            if position(3) >= 1e-12
                this.IntLimits = transform_log_to_lin(this,intLimits);
                
                this.SrcContainer.LowSat = ...
                    get_saturation(this,this.IntLimits(1));
                this.SrcContainer.HighSat = ...
                    100-get_saturation(this,this.IntLimits(2));
                if isempty(this.hToolbar)
                    set(this.hLowSatEdit,'String',sprintf('%.2f',this.LowSat))
                    set(this.hHighSatEdit,'String',sprintf('%.2f',this.HighSat))
                else
                    if eq(this.Parent,get(this.hToolbar.Channel(...
                            strcmp(get(this.hToolbar.Channel,'State'),'on')),'UserData'))
                        set(this.hLowSatEdit,'String',sprintf('%.2f',this.LowSat))
                        set(this.hHighSatEdit,'String',sprintf('%.2f',this.HighSat))
                    end %if
                end %if
                
                if ishandle(this.Parent.hImageFig)
                    %check, that clims are not equal within 1e-12 tolerance
                    if diff(this.IntLimits) < 1e-12
                        this.IntLimits(2) = ...
                            this.IntLimits(1) +...
                            (1e-12 - diff(this.IntLimits));
                    end %if
                    set(this.Parent.hImageAx,'CLim',this.IntLimits);
                else
                    if strcmp(class(this.Parent.Parent),'ClassComposite')
                        update_image_plane_contrast(this.Parent.Parent,this.Parent,this.IntLimits)
                    end %if
                end %if
            end %if
        end %fun
        
        function select_channel(this,src)
            %set exclusive toolbar behavior
            set(this.hToolbar.Channel,...
                'State','off')
            set(src, 'State','on')
            
            %get actual data object
            imdataObj = get(src,'UserData');
            
            %select actual axes
            set(findobj(this.hFig,'Type','axes'),...
                'XGrid','off','YGrid','off')
            axes(imdataObj.objContrastSettings.hAx)
            set(imdataObj.objContrastSettings.hAx,...
                'XGrid','on','YGrid','on')
            
            %show actual frame
            set(findobj(this.hFig,'Tag','imrect'),...
                'Visible','off')
            set(imdataObj.objContrastSettings.hFrame, 'Visible','on')
            
            if all(this.X==0)
                set(this.hLowSatEdit,...
                    'String',sprintf('%.2f',imdataObj.objContrastSettings.LowSat),...
                    'Callback', @(src,evnt)set_LowSat(imdataObj.objContrastSettings,src))
                set(this.hHighSatEdit,...
                    'String',sprintf('%.2f',imdataObj.objContrastSettings.HighSat),...
                    'Callback', @(src,evnt)set_HighSat(imdataObj.objContrastSettings,src))
            else
                set(this.hLowSatEdit,...
                    'String',sprintf('%.2f',...
                    get_saturation(imdataObj.objContrastSettings,...
                    imdataObj.objContrastSettings.IntLimits(1))),...
                    'Callback', @(src,evnt)set_LowSat(imdataObj.objContrastSettings,src))
                set(this.hHighSatEdit,...
                    'String',sprintf('%.2f',...
                    100-get_saturation(imdataObj.objContrastSettings,...
                    imdataObj.objContrastSettings.IntLimits(2))),...
                    'Callback', @(src,evnt)set_HighSat(imdataObj.objContrastSettings,src))
            end %if
            set(this.hFixedSatCheckbox,...
                'Value', imdataObj.objContrastSettings.FixedSat,...
                'Callback', @(src,evnt)set_FixedSat(imdataObj.objContrastSettings,src))
        end %fun
        
        function set_LowSat(this,src)
            this.SrcContainer.LowSat = ...
                min(100-this.HighSat,max(0,...
                str2double(get(src,'String'))));
            this.IntLimits(1) = get_intensity_limit(this,this.LowSat);
            %check, that clims are not equal within 1e-12 tolerance
            if diff(this.IntLimits) < 1e-12
                this.IntLimits(1) = ...
                    this.IntLimits(2) -...
                    (1e-12 - diff(this.IntLimits));
            end %if
            set(this.Parent.hImageAx,'CLim', this.IntLimits);
            
            set(src,'String',this.LowSat)
            logIntLimits = ...
                transform_lin_to_log(this,this.IntLimits);
            setPosition(this.hFrame,...
                [logIntLimits(1) 0 ...
                range(logIntLimits) 1])
        end %fun
        function set_HighSat(this,src)
            this.SrcContainer.HighSat = ...
                min(100-this.LowSat,max(0,...
                str2double(get(src,'String'))));
            this.IntLimits(2) = get_intensity_limit(this,100-this.HighSat);
            %check, that clims are not equal within 1e-12 tolerance
            if diff(this.IntLimits) < 1e-12
                this.IntLimits(2) = ...
                    this.IntLimits(1) +...
                    (1e-12 - diff(this.IntLimits));
            end %if
            set(this.Parent.hImageAx,'CLim', this.IntLimits);
            
            set(src,'String',this.HighSat)
            logIntLimits = ...
                transform_lin_to_log(this,this.IntLimits);
            setPosition(this.hFrame,...
                [logIntLimits(1) 0 ...
                range(logIntLimits) 1])
        end %fun
        function set_FixedSat(this,src)
            value = get(src,'Value');
            this.SrcContainer.FixedSat = value;
        end %fun
        
        function lowsat = get.LowSat(this)
            lowsat = this.SrcContainer.LowSat;
        end %fun
        function highsat = get.HighSat(this)
            highsat = this.SrcContainer.HighSat;
        end %fun
        function fixedsat = get.FixedSat(this)
            fixedsat = this.SrcContainer.FixedSat;
        end %fun
        
        function logData = transform_lin_to_log(this,linData)
            %normalize to lg[1 inf]=[0 inf]
            logData = log10(linData-this.LogScaleFac+1);
        end %fun
        function linData = transform_log_to_lin(this,logData)
            linData = 10.^(logData)+this.LogScaleFac-1;
        end %fun
        
        function intLimit = get_intensity_limit(this,saturation)
            intLimit = ...
                interp1(this.ECDF,this.X,saturation/100,'linear','extrap');
        end %fun
        function saturation = get_saturation(this,intLimit)
            saturation = min(100,max(0,...
                interp1(this.X,this.ECDF,intLimit,'linear','extrap')*100));
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassManager(this);
        end %fun
        function close_object(this)
            if ishandle(this.hFig)
                delete(this.hFig)
            end %if
        end %fun
        function delete_object(this)
            if ishandle(this.hFig)
                delete(this.hFig)
            end %if
            
            delete_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
            
            cpObj.hFig = nan;
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerContrastSettings;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef