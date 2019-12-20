classdef ManagerCoLocSettings < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden,Dependent)
        UseFixedDist
        DistThresh
        ProbMiss
        InterMolDist
        CoLocMode
    end %properties
    properties (Hidden,Transient)
        hFig = nan;
        hDistThreshCheckbox
        hDistThreshEdit
        hProbMissCheckbox
        hProbMissEdit
        hCoLocTestButton
        hCoLocButton
        hProfilePopup
        
        CoLocModes = {...
            'inclusive',...
            'exclusive'};
        
        %% Tooltips
        ToolTips = struct([]);
    end %properties
    
    methods
        %% constructor
        function this = ManagerCoLocSettings(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
            
            if nargin > 0
                check_settings(this)
            end %if
        end %fun
        function check_settings(this)
        end %fun
        
        %%
        function set_parameter(this)
            %check if gui already open
            if ishandle(this.hFig)
                waitfor(msgbox('COLOCALIZATION MANAGER already open','INFO','help','modal'))
                figure(this.hFig)
                return
            end %if
            
            y0 = 130;
            
            scrSize = get(0, 'ScreenSize');
            this.hFig = ...
                figure(...
                'Units','pixels',...
                'Position', ...
                [0.5*(scrSize(3)-225) 0.5*(scrSize(4)-y0) 225 y0],...
                'Name', 'COLOCALIZATION MANAGER',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Color', this.FamilyColor,...
                'IntegerHandle','off',...
                'Resize','off',...
                'CloseRequestFcn', @(src,evnt)close_object(this));
            
            y = y0 - 20;
            this.hDistThreshCheckbox = ...
                uicontrol(...
                'Style', 'checkbox',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'BackgroundColor', this.FamilyColor,...
                'String', 'Max. Co-Loc. Distance [nm]:',...
                'Value', this.UseFixedDist,...
                'Callback', @(src,evnt)set_UseFixedDist(this,src));
            
            this.hDistThreshEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.DistThresh,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_DistThresh(this,src));
            if ~this.UseFixedDist
                set(this.hDistThreshEdit,'Enable','off')
            end %if
            
            y = y - 20;
            this.hProbMissCheckbox = ...
                uicontrol(...
                'Style', 'checkbox',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'BackgroundColor', this.FamilyColor,...
                'String', 'Co-Loc. Miss Probability [10^]:',...
                'Value', ~this.UseFixedDist,...
                'Callback', @(src,evnt)set_UseFixedDist(this,src));
            
            this.hProbMissEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.ProbMiss,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_ProbMiss(this,src));
            if this.UseFixedDist
                set(this.hProbMissEdit,'Enable','off')
            end %if
            
            y = y -20;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'String', 'Intermolecular Distance [nm]:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.InterMolDist,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_InterMolDist(this,src));
            
            y = y -25;
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y+2 110 15],...
                'FontSize', 8,...
                'String', 'Co-Localization Mode:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            
            uicontrol(...
                'Style', 'popupmenu',...
                'Units','pixels',...
                'Position', [140 y+2 80 15],...
                'FontSize', 7,...
                'String', this.CoLocModes,...
                'Value', find(strcmp(this.CoLocMode,this.CoLocModes)),...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_CoLocMode(this,src));
            
            y = y -35;
            
            this.hCoLocTestButton = ...
                uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [25 y 75 25],...
                'FontSize', 8,...
                'String', 'Test',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            this.hCoLocButton = ...
                uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [125 y 75 25],...
                'FontSize', 8,...
                'String', 'Co-Localize',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)find_co_localization_events(this.Parent));
            
            set(get(this.hFig,'Children'),...
                'Units', 'normalized',...
                'FontUnits', 'normalized',...
                'FontWeight','bold')
            set(this.hFig,'Units','pixels',...
                'Position', set_figure_position(225/y0, 0.45/225*y0, 'center'))
        end %fun
        
        %% setter
        function set_Profile(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            profile = content{value};
            update_profile(this,profile)
        end %fun
        
        function set_UseFixedDist(this,src)
            if eq(src,this.hDistThreshCheckbox)
                this.SrcContainer.UseFixedDist = 1;
                set(this.hDistThreshEdit,'Enable','on')
                
                set(this.hDistThreshCheckbox,'Value',1)
                set(this.hProbMissCheckbox,'Value',0)
                set(this.hProbMissEdit,'Enable','off')
            else
                this.SrcContainer.UseFixedDist = 0;
                set(this.hProbMissEdit,'Enable','on')
                
                set(this.hProbMissCheckbox,'Value',1)
                set(this.hDistThreshCheckbox,'Value',0)
                set(this.hDistThreshEdit,'Enable','off')
            end %if
            
            update_profile(this,'None')
        end %fun
        function set_DistThresh(this,src)
            value = max(1,str2double(get(src,'String')));
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).DistThresh = value;
            end %for
            this.SrcContainer.DistThresh = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_ProbMiss(this,src)
            value = min(0,str2double(get(src,'String')));
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).ProbMiss = value;
            end %for
            this.SrcContainer.ProbMiss = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_InterMolDist(this,src)
            value = max(0,str2double(get(src,'String')));
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).InterMolDist = value;
            end %for
            this.SrcContainer.InterMolDist = value;
            
            set(src,'String', value)
            update_profile(this,'None')
        end %fun
        function set_CoLocMode(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            numTargets = numel(this.TargetContainer);
            for idx = 1:numTargets
                this.TargetContainer(idx).CoLocMode = content{value};
            end %for
            this.SrcContainer.CoLocMode = content{value};
            
            update_profile(this,'None')
        end %fun
        
        %% getter
        function usefixeddist = get.UseFixedDist(this)
            usefixeddist = this.SrcContainer.UseFixedDist;
        end %fun
        function distthresh = get.DistThresh(this)
            distthresh = this.SrcContainer.DistThresh;
        end %fun
        function probmiss = get.ProbMiss(this)
            probmiss = this.SrcContainer.ProbMiss;
        end %fun
        function intermoldist = get.InterMolDist(this)
            intermoldist = this.SrcContainer.InterMolDist;
        end %fun
        function colocmode = get.CoLocMode(this)
            colocmode = this.SrcContainer.CoLocMode;
        end %fun
        
        %%
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
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerCoLocSettings;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef