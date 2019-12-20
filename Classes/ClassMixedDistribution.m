classdef ClassMixedDistribution < matlab.mixin.Copyable
    
    properties(Hidden)
        Parent %Mixed Dist. Manager
        NumMix
        DistFamily
        
        objModel
        
        NumParam
        NumParamEst
        
        Formula
        NameParam
        
        Nll
        AIC
        %         AICc
        BIC
        
        %         YHat
        %         Posterior
    end %properties
    properties(Hidden,Transient)
        listenerDestruction
    end %properties
    
    events
        ObjectDestruction
    end %events
    
    methods
        function this = ClassMixedDistribution(parent,numMix,distFamily)
            if nargin > 0
                this.NumMix = numMix;
                this.DistFamily = distFamily;
                
                switch distFamily
                    case 'Normal'
                        this.objModel = ClassModelNormal.empty;
                        for subpop = 1:numMix
                            this.objModel(subpop,1) = ClassModelNormal(this,subpop);
                        end %for
                    case 'Exp'
                        this.objModel = ClassModelExp.empty;
                        for subpop = 1:numMix
                            this.objModel(subpop,1) = ClassModelExp(this,subpop);
                        end %for
                    case 'Rayl'
                        this.objModel = ClassModelRayleigh.empty;
                        for subpop = 1:numMix
                            this.objModel(subpop,1) = ClassModelRayleigh(this,subpop);
                        end %for
                end %switch
                this.NumParam = numMix*this.objModel(1).NumParam;
                
                set_parent(this,parent)
            end %if
        end %constructor
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

        function initialize_model_function(this)
            this.NameParam = {};
            
            p = 0;
            [this.Formula this.NumParamEst nameParam] = ...
                build_formula(this.objModel(1));
            for coeff = 1:this.NumParamEst
                p = p +1;
                coeffName = ['param(' num2str(p) ')'];
                this.Formula = strrep(this.Formula,nameParam{coeff},coeffName);
                this.NameParam = [this.NameParam; [nameParam(coeff) {coeffName} {1}]];
            end %for
            
            if this.NumMix > 1
                for subpop = 2:this.NumMix
                    [formula numparamest nameParam] = build_formula(this.objModel(subpop));
                    this.Formula = [this.Formula '+' formula];
                    this.NumParamEst = this.NumParamEst + numparamest;
                    
                    if numparamest > 0
                        for coeff = 1:numparamest
                            p = p +1;
                            coeffName = ['param(' num2str(p) ')'];
                            this.Formula = strrep(this.Formula,nameParam{coeff},coeffName);
                            this.NameParam = [this.NameParam; [nameParam(coeff) {coeffName} {subpop}]];
                        end %for
                    end %if
                end %for
            end %if
        end %fun
        function isOK = estimate_model_parameter(this,hProgressbar)
            data = this.Parent.Data;
            
            if isempty(data)
                waitfor(errordlg('No Data found','','modal'))
                isOK = 0;
                return
            end %if
            
            if any(~isfinite(data))
                %                 waitfor(warndlg('Data contains Nan/Inf Values','','modal'))
                data = data(isfinite(data));
                if isempty(data)
                    waitfor(errordlg('No Data found','','modal'))
                    isOK = 0;
                    return
                end %if
            end %if
            
            if this.Parent.IsTruncated
                %apply data truncation
                data(data <= this.Parent.LeftTrunc |...
                    data > this.Parent.RightTrunc) = [];
                
                if numel(data) == 0
                    waitfor(errordlg('No Data found','','modal'))
                    isOK = 0;
                    return
                else
                    if numel(unique(data)) == 1
                        waitfor(errordlg('Data has Zero Variance','','modal'))
                        isOK = 0;
                        return
                    end %if
                end %if
            end %if
            
            %construct neg. loglikelihood function
            initialize_model_function(this)
            hFormula{1} = eval(strcat('@(param)-sum(log(',this.Formula,'))'));
            hFormula{2} = str2func(strcat('@(param,data,cens,freq)-sum(log(',this.Formula,'))'));
            
            coeffNames = [this.objModel.ParamNames];
            userValue = cell2mat([this.objModel.UserValue]);
            isFixed = strcmp([this.objModel.ParamMode],'Fixed');
            if any(isnan(userValue(isFixed)))
                waitfor(errordlg('No Value for fixed Parameter found',''))
                isOK = 0;
                return
            end %if
            
            lb = cell2mat([this.objModel.LB]);
            ub = cell2mat([this.objModel.UB]);
            
            Aeq = zeros(1,this.NumParam);
            beq = 1;
            for coeff = 1:this.NumParam
                if regexp(coeffNames{coeff},'Weight')
                    Aeq(coeff) = 1;
                    if isFixed(coeff)
                        beq = beq - userValue(coeff);
                        if beq < 0
                            waitfor(errordlg('Fixed Weight > 1 not allowed',''))
                            isOK = 0;
                            return
                        end %if
                    end %if
                end %if
            end %for
            
            %remove fixed parameter
            Aeq = Aeq(~isFixed);
            lb = lb(~isFixed);
            ub = ub(~isFixed);
            
            options = ...
                optimset(...
                'Display', 'notify-detailed', ...
                'Algorithm', 'interior-point', ...
                'ScaleProblem', 'obj-and-constr',...
                'MaxIter', this.Parent.MaxIter,...
                'TolFun', 10^this.Parent.TolFun,...
                'Diagnostics', 'off');
            
            %preallocate
            [initGuess estimate] = deal(cell(this.Parent.Replicates,1));
            [nll flag] = deal(zeros(this.Parent.Replicates,1));
            
            % Find maximum likelihood estimates
            errCnt = 0;
            critErrCnt = 100;
            replicate = 1;
            while replicate <= this.Parent.Replicates
                initGuess{replicate} = cell2mat([this.objModel.UserValue]);
                initGuess{replicate} = initGuess{replicate}(~isFixed);
                for param = 1:this.NumParamEst
                    if Aeq(param)
                        if isnan(initGuess{replicate}(param))
                            if param == find(Aeq,1,'last')
                                initGuess{replicate}(param) = ...
                                    min(ub(param),beq-nansum(initGuess{replicate}(logical(Aeq))));
                            else
                                initGuess{replicate}(param)= ...
                                    unifrnd(lb(param),min(ub(param),...
                                    lb(param)+beq-nansum(max(lb(logical(Aeq)),...
                                    initGuess{replicate}(logical(Aeq))))),1);
                            end %if
                        end %if
                    else
                        if isnan(initGuess{replicate}(param))
                            %draw initial guess
                            initGuess{replicate}(param) = unifrnd(max(lb(param),...
                                -1E3),min(ub(param),1E3),1);
                        end %if
                    end %if
                end %for
                try
                    [estimate{replicate},nll(replicate),flag(replicate)] = ...
                        fmincon(hFormula{1},initGuess{replicate}(:),[],[],Aeq,beq,lb,ub,[],options);
                    
                    %Number of iterations exceeded options.MaxIter or
                    %number of function evaluations exceeded options.MaxFunEvals.
                    if flag(replicate) == 0
                        answer = questdlg(sprintf(...
                            'No Solution found within %.0f iterations',options.MaxIter),...
                            '',sprintf('Relax Tolerance to %.0E',options.TolFun*10),...
                            sprintf('Increase max. # iterations to %.0E',options.MaxIter+10),...
                            'Abort','Abort');
                        switch answer
                            case sprintf('Relax Tolerance to %.0E',options.TolFun*10)
                                options.TolX = options.TolFun*10;
                            case sprintf('Increase max. # iterations to %.1E',options.MaxIter+10)
                                options.MaxIter = options.MaxIter+10;
                            case 'Abort'
                                isOK = 0;
                                return
                        end %switch
                    else
                        if hProgressbar.NumBars == 2
                            update_progressbar(hProgressbar,{[],replicate/this.Parent.Replicates})
                        elseif hProgressbar.NumBars == 3
                            update_progressbar(hProgressbar,{[],[],replicate/this.Parent.Replicates})
                        end %if
                        
                        replicate = replicate +1;
                    end %if
                catch err
                    if strcmp(err.identifier,'optim:barrier:UsrObjUndefAtX0')
                        %start values badly chosen -> repeat with new start
                        %values
                        errCnt = errCnt + 1;
                        if errCnt > critErrCnt
                            answer = questdlg(...
                                'Constraints for Optimization badly chosen',...
                                '','Continue (100x)','Abort','Abort');
                            switch answer
                                case 'Continue (100x)'
                                    critErrCnt = critErrCnt + 100;
                                case 'Abort'
                                    isOK = 0;
                                    return
                            end %switch
                        end %if
                    end %if
                end %try
            end %for
            
            if any(flag==1)
                isOK = 1;
                good = find(flag==1);
                [~, bestFit] = min(nll(good));
                bestFit = good(bestFit);
                
                this.Nll = nll(bestFit);
                initGuess = initGuess{bestFit};
                estimate = estimate{bestFit}';
                
                hessian = mlecov(estimate, data, 'nloglf', hFormula{2});
                ci = 1.96*sqrt(diag(hessian))'; % ci=95%
                
                for mix = 1:this.NumMix
                    good = cell2mat(this.NameParam(:,3)) == mix;
                    set_results(this.objModel(mix),initGuess(good),estimate(good),ci(good))
                end %for
            else
                isOK = 0;
                waitfor(errordlg(sprintf(...
                    'No Solution found for Model Complexity %0.0f',this.NumMix),''))
                return
            end %if
        end %fun
        function calculate_information_criteria(this)
            this.AIC = 2*this.Nll+2*this.NumParamEst+...
                (2*this.NumParamEst*(this.NumParamEst+1))/...
                (this.Parent.NumPoints-this.NumParamEst-1); %corrected in case of small sample (=AICc)
            this.BIC = 2*this.Nll+this.NumParamEst*log(this.Parent.NumPoints);
        end %fun
        function [yHat posterior] = evaluate_model_mixture(this,x)
            %preallocate
            yHat = zeros(numel(x),this.NumMix);
            
            for mix = 1:this.NumMix
                yHat(:,mix) = evaluate_subpopulation(this.objModel(mix),x);
            end %for
            yHat(:,end+1) = sum_log(yHat,2);
            posterior = bsxfun(@minus,yHat,yHat(:,end));
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
            notify(this,'ObjectDestruction')
            
            delete(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@matlab.mixin.Copyable(this);
            for idx = 1:this.NumMix
                cpObj.objModel = copy(this.objModel);
            end %for
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ClassMixedDistribution;
            
            if isobject(S) %backwards-compatibility
                %                     this = S;
                S = saveobj(S);
            end %if
            %                 else
            this = reload(this,S);
            %                 end %if
        end %fun
    end %methods
end %classdef