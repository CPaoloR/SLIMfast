classdef ManagerJumpSeries < SuperclassManager
    
    properties
        Sampling = 2^8;
        
        FitStart
        FitEnd
        
        objMasterMixModelSettings
        
        ExportBin
    end %properties
    properties (Hidden,Transient)
        DisplayWin %[frames]
        
        Displacement %[nm]
        NumPnts
        
        Dt
        MaxDt
        
        EstDensity
        X
        Y
        PDF
        CDF
        
        objMixModelSettings
        
        hJumpSeriesFig = nan;
        hJumpSeriesAx
        hJumpSeriesToolbar
        hSurf
        hLine
        hJumpSeriesSlider
        hDtEdit
        hPlayButton
        
        hInfoCritFig
        InfoCrit
        hComplexityPopupmenu
        
        hMsdFig
        hMsdAx
        hMsdToolbar
        hMsdLine
    end %properties
    
    methods
        function this = ManagerJumpSeries(parent)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
        end %constructor
        
        function initialize_jumpsize_series(this,objData)
            %check if gui already open
            if ishandle(this.hJumpSeriesFig)
                waitfor(msgbox('JUMPSIZE SERIES MANAGER already open','INFO','help','modal'))
                figure(this.hJumpSeriesFig)
                return
            end %if
            
            this.objMasterMixModelSettings = ManagerMixedDistSettings(this);
            initialize_model_parameters(...
                this.objMasterMixModelSettings,[],'Rayl')
            
            if numel(objData) == 1         
            displacement = sqrt(vertcat(objData.objIndividual(objData.ActiveIdx).SD))*1000; %[nm]
            dt = vertcat(objData.objIndividual(objData.ActiveIdx).SdDeltaT);
            else
                displacement = cell2mat(arrayfun(...
                    @(x)get_all_particle_jumps(x,'Unit','nm'),objData,'Un',0));
                dt = cell2mat(arrayfun(...
                    @(x)get_all_frame_jumps(x),objData,'Un',0));
            end %if
            
            this.MaxDt = max(dt);
            this.Displacement = accumarray(dt,displacement,[this.MaxDt 1],@(x){x});
            this.NumPnts = cellfun('size',this.Displacement,1);
            
            calculate_density_matrix(this);
            
            this.DisplayWin = min(this.MaxDt,30);
            this.Dt = this.DisplayWin;
            
            this.FitStart = 1;
            this.FitEnd = this.MaxDt;
            
            this.hJumpSeriesFig =...
                figure(...
                'Units','pixels',...
                'Position', set_figure_position(1.5,0.75,'center'),...
                'Color', this.FamilyColor,...
                'Name', 'JUMPSIZE SERIES MANAGER',...
                'NumberTitle', 'off',...
                'DockControls', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'IntegerHandle', 'off',...
                'CloseRequestFcn',@(src,evnt)close_object(this));
            
            this.hJumpSeriesToolbar = uitoolbar(...
                'Parent',this.hJumpSeriesFig);
            icon = getappdata(0,'icon');
            uitoggletool(...
                'Parent',this.hJumpSeriesToolbar,...
                'Separator','on',...
                'CData', icon.('Zoom'),...
                'Tag','Zoom',...
                'ClickedCallback', @(src,evnt)set_zoom(src,'hFig',this.hJumpSeriesFig))
            uitoggletool(...
                'Parent',this.hJumpSeriesToolbar,...
                'CData', icon.('Pan'),...
                'Tag','Pan',...
                'ClickedCallback', @(src,evnt)set_pan(src,'hFig',this.hJumpSeriesFig))
            uitoggletool(...
                'Parent',this.hJumpSeriesToolbar,...
                'CData', icon.('Rotate'),...
                'Tag','Rotate',...
                'ClickedCallback', @(src,evnt)set_rotate(src,'hAx',this.hJumpSeriesAx))
            uipushtool(...
                'Parent', this.hJumpSeriesToolbar,...
                'CData', icon.('Jumpsize_Distribution'),...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,'Jumpsize Distribution',this))
            
            uipushtool(...
                'Parent', this.hJumpSeriesToolbar,...
                'CData', icon.('Fit'),...
                'ClickedCallback', @(src,evnt)set_estimation_parameter(this));
            
            this.hJumpSeriesAx = ...
                axes(...
                'Parent', this.hJumpSeriesFig,...
                'Units', 'normalized',...
                'OuterPosition', [0.1 0.2 0.8 0.7],...
                'FontSize', 24,...
                'NextPlot', 'add',...
                'XDir', 'reverse',...
                'ZGrid', 'on',...
                'CLimMode', 'manual',...
                'Box','on',...
                'Projection','perspective',...
                'CLim', [0 max(this.PDF(:))]);
            
            this.hSurf = surf(this.hJumpSeriesAx, ...
                this.X(1:this.DisplayWin,:),...
                this.Y(1:this.DisplayWin,:),...
                this.PDF(1:this.DisplayWin,:));
            
            lightangle(0,30)
            set(this.hSurf,...
                'EdgeColor', 'none',...
                'FaceColor', 'interp',...
                'FaceLighting','phong',...
                'AmbientStrength',.3,...
                'DiffuseStrength',.8,...
                'SpecularStrength',1,...
                'SpecularExponent',15,...
                'BackFaceLighting','reverselit')
            
            this.hLine = ...
                line(...
                'XData',this.X(this.DisplayWin,:),...
                'YData',this.Y(this.DisplayWin,:),...
                'ZData',this.PDF(this.DisplayWin,:),...
                'Color', [1 0 0],...
                'LineWidth', 3);
            
            axis('vis3d','tight')
            view(-160,10)
            
            ylabel(this.hJumpSeriesAx,'Delay Time [frame]')
            xlabel(this.hJumpSeriesAx, 'Displacement [nm]')
            zlabel(this.hJumpSeriesAx, sprintf('Probability Density'))
            
            this.hJumpSeriesSlider = ...
                uicontrol(...
                'Style', 'slider',...
                'Units', 'normalized',...
                'Position', [0.1 0 0.8 0.05],...
                'Min', 1,...
                'Max', this.MaxDt,...
                'Value', this.Dt,....
                'SliderStep', [1 1]/(this.MaxDt));
            addlistener(this.hJumpSeriesSlider,'ContinuousValueChange',...
                @(src,event)update_jumpsize_series(this));
            
            this.hDtEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Units','normalized',...
                'Position', [0.9 0 0.1 0.05],...
                'FontSize', 15,...
                'String', this.Dt,...
                'Callback', @(src,evnt)set_Dt(this));
            
            this.hPlayButton = ...
                uicontrol(...
                'Style', 'togglebutton',...
                'Units','normalized',...
                'Position', [0 0 0.1 0.05],...
                'FontSize', 15,...
                'String', 'Play',...
                'Callback', @(src,evnt)play_slider(this));
        end %fun
        function update_jumpsize_series(this)
            sliderPos = round(get(this.hJumpSeriesSlider,'Value'));
            newDisplayWin = sliderPos-this.DisplayWin:sliderPos;
            good = newDisplayWin > 0;
            newDisplayWin = newDisplayWin(good);
            
            %update graph
            set(this.hSurf,...
                'XData',this.X(newDisplayWin,:),...
                'YData',this.Y(newDisplayWin,:),...
                'ZData',this.PDF(newDisplayWin,:))
            set(this.hLine,...
                'XData',this.X(newDisplayWin(end),:),...
                'YData',this.Y(newDisplayWin(end),:),...
                'ZData',this.PDF(newDisplayWin(end),:));
            ylim([newDisplayWin(1) max(2,newDisplayWin(end))])
            
            %update dt value and editbox
            this.Dt = newDisplayWin(end);
            set(this.hDtEdit,'String',newDisplayWin(end))
        end %nested0
        
        function calculate_density_matrix(this)
            hProgressbar = ClassProgressbar({'Probability Surface Construction...'});
            
            this.EstDensity = zeros(this.Sampling,this.MaxDt,4);
            for dt = 1:this.MaxDt
                if this.NumPnts(dt) > 1
                    [~,this.EstDensity(:,dt,1),...
                        this.EstDensity(:,dt,3),...
                        this.EstDensity(:,dt,2)] =...
                        kde(this.Displacement{dt},this.Sampling);
                    this.EstDensity(:,dt,4) = ones(this.Sampling,1)*dt;
                end %if
                update_progressbar(hProgressbar,{dt/this.MaxDt*0.9})
            end %for
            
            %generate x-y-matrix
            [this.X,this.Y] = meshgrid(...
                linspace(min(this.EstDensity(1,:,3)),...
                max(this.EstDensity(end,:,3)),this.Sampling),1:this.MaxDt);
            
            %interpolate to x-y-matrix
            funPDF = TriScatteredInterp(...
                reshape(this.EstDensity(:,:,3),[],1),...
                reshape(this.EstDensity(:,:,4),[],1),...
                reshape(this.EstDensity(:,:,1),[],1));
            this.PDF = funPDF(this.X,this.Y);
            this.PDF(isnan(this.PDF)) = 0;
            
            update_progressbar(hProgressbar,{0.95})
            
            funCDF = TriScatteredInterp(...
                reshape(this.EstDensity(:,:,3),[],1),...
                reshape(this.EstDensity(:,:,4),[],1),...
                reshape(this.EstDensity(:,:,2),[],1));
            this.CDF = funCDF(this.X,this.Y);
            this.CDF(isnan(this.PDF)) = 0;
            
            close_progressbar(hProgressbar)
        end %fun
        
        function set_Dt(this)
            value = max(1,min(this.MaxDt,...
                str2double(get(this.hDtEdit,'String'))));
            this.Dt = value;
            set(this.hDtEdit,'String',value)
            
            %update slider position
            set(this.hJumpSeriesSlider,'Value', value)
            %update graph
            update_jumpsize_series(this)
        end %fun
        function set_FitStart(this,src)
            value = max(1,min(this.FitEnd,...
                str2double(get(src,'String'))));
            
            this.FitStart = value;
            set(src,'String',value)
        end %fun
        function set_FitEnd(this,src)
            value = max(this.FitStart,min(this.MaxDt,...
                str2double(get(src,'String'))));
            
            this.FitEnd = value;
            set(src,'String',value)
        end %fun
        
        function play_slider(this)
            step = 1;
            while ishandle(this.hJumpSeriesFig) && get(this.hPlayButton,'Value')
                actSliderPos = get(this.hJumpSeriesSlider,'Value');
                
                %change step direction when at the ends
                if actSliderPos+step < get(this.hJumpSeriesSlider,'Min') ||...
                        actSliderPos+step > get(this.hJumpSeriesSlider,'Max')
                    step = -1*step;
                end %if
                set(this.hJumpSeriesSlider,'Value', actSliderPos+step)
                
                %update graph
                update_jumpsize_series(this)
                pause(0.1)
            end %while
        end %fun
        
        function set_estimation_parameter(this)
            set_parameter(this.objMasterMixModelSettings)
            
            %restore original size
            scrSize = get(0, 'ScreenSize');
            drawnow
            set(this.objMasterMixModelSettings.hEstFig,'Units','pixels',...
                'Position', [0.5*(scrSize(3)-225) 0.5*(scrSize(4)-170) 225 170])
            hList = allchild(this.objMasterMixModelSettings.hEstFig);
            set(hList,'Units','pixels')
            
            %add fit range fields
            set(this.objMasterMixModelSettings.hEstFig,'Position',...
                get(this.objMasterMixModelSettings.hEstFig,'Position')+[-10 0 0 20])
            
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 170 170 15],...
                'FontSize', 8,...
                'String', 'Fitrange:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [140 170 40 15],...
                'FontSize', 8,...
                'String', this.FitStart,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FitStart(this,src));
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 170 40 15],...
                'FontSize', 8,...
                'String', this.FitEnd,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FitEnd(this,src));
            
            set(get(this.objMasterMixModelSettings.hEstFig,'Children'),...
                'Units', 'normalized',...
                'FontUnits', 'normalized',...
                'FontWeight','bold')
            set(this.objMasterMixModelSettings.hEstFig,'Units','pixels',...
                'Position', set_figure_position(225/190, 0.39,'center'))
            
            %redirect estimation function
            set(this.objMasterMixModelSettings.hEstButton,...
                'Callback',@(src,evnt)estimate_parameter(this))
        end %fun
        function estimate_parameter(this)
            if ishandle(this.objMasterMixModelSettings.hEstFig)
                delete(this.objMasterMixModelSettings.hEstFig)
            end %if
            
            hProgressbar = ClassProgressbar({'MSD Curve Construction...',...
                'Estimation Process...','Model Evaluation...'});
            
            this.objMixModelSettings = ManagerMixedDistSettings.empty(this.FitEnd,0);
            this.InfoCrit = [];
            for dt = 1:this.FitEnd
                this.objMixModelSettings(dt) = ManagerMixedDistSettings(this);
                if dt >= this.FitStart
                    %initialize object (derived from master object)
                    this.objMixModelSettings(dt).SrcContainer = this.objMasterMixModelSettings.SrcContainer;
                    this.objMixModelSettings(dt).Data = this.Displacement{dt};
                    this.objMixModelSettings(dt).NumPoints = this.NumPnts(dt);
                    this.objMixModelSettings(dt).DistFamily = 'Rayl';
                    
                    if this.objMasterMixModelSettings.UseInfoCrit
                        this.objMixModelSettings(dt).Candidates = ...
                            ClassMixedDistribution.empty(this.objMasterMixModelSettings.MaxMix,0);
                        for complexity = 1:this.objMasterMixModelSettings.MaxMix
                            this.objMixModelSettings(dt).Candidates(complexity) = ...
                                copy(this.objMasterMixModelSettings.Candidates(complexity));
                            
                            %update parent
                            this.objMixModelSettings(dt).Candidates(complexity).Parent = this.objMixModelSettings(dt);
                            isOK = estimate_model_parameter(this.objMixModelSettings(dt).Candidates(complexity),hProgressbar);
                            if isOK
                            calculate_information_criteria(this.objMixModelSettings(dt).Candidates(complexity));
                            this.InfoCrit(complexity,dt,1) = this.objMixModelSettings(dt).Candidates(complexity).AIC;
                            this.InfoCrit(complexity,dt,2) = this.objMixModelSettings(dt).Candidates(complexity).BIC;
                            else
                                this.InfoCrit(complexity,dt,:) = inf;
                            end %if
                            update_progressbar(hProgressbar,{[],complexity/this.objMasterMixModelSettings.MaxMix,[]})
                        end %for
                    else
                        this.objMixModelSettings(dt).Candidate = ...
                            copy(this.objMasterMixModelSettings.Candidate);
                        
                        %update parent
                        this.objMixModelSettings(dt).Candidate.Parent = this.objMixModelSettings(dt);
                        isOK = estimate_model_parameter(this.objMixModelSettings(dt).Candidate,hProgressbar);
                        if ~isOK
                            waitfor(errordlg(sprintf(...
                                'Errorhandling not implemented yet!\nPlease adjust Fitting Parameter to avoid Error'),'CRITICAL','modal'))
                            return
                        end %if
                        update_progressbar(hProgressbar,{[],1,[]})
                    end %if
                    update_progressbar(hProgressbar,{(dt-this.FitStart+1)/(this.FitEnd-this.FitStart+1),[],[]})
                end %if
            end %for
            update_progressbar(hProgressbar,{1,1,1})
            pause(0.1)
            close_progressbar(hProgressbar)
            
            if this.objMasterMixModelSettings.UseInfoCrit
                apply_information_criteria(this)
            else
                plot_msd_curve(this)
            end %if
        end %fun
        function apply_information_criteria(this)
            this.hInfoCritFig = ...
                figure(...
                'Color', this.FamilyColor,...
                'Units','pixels',...
                'Position', set_figure_position(1.8,0.5,'center'),...
                'Name', 'MODEL SELECTION',...
                'NumberTitle', 'off',...
                'DockControls', 'off',...
                'MenuBar', 'none',...
                'IntegerHandle','off',...
                'ToolBar', 'figure',...
                'Resize','off');
            
            hToolbar = findall(this.hInfoCritFig,'Type','uitoolbar');
            hToggleList = findall(hToolbar);
            delete(hToggleList([2:9 13:17]))
            
            ax(1) = ...
                axes(...
                'Units','normalized',...
                'Position', [0.2 0.51 0.6 0.29],...
                'XTickLabel','',...
                'YTickLabel','',...
                'NextPlot', 'add');
            ylabel('AIC')
            ax(2) = ...
                axes(...
                'Units','normalized',...
                'Position', [0.2 0.2 0.6 0.29],...
                'YTickLabel','',...
                'NextPlot', 'add');
            xlabel('dt [frame]')
            ylabel('BIC')
            
            colormap(lines(this.objMasterMixModelSettings.MaxMix));
            %calculate information criteria weights
            this.InfoCrit(:,:,1) = exp(bsxfun(@minus,min(this.InfoCrit(:,:,1)),this.InfoCrit(:,:,1))/2);
            this.InfoCrit(:,:,1) = bsxfun(@rdivide,this.InfoCrit(:,:,1),sum(this.InfoCrit(:,:,1)));
            bar(ax(1),this.InfoCrit(:,:,1)',1,'BarLayout','stacked','EdgeColor','none')
            
            this.InfoCrit(:,:,2) = exp(bsxfun(@minus,min(this.InfoCrit(:,:,2)),this.InfoCrit(:,:,2))/2);
            this.InfoCrit(:,:,2) = bsxfun(@rdivide,this.InfoCrit(:,:,2),sum(this.InfoCrit(:,:,2)));
            bar(ax(2),this.InfoCrit(:,:,2)',1,'BarLayout','stacked','EdgeColor','none')
            
            axis(ax, 'tight')
            linkaxes(ax,'x')
            zoom xon
            
            legend(cellstr(num2str((1:this.objMasterMixModelSettings.MaxMix)')),...
                'FontSize', 12, 'Location',[0.85 0.25 0.1 0.5])
            
            uicontrol(...
                'Style', 'Text',...
                'Units','normalized',...
                'Position', [0 0.9 0.8 0.1],...
                'FontSize', 20,...
                'String', 'Choose final Complexity:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'right');
            
            this.hComplexityPopupmenu = ...
                uicontrol(...
                'Style', 'popupmenu',...
                'Units','normalized',...
                'Position', [0.8 0.9 0.1 0.1],...
                'FontSize', 17,...
                'String', cellstr(num2str((1:this.objMasterMixModelSettings.MaxMix)')),...
                'Value', 1);
            
            uicontrol(...
                'Style', 'pushbutton',...
                'Units','normalized',...
                'Position', [0.9 0.9 0.1 0.1],...
                'FontSize', 18,...
                'String', 'OK',...
                'Callback', @(src,evnt)set_model_complexity(this));
        end %fun
        function set_model_complexity(this)
            this.objMasterMixModelSettings.SrcContainer.NumMix = ...
                get(this.hComplexityPopupmenu,'Value');
            for idx = this.FitStart:this.FitEnd
                this.objMixModelSettings(idx).Candidate = ...
                    this.objMixModelSettings(idx).Candidates(...
                    this.objMasterMixModelSettings.NumMix);
            end %for
            delete(this.hInfoCritFig)
            
            plot_msd_curve(this)
        end %fun
        
        function plot_msd_curve(this)
            for idx = this.FitEnd:-1:this.FitStart
                result = cell2mat(...
                    [this.objMixModelSettings(idx).Candidate.objModel.EstValue]);
                [msdList(idx,:) sortIdx] = sort((result(2:2:end)/1000).^2);
                fracList(idx,sortIdx) = result(1:2:end);
                result = max(0,cell2mat(...
                    [this.objMixModelSettings(idx).Candidate.objModel.CI]));
                msdCiList(idx,sortIdx) = (result(2:2:end)/1000).^2;
                fracCiList(idx,sortIdx) = result(1:2:end);
            end %for
            % fill ExportBin
            this.ExportBin = struct(...
                'Header', struct(...
                'Diff_Pop','Estimated diffusive Subspecies (dt [s] | w [x100%] | 95% CI [x100%])',...
                'MSD_Curve','MSD vs. Time Plot (dt [s] | <dx^2>) [�m^2] | 95% CI [�m^2]'),...
                'Data', struct(...
                'Diff_Pop', [(this.FitStart:this.FitEnd)'*this.Parent.Frame2msec/1000,...
                fracList fracCiList],...
                'MSD_Curve', [...
                (this.FitStart:this.FitEnd)'*this.Parent.Frame2msec/1000,...
                msdList msdCiList]));
            
            this.hMsdFig = ...
                figure(...
                'Color', this.FamilyColor,...
                'Units','pixels',...
                'Position', set_figure_position(1.7,0.7,'center'),...
                'Name', 'DIFFSUION COEFFICIENT',...
                'NumberTitle', 'off',...
                'DockControls', 'off',...
                'IntegerHandle','off',...
                'MenuBar', 'none',...
                'ToolBar', 'none');
            
            this.hMsdToolbar = uitoolbar('Parent',this.hMsdFig);
            icon = getappdata(0,'icon');
            uipushtool(...
                'Parent',this.hMsdToolbar,...
                'CData', icon.('Save_Data'),...
                'ClickedCallback', @(src,evnt)write_variable_to_ascii(this));
            uipushtool(...
                'Parent',this.hMsdToolbar,...
                'CData', icon.('Fit'),...
                'ClickedCallback', @(src,evnt)set_parameter(this.Parent.objDiffCoeffFit,this),...
                'Enable','off');
            
            this.hMsdAx = ...
                axes(...
                'Units','normalized',...
                'OuterPosition', [0.05 0.05 0.9 0.9],...
                'NextPlot', 'add');
            
            cmap = lines(this.objMasterMixModelSettings.NumMix);
            dt = (this.FitStart:this.FitEnd)';
            for subpop = 1:this.objMasterMixModelSettings.NumMix
                patch([dt; flipud(dt)]*this.Parent.Frame2msec/1000,...
                    [msdList(dt,subpop)-msdCiList(dt,subpop); ...
                    flipud(msdList(dt,subpop)+msdCiList(dt,subpop))],...
                    cmap(subpop,:), ...
                    'FaceAlpha',0.7,...
                    'Parent', this.hMsdAx)
                line(dt*this.Parent.Frame2msec/1000,msdList(dt,subpop),....
                    'Parent',this.hMsdAx,...
                    'Color', [0 0 0],...
                    'Marker', '.',...
                    'MarkerSize', 5)
            end %for
            xlabel('dt [s]')
            ylabel('MSD [�m^2]')
            
            axis tight
        end %fun
        function estimate_diffusion_coefficient(this)
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassManager(this);
        end %fun
        function close_object(this)
            if ishandle(this.hJumpSeriesFig)
                delete(this.hJumpSeriesFig)
            end %if
            if ishandle(this.hInfoCritFig)
                delete(this.hInfoCritFig)
            end %if
            if ishandle(this.hMsdFig)
                delete(this.hMsdFig)
            end %if
        end %fun
        function delete_object(this)
            if ishandle(this.hJumpSeriesFig)
                delete(this.hJumpSeriesFig)
            end %if
            if ishandle(this.hInfoCritFig)
                delete(this.hInfoCritFig)
            end %if
            if ishandle(this.hMsdFig)
                delete(this.hMsdFig)
            end %if
            
            delete_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
            
            cpObj.hJumpSeriesFig = nan;
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerJumpSeries;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef