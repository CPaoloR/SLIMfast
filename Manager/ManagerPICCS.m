classdef ManagerPICCS < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden,Dependent)
        FrameStart
        FrameEnd
        CorrStart
        CorrEnd
        CorrSamples
        SamplingMode
        
        Px2nm
        ActExp
        
        hImageFig
        hImage
        hImageAx
        FieldOfView
    end %properties
    properties (Hidden,Transient)
        hFig = nan;
        
        hProfilePopup
        hProfileSaveButton
        
        SamplingModes = {...
            'Linear',...
            'Logarithmic'};
        
        ROI
        
        %% Tooltips
        ToolTips = struct([]);
    end %properties
    
    methods
        %constructor
        function this = ManagerPICCS(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
            
            check_settings(this)
        end %fun
        function check_settings(this)
        end %fun
        
        function set_parameter(this)
            %check if gui already open
            if ishandle(this.hFig)
                waitfor(msgbox('PICCS MANAGER already open','INFO','help','modal'))
                figure(this.hFig)
                return
            end %if
            
            y0 = 150;
            
            scrSize = get(0, 'ScreenSize');
            this.hFig = ...
                figure(...
                'Units','pixels',...
                'Position', ...
                [0.5*(scrSize(3)-225) 0.5*(scrSize(4)-y0) 225 y0],...
                'Name', 'PICCS MANAGER',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Color', this.FamilyColor,...
                'IntegerHandle','off',...
                'Resize','off',...
                'CloseRequestFcn', @(src,evnt)close_object(this),...
                'Visible','off');
            
            y = y0 -20;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 50 15],...
                'FontSize', 8,...
                'String', 'Profile:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            get_actual_profiles(this.SrcContainer)
            this.hProfilePopup = ...
                uicontrol(...
                'Style', 'popupmenu',...
                'Units','pixels',...
                'Position', [60 y+1 115 15],...
                'FontSize', 7,...
                'String', this.SrcContainer.Profiles,...
                'Value', find(strcmp(this.SrcContainer.Profile,this.SrcContainer.Profiles)),...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_Profile(this,src));
            this.hProfileSaveButton = ...
                uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', 'Save',...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)save_actual_properties_as_profile(this.SrcContainer));
            
            y = y - 20;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 130 15],...
                'FontSize', 8,...
                'String', 'Frame Range:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [140 y 40 15],...
                'FontSize', 8,...
                'String', this.FrameStart,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FrameStart(this,src));
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.FrameEnd,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FrameEnd(this,src));
            
            y = y -20;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 135 15],...
                'FontSize', 8,...
                'String', 'Correlation Range [nm]:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [140 y 40 15],...
                'FontSize', 8,...
                'FontUnits', 'normalized',...
                'String', this.CorrStart,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_CorrStart(this,src));
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'FontUnits', 'normalized',...
                'String', this.CorrEnd,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_CorrEnd(this,src));
            
            y = y -20;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'String', '# Samples:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.CorrSamples,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_CorrSamples(this,src));
            
            y = y -25;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y+2 110 15],...
                'FontSize', 8,...
                'String', 'Sampling Mode:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'popupmenu',...
                'Units','pixels',...
                'Position', [140 y+2 80 15],...
                'FontSize', 7,...
                'String', this.SamplingModes,...
                'Value', find(strcmp(this.SamplingMode,this.SamplingModes)),...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_SamplingMode(this,src));
            
            y = y - 35;
            
            uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [25 y 75 25],...
                'FontSize', 8,...
                'String', 'Set ROI',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)set_ROI(this));
            
            uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [125 y 75 25],...
                'FontSize', 8,...
                'String', 'Estimate',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)estimate_PICCS(this.Parent));
            
            set(get(this.hFig,'Children'),...
                'Units', 'normalized',...
                'FontUnits', 'normalized',...
                'FontWeight','bold')
            set(this.hFig,...
                'Units','pixels',...
                'Position', set_figure_position(225/y0, 0.45/225*y0, 'center'),...
                'Visible','on')
        end %fun
        
        %%
        function framestart = get.FrameStart(this)
            framestart = this.SrcContainer.FrameStart;
        end %fun
        function frameend = get.FrameEnd(this)
            frameend = this.SrcContainer.FrameEnd;
        end %fun
        
        function corrstart = get.CorrStart(this)
            corrstart = this.SrcContainer.CorrStart;
        end %fun
        function corrend = get.CorrEnd(this)
            corrend = this.SrcContainer.CorrEnd;
        end %fun
        function corrsamples = get.CorrSamples(this)
            corrsamples = this.SrcContainer.CorrSamples;
        end %fun
        function samplingmode = get.SamplingMode(this)
            samplingmode = this.SrcContainer.SamplingMode;
        end %fun
        
        function px2nm = get.Px2nm(this)
            px2nm = this.Parent.Px2nm;
        end %fun
        function actexp = get.ActExp(this)
            actexp = this.Parent.ActExp;
        end %fun
        function fieldofview = get.FieldOfView(this)
            fieldofview = this.Parent.FieldOfView;
        end %fun
        function himagefig = get.hImageFig(this)
            himagefig = this.Parent.hImageFig;
        end %fun
        function himage = get.hImage(this)
            himage = this.Parent.hImage;
        end %fun
        function himageax = get.hImageAx(this)
            himageax = this.Parent.hImageAx;
        end %fun
        
        %%
        function set_Profile(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            profile = content{value};
            update_profile(this,profile)
        end %fun
        
        function set_FrameStart(this,src)
            value = min(max(...
                str2double(get(src,'String')),1), ...
                this.SrcContainer.FrameEnd);
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).FrameStart = value;
            end %for
            this.SrcContainer.FrameStart = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_FrameEnd(this,src)
            value = max(...
                str2double(get(src,'String')),...
                this.SrcContainer.FrameStart);
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).FrameEnd = value;
            end %for
            this.SrcContainer.FrameEnd = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        
        function set_CorrStart(this,src)
            value = min(max(...
                str2double(get(src,'String')),1), ...
                this.SrcContainer.CorrEnd);
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).CorrStart = value;
            end %for
            this.SrcContainer.CorrStart = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_CorrEnd(this,src)
            value = max(...
                str2double(get(src,'String')),...
                this.SrcContainer.CorrStart);
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).CorrEnd = value;
            end %for
            this.SrcContainer.CorrEnd = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_CorrSamples(this,src)
            value = max(...
                str2double(get(src,'String')),3);
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).CorrSamples = value;
            end %for
            this.SrcContainer.CorrSamples = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_SamplingMode(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).SamplingMode = content{value};
            end %for
            this.SrcContainer.SamplingMode = content{value};
            
            update_profile(this,'None')
        end %fun
        
        function set_ROI(this)
            if not(isempty(this.ROI))
                delete(this.ROI.hRoi)
            end %if
            
            fieldOfView = this.Parent.FieldOfView;
            imLim = [0 fieldOfView(5)*this.Parent.ActExp ...
                0 fieldOfView(6)*this.Parent.ActExp]+0.5;
            
            set(this.Parent.hImage,  'HitTest', 'on')
            
            repeat = true;
            while repeat
                this.ROI.hRoi = imfreehand(this.Parent.hImageAx);
                fcn = makeConstrainToRectFcn('imfreehand',...
                    imLim(1:2),imLim(3:4));
                setPositionConstraintFcn(this.ROI.hRoi,fcn);
                
                if generate_binary_decision_dialog('',{'Accept defined ROI?'});
                    repeat = false;
                    
                    this.ROI.Vert = getPosition(this.ROI.hRoi); %[x y]
                    this.ROI.Mask = createMask(this.ROI.hRoi);
                    this.ROI.Area = bwarea(this.ROI.Mask);
                    this.ROI.RectHull = [round(min(this.ROI.Vert(:,1))),round(max(this.ROI.Vert(:,1))),...
                        round(min(this.ROI.Vert(:,2))),round(max(this.ROI.Vert(:,2)))]; %[xmin xmax ymin ymax]
                else
                    if generate_binary_decision_dialog('',{'Repeat ROI definition?'});
                        delete(this.ROI.hRoi)
                    else
                        this.ROI = [];
                        
                        return
                    end %if
                end %if
                
                set(this.Parent.hImage, 'HitTest', 'off')
            end %while
        end %fun
        
        function update_profile(this,profile)
            this.SrcContainer.Profile = profile;
            switch profile
                case 'None'
                    set(this.hProfilePopup,'Value',...
                        find(strcmp('None',this.SrcContainer.Profiles)))
                case 'Standard'
                    set_standard_properties(this.SrcContainer)
                    check_settings(this)
                    
                    close_object(this)
                    set_parameter(this)
                otherwise
                    SLIMfastPath = getappdata(0,'SLIMfastPath');
                    filename = fullfile(SLIMfastPath, ...
                        'Profiles', [this.SrcContainer.Profile '.txt']);
                    load_settings_from_disc(this.SrcContainer,filename)
                    check_settings(this)
                    
                    close_object(this)
                    set_parameter(this)
            end %switch
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
            this = ManagerPICCS;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef