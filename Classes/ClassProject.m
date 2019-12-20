classdef ClassProject < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Created
        
        Name
        Build
        ModDate
        
        ExpNotes
        
        objData = {[] [] [] [] []};
    end %properties
    properties (Hidden, Transient)
        Parent %SLIMfast
        
        hProjectNode
        hClassNodes = {[] [] [] [] []}; %class nodes
        ClassNames = {...
            'ClassRaw',...
            'ClassLocalization',...
            'ClassCluster',...
            'ClassTrajectory',...
            'ClassComposite'};
        StateNodeExpansion
        listenerProjectNodeDestruction
        
        SaveTo
        
        listenerDestruction
    end %properties
    
    events
        ObjectDestruction
    end %events
    
    methods
        %constructor
        function this = ClassProject
            this.Created = datestr(now);
            this.Name = 'Nameless Project';
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %fired when parent (SLIMfast) gets closed
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
        
        function add_data_to_project(this,objData)
            %get data class
            classIdx = strcmp(class(objData),this.ClassNames);
            %add data object to respective data list
            this.objData{classIdx} = [this.objData{classIdx}; objData];
            
            objSLIMfast = this.Parent;
            %update project tree
            switch class(objData)
                case 'ClassComposite'
                    %send signal to add composite node
                    add_composite_node(objSLIMfast.objProjectExplorer,objData)
                otherwise
                    %send signal to add data leaf
                    add_data_leaf(objSLIMfast.objProjectExplorer,objData)
            end %switch
        end %fun
        function remove_data_from_project(this,objData)
            %identify data type
            idxClass = strcmp(class(objData),this.ClassNames);
            %remove respective data object from project's child list
            badIdx = eq(this.objData{idxClass},objData);
            this.objData{idxClass}(badIdx) = [];
            
            delete_object(objData)
        end %fun
        function objDataClone = copy_data_to_project(this,objData)
            %generate deep copy ob object
            objDataClone = clone_object(objData,this);
            objDataClone.Name = [objDataClone.Name ' (Cloned)'];
            
            add_data_to_project(this,objDataClone)
        end %fun
        
        function objComposite = create_composite_data(this)
            objSLIMfast = this.Parent;
            
            %generate composite object
            objComposite = ClassComposite;
            set_parent(objComposite,this)
            
            %initialize associated manager
            objComposite.objContrastSettings = ManagerContrastSettings(objComposite);
            objComposite.objDisplaySettings = ManagerDisplaySettings(objComposite);
            objComposite.objColormap = ManagerColormap(objComposite);
            objComposite.objGrid = ManagerGrid(objComposite);
            objComposite.objRoi = ManagerRoi(objComposite);
            objComposite.objScalebar = ManagerScalebar(objComposite);
            objComposite.objTimestamp = ManagerTimestamp(objComposite);
            objComposite.objTextstamp = ManagerTextstamp(objComposite);
            objComposite.objCoLocSettings = ManagerCoLocSettings(objComposite);
            objComposite.objPICCS = ManagerPICCS(objComposite);
            
            %add composite data to project's child list
            classIdx = strcmp(class(objComposite),this.ClassNames);
            this.objData{classIdx} = ...
                [this.objData{classIdx}; objComposite];
            
            %send signal to update project tree
            add_composite_node(objSLIMfast.objProjectExplorer,objComposite)
        end %fun
                
        %%
        function S = saveobj(this)
            S = class2struct(this);
            
            S.Build = this.Parent.Build;
            S.ModDate = datestr(now);
        end %fun
        function this = reload(this,S)
            this = struct2class(S,this);
            set_children(this)
        end %fun
        function delete_object(this)
            %send signal to close
            notify(this,'ObjectDestruction')
            
            delete(this)
        end
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ClassProject;

            if isobject(S)
                this = reload(this,class2struct(S));
            else
                this = reload(this,S);
            end %if
        end %fun
    end %methods
end %classdef