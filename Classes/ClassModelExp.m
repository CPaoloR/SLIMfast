classdef ClassModelExp < matlab.mixin.Copyable
    
    properties(Hidden)
        Parent
        
        Subpop
        NumParam = 2;
        ParamNames
        ParamMode = {'Bound' 'Unbound'}
        UserValue = {nan nan};
        LB = {0.05 0};
        UB = {1 inf};
        InitValue
                
        EstValue
        CI
    end %properties
    properties(Hidden,Transient)
        listenerDestruction
    end %properties
    
    methods
        function this = ClassModelExp(parent,subpop)
            if nargin > 0
            this.Subpop = subpop;
            this.ParamNames = {...
                ['Weight_' num2str(subpop)], ...
                ['Mu_' num2str(subpop)]};
            
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
        
        function update_model_parameters(this,selection,evnt)
            coeffIdx = strcmp(selection,this.ParamNames);
            if any(coeffIdx)
                switch evnt.Indices(2)
                    case 2 %Mode
                        this.ParamMode{coeffIdx} = evnt.NewData;
                        switch evnt.NewData
                            case 'Unbound'
                                if regexp(selection,'Weight')
                                    this.LB{coeffIdx} = 0;
                                    this.UB{coeffIdx} = 1;
                                else
                                    this.LB{coeffIdx} = 0;
                                    this.UB{coeffIdx} = inf;
                                end %if
                            case 'Bound'
                                if regexp(selection,'Weight')
                                    this.LB{coeffIdx} = 0.05;
                                    this.UB{coeffIdx} = 1;
                                else
                                    this.LB{coeffIdx} = 0;
                                    this.UB{coeffIdx} = inf;
                                end %if
                            case 'Fixed'
                                this.LB{coeffIdx} = nan;
                                this.UB{coeffIdx} = nan;
                        end %switch
                    case 3 %LB
                        if regexp(selection,'Weight')
                            this.LB{coeffIdx} = max(min(evnt.NewData,min(this.UserValue{coeffIdx},1)),0);
                        else
                            this.LB{coeffIdx} = min(evnt.NewData,this.UserValue{coeffIdx});
                        end %if
                    case 4 %Value
                        switch this.ParamMode{coeffIdx}
                            case {'Unbound' 'Fixed'}
                                if regexp(selection,'Weight')
                                    this.UserValue{coeffIdx} = max(min(evnt.NewData,1),0);
                                else
                                    this.UserValue{coeffIdx} = evnt.NewData;
                                end %if
                            case 'Bound'
                                this.UserValue{coeffIdx} = ...
                                    max(min(evnt.NewData,this.UB{coeffIdx}),this.LB{coeffIdx});
                        end %switch
                    case 5 %UB
                        if regexp(selection,'Weight')
                            this.UB{coeffIdx} = min(max(evnt.NewData,max(this.UserValue{coeffIdx},0)),1);
                        else
                            this.UB{coeffIdx} = max(evnt.NewData,this.UserValue{coeffIdx});
                        end %if
                end %switch
            end %if
        end %fun
        function [formula numParam nameParam] = build_formula(this)
            nameParam = {};
            numParam = this.NumParam;
            
            if this.Parent.Parent.IsTruncated %Mix.Model Manager
                %use truncation corrected formula
                formula = sprintf(['%s*(exppdf(data,%s)/'...
                    '(expcdf(%f,%s)-expcdf(%f,%s)))'],...
                    this.ParamNames{1},this.ParamNames{2},...
                    this.Parent.Parent.RightTrunc,this.ParamNames{2},...
                    this.Parent.Parent.LeftTrunc,this.ParamNames{2});
            else
                formula = sprintf('%s*exppdf(data,%s)',...
                    this.ParamNames{1},this.ParamNames{2});
            end %if
            
            isFixed = strcmp('Fixed',this.ParamMode);
            if any(isFixed)
                for coeff = 1:this.NumParam
                    if isFixed(coeff)
                        numParam = numParam-1;
                        formula = strrep(formula,this.ParamNames{coeff},...
                            num2str(this.UserValue{coeff}));
                    else
                        nameParam = [nameParam this.ParamNames(coeff)];
                    end %if
                end %for
            else
                nameParam = this.ParamNames;
            end %if
        end %fun
        function set_results(this,initValue,estValue,ci)
            [this.InitValue this.EstValue] = deal(this.UserValue);
            this.CI = {0 0};
            
            isFixed = strcmp('Fixed',this.ParamMode);
            if ~all(isFixed)
                this.InitValue(~isFixed) = num2cell(initValue);
                this.EstValue(~isFixed) = num2cell(estValue);
                this.CI(~isFixed) = num2cell(ci);
            end %if
        end %fun
        function yhat = evaluate_subpopulation(this,data)
            yhat = log(this.EstValue{1})+(-data/...
                this.EstValue{2})-log(this.EstValue{2});
%             yhat = this.EstValue{1}*exppdf(data,this.EstValue{2});
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
            delete(this)
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
                this = ClassModelExp;
            
            if isobject(S) %backwards-compatibility
                %                     this = S;
                S = saveobj(S);
            end %if
            
            this = reload(this,S);         
        end %fun
    end %methods
end %classdef