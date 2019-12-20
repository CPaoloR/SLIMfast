classdef ManagerMsdCurveFit < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        EffFitStart
        EffFitEnd
        EffFitRange
    end %properties
    properties (Hidden,Dependent)
        CutOffMode
        FitStart
        FitEnd
        
        DiffModel
        %         YHat
        
        MaxIter
        TolFun
    end %properties
    properties (Hidden,Transient)
        hFig = nan;
        hFitStartEdit
        hFitEndEdit
        
        DiffModels = ...
            {'Free Diffusion',...
            'Anomalous Diffusion',...
            'Transport'};
        CutOffModes = {...
            'Absolute',...
            'Relative'};
    end %properties
    
    methods
        %constructor
        function this = ManagerMsdCurveFit(parent)
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
        
        function set_parameter(this,objEntity)
            %check if gui already open
            if ishandle(this.hFig)
                waitfor(msgbox('MSD CURVE ESTIMATOR already open','INFO','help','modal'))
                figure(this.hFig)
                return
            end %if
            
            y0 = 150;
            
            scrSize = get(0, 'ScreenSize');
            this.hFig = figure(...
                'Units','pixels',...
                'Position', ...
                [0.5*(scrSize(3)-225) 0.5*(scrSize(4)-y0) 225 y0],...
                'Name', 'MSD CURVE ESTIMATOR',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Color', this.FamilyColor,...
                'Resize', 'off',...
                'IntegerHandle','off');
            
            y = y0 -20;
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 80 15],...
                'FontSize', 8,...
                'String', 'Fit Range:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            this.hFitStartEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [140 y 40 15],...
                'FontSize', 8,...
                'FontUnits', 'normalized',...
                'String', this.FitStart,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FitStart(this,src));
            
            this.hFitEndEdit = ...
                uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'FontUnits', 'normalized',...
                'String', this.FitEnd,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_FitEnd(this,src));
            
            y = y -23;
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y+1.5 80 15],...
                'FontSize', 8,...
                'String', 'Range Mode:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'popupmenu',...
                'Units','pixels',...
                'Position', [140 y+1.5 80 15],...
                'FontSize', 7,...
                'String', this.CutOffModes,...
                'Value', find(strcmp(this.CutOffMode,this.CutOffModes)),...
                'Callback', @(src,evnt)set_CutOffMode(this,src));
            
            y = y -23;
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y+1.5 80 15],...
                'FontSize', 8,...
                'String', 'Model:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'popupmenu',...
                'Units','pixels',...
                'Position', [85 y+1.5 135 15],...
                'FontSize', 7,...
                'String', this.DiffModels,...
                'Value', find(strcmp(this.DiffModel,this.DiffModels)),...
                'Callback', @(src,evnt)set_DiffModel(this,src));
            
            y = y - 20;
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'String', 'Max. # Iterations:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.MaxIter,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_MaxIter(this,src));
            
            y = y - 20;
            uicontrol(...
                'Style', 'Text',...
                'Units','pixels',...
                'Position', [5 y 170 15],...
                'FontSize', 8,...
                'String', 'Termination Tolerance [10^]:',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            
            uicontrol(...
                'Style', 'edit',...
                'Units','pixels',...
                'Position', [180 y 40 15],...
                'FontSize', 8,...
                'String', this.TolFun,...
                'BackgroundColor', [1 1 1],...
                'Callback', @(src,evnt)set_TolFun(this,src));
            
            y = y -35;
            hAcceptButton = ...
                uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [125 y 75 25],...
                'FontSize', 8,...
                'String', 'Accept',...
                'BackgroundColor', this.FamilyColor,...
                'HorizontalAlignment', 'left');
            if isempty(objEntity)
                set(hAcceptButton,...
                    'Callback', @(src,evnt)update_diff_coeff_fits(this.Parent))
            else
                set(hAcceptButton,...
                    'Callback', @(src,evnt)update_individual_data(objEntity,[]))
            end %if
            
            set(get(this.hFig,'Children'),...
                'Units', 'normalized',...
                'FontUnits', 'normalized',...
                'FontWeight','bold')
            set(this.hFig,'Units','pixel',...
                'Position', set_figure_position(225/y0, 0.45/225*y0, 'center'))
        end %fun
        
        %% getter
        function cutoffmode = get.CutOffMode(this)
            cutoffmode = this.SrcContainer.CutOffMode;
        end %fun
        function fitstart = get.FitStart(this)
            fitstart = this.SrcContainer.FitStart;
        end %fun
        function fitend = get.FitEnd(this)
            fitend = this.SrcContainer.FitEnd;
        end %fun
        function diffmodel = get.DiffModel(this)
            diffmodel = this.SrcContainer.DiffModel;
        end %fun
        function maxiter = get.MaxIter(this)
            maxiter = this.SrcContainer.MaxIter;
        end %fun
        function tolfun = get.TolFun(this)
            tolfun = this.SrcContainer.TolFun;
        end %fun
        
        %% setter
        function set_CutOffMode(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            this.SrcContainer.CutOffMode = content{value};
            
            switch this.CutOffMode
                case 'Absolute'
                    this.SrcContainer.FitStart = 1;
                    set(this.hFitStartEdit,'String',this.FitStart)
                    this.SrcContainer.FitEnd = 3;
                    set(this.hFitEndEdit,'String',this.FitEnd)
                case 'Relative'
                    this.SrcContainer.FitStart = 0;
                    set(this.hFitStartEdit,'String',this.FitStart)
                    this.SrcContainer.FitEnd = 33;
                    set(this.hFitEndEdit,'String',this.FitEnd)
            end %switch
        end %fun
        function set_FitStart(this,src)
            switch this.CutOffMode
                case 'Absolute'
                    this.SrcContainer.FitStart = max(1,min(this.FitEnd-1,...
                        str2double(get(src,'String'))));
                case 'Relative'
                    this.SrcContainer.FitStart = max(0,min(this.FitEnd,...
                        str2double(get(src,'String'))));
            end %switch
            set(src,'String', this.SrcContainer.FitStart)
        end %fun
        function set_FitEnd(this,src)
            switch this.CutOffMode
                case 'Absolute'
                    this.SrcContainer.FitEnd = max(this.FitStart+1,...
                        str2double(get(src,'String')));
                case 'Relative'
                    this.SrcContainer.FitEnd = max(this.FitStart,min(100,...
                        str2double(get(src,'String'))));
            end %switch
            set(src,'String', this.SrcContainer.FitEnd)
        end %fun
        function set_DiffModel(this,src)
            content = get(src,'String');
            value = get(src,'Value');
            
            this.SrcContainer.DiffModel = content{value};
        end %fun
        function set_MaxIter(this,src)
            this.SrcContainer.MaxIter = max(...
                str2double(get(src,'String')),1);
            set(src,'String', this.SrcContainer.MaxIter)
        end %fun
        function set_TolFun(this,src)
            this.SrcContainer.TolFun = str2double(get(src,'String'));
        end %fun
        
        %%
        function fit_diffusion_coefficient(this,objEntity)
            switch this.CutOffMode
                case 'Absolute'
                    this.EffFitStart = min(max(objEntity.MsdDeltaT)-1,this.FitStart);
                    this.EffFitEnd = min(max(objEntity.MsdDeltaT),max(this.EffFitStart+1,this.FitEnd));
                case 'Relative'
                    this.EffFitStart = min(max(objEntity.MsdDeltaT)-1,...
                        max(1,unidinv(this.FitStart/100,range(objEntity.MsdDeltaT)+1)));
                    this.EffFitEnd = max(this.EffFitStart+1,...
                        unidinv(this.FitEnd/100,range(objEntity.MsdDeltaT)+1));
            end %switch
            this.EffFitRange = this.EffFitEnd-this.EffFitStart+1;
            
            %crop fit range
            dt = objEntity.MsdDeltaT(this.EffFitStart:this.EffFitEnd)*this.Parent.Frame2msec/1000;
            msd = objEntity.MSD(this.EffFitStart:this.EffFitEnd);
            
            options = ...
                optimset(...
                'Display', 'off', ...
                'MaxIter', this.MaxIter,...
                'TolFun', 10^this.TolFun,...
                'Diagnostics', 'off');
            
            switch this.DiffModel
                case 'Free Diffusion'
                    x = [ones(this.EffFitRange,1) dt];
                    guess = x\(msd);
                    x0 = [exp(guess(1))/4 guess(2)];
                    
                    model = @(param,t)4*param(1)*t+param(2);
                    [paramEst,~,resid,~,~,~,J] = lsqcurvefit(model,x0,dt,msd,[0 -inf],[inf inf],options);
                    paramCi = diff(nlparci(paramEst,resid,'jacobian',J),[],2)/2;
                    
                    objEntity.DiffCoeff = paramEst(1);
                    objEntity.CiDiffOffset = paramCi(1);
                    objEntity.AnomalousCoeff = [];
                    objEntity.CiAnomalousCoeff = [];
                    objEntity.TransportCoeff = [];
                    objEntity.CiTransportCoeff = [];
                    objEntity.DiffOffset = paramEst(2);
                    objEntity.CiDiffCoeff = paramCi(2);
                    
                    SST = sum(bsxfun(@minus,msd,...
                        mean(msd)).^2);
                    SSR = sum((msd-model(paramEst,dt)).^2);
                    objEntity.Rsquare = 1-SSR./SST;
                case 'Anomalous Diffusion'
                    %calculate initial guess
                    x = [ones(this.EffFitRange,1) log(dt)];
                    guess = x\log(msd);
                    x0 = [exp(guess(1))/4 guess(2) 0];
                    
                    model = @(param,t)4*param(1)*t.^param(2)+param(3);
                    if numel(dt) > 2
                        [paramEst,~,resid,~,~,~,J] = lsqcurvefit(model,x0,dt,msd,...
                            [0 0 -inf],[inf inf inf],options);
                        paramCi = diff(nlparci(paramEst,resid,'jacobian',J),[],2)/2;
                    else
%                         [paramEst,resid,J] = nlinfit(dt,msd,model,x0);
                        paramEst = nan(1,3);
                        paramCi = nan(1,3);
                    end %if
                    
                    objEntity.DiffCoeff = paramEst(1);
                    objEntity.CiDiffCoeff = paramCi(1);
                    objEntity.AnomalousCoeff = paramEst(2);
                    objEntity.CiAnomalousCoeff = paramCi(2);
                    objEntity.TransportCoeff = [];
                    objEntity.CiTransportCoeff = [];
                    objEntity.DiffOffset = paramEst(3);
                    objEntity.CiDiffOffset = paramCi(3);
                    
                    SST = sum(bsxfun(@minus,msd,...
                        mean(msd)).^2);
                    SSR = sum((msd-model(paramEst,dt)).^2);
                    objEntity.Rsquare = 1-SSR./SST;
                case 'Transport'
                    %calculate initial guess
                    x = [ones(this.EffFitRange,1) log(dt)];
                    guess = x\log(msd);
                    x0 = [exp(guess(1))/4 0 0];
                    
                    model = @(param,t)4*param(1)*t+param(2)^2*t.^2+param(3);
                    if numel(dt) > 2
                        [paramEst,~,resid,~,~,~,J] = lsqcurvefit(model,x0,dt,msd,...
                            [0 0 -inf],[inf inf inf],options);
                        paramCi = diff(nlparci(paramEst,resid,'jacobian',J),[],2)/2;
                    else
%                         [paramEst,resid,J] = nlinfit(dt,msd,model,x0);
                        paramEst = nan(1,3);
                        paramCi = nan(1,3);
                    end %if
                    
                    objEntity.DiffCoeff = paramEst(1);
                    objEntity.CiDiffCoeff = paramCi(1);
                    objEntity.AnomalousCoeff = [];
                    objEntity.CiAnomalousCoeff = [];
                    objEntity.TransportCoeff = paramEst(2);
                    objEntity.CiTransportCoeff = paramCi(2);
                    objEntity.DiffOffset = paramEst(3);
                    objEntity.CiDiffOffset = paramCi(3);
                    
                    SST = sum(bsxfun(@minus,msd,...
                        mean(msd)).^2);
                    SSR = sum((msd-model(paramEst,dt)).^2);
                    objEntity.Rsquare = 1-SSR./SST;
            end %switch
        end %fun
        function yhat = evaluate_model(this,objEntity,x)
            switch this.DiffModel
                case 'Free Diffusion'
                    model = @(t,D,offset)4*D*t+offset;
                    yhat = model(x,objEntity.DiffCoeff,objEntity.DiffOffset);
                case 'Anomalous Diffusion'
                    model = @(t,D,alpha,offset)4*D*t.^alpha+offset;
                    yhat = model(x,objEntity.DiffCoeff,objEntity.AnomalousCoeff,objEntity.DiffOffset);
                case 'Transport'
                    model = @(t,D,V,offset)4*D*t+(V*t).^2+offset;
                    yhat = model(x,objEntity.DiffCoeff,objEntity.TransportCoeff,objEntity.DiffOffset);
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
            this = ManagerMsdCurveFit;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef