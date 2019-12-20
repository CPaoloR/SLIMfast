classdef SuperclassManager < matlab.mixin.Copyable
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent
        Created
        FamilyColor = get(0,'DefaultUIControlBackgroundColor');
        
        SrcContainer
        TargetContainer %will be removed
    end %properties
    properties (Hidden,Transient)
        listenerCloseVis
        listenerDestruction
    end %fun
    
    events
        ClosingVisualization
        ObjectDestruction
    end %events
    
    methods
        %constructor
        function this = SuperclassManager(parent)
            this.Created = datestr(now);
            
            if ~isempty(parent)
                this.Parent = parent;
                this.FamilyColor = parent.FamilyColor;
                
                this.listenerCloseVis = ...
                    event.listener(parent,'ClosingVisualization',...
                    @(src,evnt)close_object(this));
                this.listenerDestruction = ...
                    event.listener(parent,'ObjectDestruction',...
                    @(src,evnt)delete_object(this));
                
                initialize_param_container(this)
            end %if
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            this.FamilyColor = parent.FamilyColor;
            
            %link destructor to new parent
            this.listenerCloseVis = ...
                event.listener(parent,'ClosingVisualization',...
                @(src,evnt)close_object(this));
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
        
        %% parameter container
        function initialize_param_container(this)
            %initialize parameter container
            this.SrcContainer = feval(...
                strrep(class(this),'Manager','Container'),this);
        end %fun
        function add_param_container(this,srcObj)
            %add shallow copy
            this.TargetContainer = [this.TargetContainer;...
                srcObj.SrcContainer];
            %             addlistener(srcObj,'GetsClosed',...
            %                 @(src,evnt)remove_target_container(this,srcObj));
        end %fun
        function remove_param_container(this,srcObj)
            this.TargetContainer = this.TargetContainer(...
                ~eq(this.TargetContainer,srcObj.SrcContainer));
        end %fun
        
        %%
        function S = saveobj(this)
            S = class2struct(this);
            S.Parent = []; %remove to avoid self-references
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
            
            cpObj.Created = now;
            cpObj.Parent = [];
            cpObj.FamilyColor = [];
            
            cpObj.SrcContainer = copy(this.SrcContainer);
            set_parent(cpObj.SrcContainer,cpObj)
            cpObj.TargetContainer = [];
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