classdef ProjectExplorer < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties(Hidden, Transient)
        Parent %SLIMfast
        
        hProjectTree
        hProjectTreeContainer
        jProjectTree
        hRootNode
        
        ClassNames = {...
            'ClassRaw',...
            'ClassLocalization',...
            'ClassCluster',...
            'ClassTrajectory',...
            'ClassComposite'};
        
        hProjectInfoPanel
        
        SelectedLeafs
        hLastSelectedLeaf
        
        hNameEdit
        hCreatedText
        hFileList
        
        hExpNotesEditButton
        hExpNotesEdit
        IsExpNotesEdit
        
        hShowDataButton
    end %properties
    
    events
        SelectRaw
        SelectLocalization
        SelectCluster
        SelectTrajectory
        SelectComposite
    end %events
    
    methods
        %constructor
        function this = ProjectExplorer(parent)
            icon = getappdata(0,'icon');
            
            this.Parent = parent;
            
            this.hProjectInfoPanel = uipanel(...
                this.Parent.hFig,...
                'Units','normalized',...
                'Position', [0.45 0 0.55 1],...
                'FontSize', 18,...
                'Title','Information',...
                'TitlePosition','centertop');
            
            hCreatedText = ...
                uicontrol(...
                'Style', 'Text',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [5 435 100 30],...
                'FontSize', 18,...
                'String', 'Created:',...
                'HorizontalAlignment', 'left');
            
            this.hCreatedText = ...
                uicontrol(...
                'Style', 'Text',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [105 435 325 30],...
                'FontSize', 18,...
                'String', '',...
                'HorizontalAlignment', 'left');
            
            hFileListText = ...
                uicontrol(...
                'Style', 'Text',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [5 400 170 30],...
                'FontSize', 18,...
                'String', 'Image Files:',...
                'HorizontalAlignment', 'left');
            
            this.hFileList = ...
                uicontrol(...
                'Style', 'listbox',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [5 340 425 60],...
                'BackgroundColor', [1 1 1],...
                'FontSize', 15,...
                'SelectionHighlight','off',...
                'Hittest', 'off',...
                'Enable','inactive');
            
            this.hExpNotesEditButton = ...
                uicontrol(...
                'Style', 'togglebutton',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [4 300 30 30],...
                'CData', icon.Pencil,...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)edit_exp_notes(this,src),...
                'Enable','inactive');
            
            hExpNotesText = ...
                uicontrol(...
                'Style', 'Text',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [35 300 250 30],...
                'FontSize', 18,...
                'String', 'Notes:',...
                'HorizontalAlignment', 'left');
            
            this.hExpNotesEdit = ...
                uicontrol(...
                'Style', 'Edit',...
                'Parent', this.hProjectInfoPanel,...
                'Units','pixels',...
                'Position', [5 10 425 290],...
                'BackgroundColor', [1 1 1],...
                'FontSize', 18,...
                'String', '',...
                'Min', 1,...
                'Max', 3,...
                'HorizontalAlignment', 'left',...
                'Enable','inactive');
            
            hNameText = ...
                uicontrol(...
                'Style', 'Text',...
                'Parent', this.Parent.hFig,...
                'Units','pixels',...
                'Position', [5 50 80 30],...
                'FontSize', 18,...
                'String', 'Name:',...
                'HorizontalAlignment', 'left');
            
            this.hNameEdit = ...
                uicontrol(...
                'Style', 'Edit',...
                'Parent', this.Parent.hFig,...
                'Units','pixels',...
                'Position', [85 50 271 30],...
                'BackgroundColor', [1 1 1],...
                'FontSize', 18,...
                'String', '',...
                'HorizontalAlignment', 'left',...
                'Enable','inactive');
            
            this.hShowDataButton = ...
                uicontrol(...
                'Style', 'pushbutton',...
                'Units','pixels',...
                'Position', [235 13 120 30],...
                'FontSize', 18,...
                'FontUnits', 'normalized',...
                'String', 'SHOW',...
                'HorizontalAlignment', 'left',...
                'Callback', @(src,evnt)initialize_visualization(this),...
                'Enable','off');
            
            this.hRootNode = uitreenode('v0', 'IsRootNode', ...
                'My Projects', [], false);
            this.hRootNode.setIcon(im2java(icon.Explorer_Root))
            
            [this.hProjectTree, this.hProjectTreeContainer] = ...
                uitree('v0',this.Parent.hFig,'Root',this.hRootNode);
            drawnow
            set(this.hProjectTree,...
                'Units','pixels',...
                'Position', [5 90 351 395],...
                'MultipleSelectionEnabled', true,...
                'DndEnabled', true,...
                'NodeSelectedCallback',@(src,evnt)show_node_details(this,evnt),...
                'NodeDroppedCallback',@(src,evnt)ProjectExplorer.node_drag_and_drop(evnt))
            
            %             import com.mathworks.mwswing.checkboxtree.*
            %             jRoot = DefaultCheckBoxNode('Root');
            %             jProjectTree = com.mathworks.mwswing.MJTree(jRoot);
            %             jCheckBoxTree = CheckBoxTree(jProjectTree.getModel);
            %             jScrollPane = com.mathworks.mwswing.MJScrollPane(jCheckBoxTree);
            %             [jComp,hc] = javacomponent(jScrollPane,[5,155,351,330],this.Parent.hFig);
            
            this.jProjectTree = this.hProjectTree.getTree;
            set(this.jProjectTree,...
                'KeyPressedCallback',@(src,evnt)keyboard_action(this,evnt))
            this.jProjectTree.setFont(this.jProjectTree.getFont.deriveFont(18))
            
            this.hProjectTree.setSelectedNode(this.hProjectTree.getRoot)
            
            set(get(this.hProjectInfoPanel,'Children'),...
                'Units','normalized')
            set(this.hProjectTree,'Units','normalized')
            set([this.hNameEdit hNameText this.hShowDataButton],...
                'Units','normalized')
            set([hExpNotesText hNameText hFileListText hCreatedText this.hCreatedText],...
                'FontUnits','normalized')
        end %fun
        function initialize_visualization(this)
            selection = this.hProjectTree.getSelectedNodes;
            numSelected = numel(selection);
            for idxLeaf = 1:numSelected
                objData = get(selection(idxLeaf),'UserData');
                %check if leaf is data object
                if any(strcmp(class(objData),this.ClassNames))
                    initialize_visualization(objData)
                else
                    %do nothing
                end %if
            end %for
        end %fun
        
        function load_node_structure(this,objProject)
            %generate project node
            add_project_node(this,objProject)
            
            %generate data channels
            for classIdx = 1:4
                %get # data object of respective data type
                numData = numel(objProject.objData{classIdx});
                if numData > 0
                    %when project is loaded, generate data leafs
                    for leafIdx = 1:numData
                        %get data object
                        objData = objProject.objData{classIdx}(leafIdx);
                        
                        %generate data leaf
                        add_data_leaf(this,objData)
                    end %for
                end %if
            end %for
            
            %when project is loaded, generate composite nodes and leafs
            classIdx = 5; %(by def: Composite Class)
            %get # data object of respective data type
            numData = numel(objProject.objData{classIdx});
            if numData > 0
                %generate composite nodes
                for nodeIdx = 1:numData
                    objComposite = objProject.objData{classIdx}(nodeIdx);
                    
                    %generate composite node
                    add_composite_node(this,objComposite)
                end %for
            end %if
            
            this.hProjectTree.setSelectedNode(...
                objProject.hProjectNode)
        end %fun
        
        function add_project_node(this,objProject)
            icon = getappdata(0,'icon');
            
            %generate project node
            objProject.hProjectNode = ...
                ProjectExplorer.generate_node(...
                'Parent',this.hRootNode,...
                'Name',objProject.Name,...
                'Type','IsProjectNode',...
                'Icon', icon.Explorer_Project,...
                'UserData', objProject);
            objProject.listenerProjectNodeDestruction = ...
                event.listener(objProject,'ObjectBeingDestroyed',...
                @(src,evnt)remove_project_node(this,objProject));
            
            this.hRootNode.add(objProject.hProjectNode)
            update_project_tree(this)
        end %fun
        function remove_project_node(this,objProject)
            objProject.hProjectNode.removeFromParent
            
            %             update_project_tree(this)
        end %fun
        
        function add_data_leaf(this,objData,varargin)
            icon = getappdata(0,'icon');
            
            objProject = get_parental_object(objData,'ClassProject');
            
            %get data type
            classIdx = strcmp(this.ClassNames,class(objData));
            
            %check if data node exists
            if isempty(objProject.hClassNodes{classIdx})
                %generate class node
                objProject.hClassNodes{classIdx} = ...
                    ProjectExplorer.generate_node(...
                    'Parent',objProject.hProjectNode,...
                    'Name',strrep(this.ClassNames{classIdx},'Class',''),...
                    'Type','IsNode');
            end %if
            
            %generate data leaf
            objData.hExplorerLeaf = ...
                ProjectExplorer.generate_node(...
                'Parent',objProject.hClassNodes{classIdx},...
                'Name',objData.Name,...
                'Type','IsLeaf',...
                'IsLeaf',true,...
                'Icon',icon.Explorer_File,...
                'UserData', objData);
            objData.listenerExplorerLeafDestruction = ...
                event.listener(objData,'ObjectBeingDestroyed',...
                @(src,evnt)remove_data_leaf(this,objData));
            
            update_project_tree(this)
            this.hProjectTree.setSelectedNode(objData.hExplorerLeaf)
        end %fun
        function remove_data_leaf(this,objData)
            objData.hExplorerLeaf.removeFromParent
            
            objProject = get_parental_object(objData,'ClassProject');
            ProjectExplorer.check_for_empty_class_node(objProject)
            
            %             update_project_tree(this)
        end %fun
        
        function create_empty_composite_container(this)
            hNode = this.hProjectTree.getSelectedNodes;
            if strcmp(get(hNode(1),'Value'),'IsProjectNode')
                objProject = get(hNode(1),'UserData');
                create_composite_data(objProject)
            elseif numel(hNode) > 1
                waitfor(errordlg('More than 1 Project selected','','modal'))
            else
                waitfor(errordlg('No Project selected','','modal'))
            end %if
        end %fun
        function add_composite_node(this,objComposite)
            objProject = get_parental_object(objComposite,'ClassProject');
            
            %check if composite node exists
            classIdx = 5; %(by def: Composite Class)
            if isempty(objProject.hClassNodes{classIdx})
                %generate class node
                objProject.hClassNodes{classIdx} = ...
                    ProjectExplorer.generate_node(...
                    'Parent',objProject.hProjectNode,...
                    'Name',strrep(this.ClassNames{classIdx},'Class',''),...
                    'Type','IsNode');
            end %if
            
            %generate data node
            objComposite.hCompositeNode = ...
                ProjectExplorer.generate_node(...
                'Parent',objProject.hClassNodes{classIdx},...
                'Name',objComposite.Name,...
                'Type','IsCompNode',...
                'UserData',objComposite);
            objComposite.listenerCompositeNodeDestruction = ...
                event.listener(objComposite,'ObjectBeingDestroyed',...
                @(src,evnt)remove_composite_node(this,objComposite));
            
            icon = getappdata(0,'icon');
            for channelIdx = 1:4
                %generate channel node
                objComposite.hChannelNodes{channelIdx} = ...
                    ProjectExplorer.generate_node(...
                    'Parent',objComposite.hCompositeNode,...
                    'Name',objComposite.ChannelNames{channelIdx},...
                    'Type','IsNode');
                
                %check if channel contains data
                if ~isempty(objComposite.hImChannel{channelIdx})
                    objData = objComposite.hImChannel{channelIdx};
                    
                    %generate data leaf
                    add_composite_channel_leaf(this,objData,channelIdx)
                end %if
            end %for
            
            %generate traj channel node
            channelIdx = 6; %(by def: traj channel)
            objComposite.hChannelNodes{channelIdx} = ...
                ProjectExplorer.generate_node(...
                'Parent',objComposite.hCompositeNode,...
                'Name',objComposite.ChannelNames{channelIdx},...
                'Type','IsNode');
            
            %get # data object of respective data type
            numTraj = numel(objComposite.hTrajChannel);
            if numTraj > 0
                for leafIdx = 1:numTraj
                    %get data object
                    objData = objComposite.hTrajChannel{leafIdx};
                    
                    %generate data leaf
                    objData.hExplorerLeaf = ...
                        ProjectExplorer.generate_node(...
                        'Parent',objComposite.hChannelNodes{channelIdx},...
                        'Name',objData.Name,...
                        'Type','IsChannelLeaf',...
                        'Icon',icon.Explorer_File,...
                        'IsLeaf',true,...
                        'UserData', objData);
                end %for
            end %if
            
            update_project_tree(this)
            this.hProjectTree.setSelectedNode(...
                objComposite.hCompositeNode)
        end %fun
        function remove_composite_node(this,objComposite)
            objComposite.hCompositeNode.removeFromParent
            
            objProject = objComposite.Parent;
            ProjectExplorer.check_for_empty_class_node(objProject)
            
            %             update_project_tree(this)
        end %fun
        function add_composite_channel_leaf(this,objData,channelIdx)
            icon = getappdata(0,'icon');
            
            objComposite = objData.Parent;
            %generate data leaf
            objData.hExplorerLeaf = ...
                ProjectExplorer.generate_node(...
                'Parent',objComposite.hChannelNodes{channelIdx},...
                'Name',objData.Name,...
                'Type','IsChannelLeaf',...
                'IsLeaf',true,...
                'Icon',icon.Explorer_File,...
                'UserData', objData);
            objData.listenerExplorerLeafDestruction = ...
                event.listener(objData,'ObjectBeingDestroyed',...
                @(src,evnt)remove_composite_channel_leaf(this,objData));
            
            update_project_tree(this)
            this.hProjectTree.setSelectedNode(objData.hExplorerLeaf)
        end %fun
        function remove_composite_channel_leaf(this,objData)
            objData.hExplorerLeaf.removeFromParent
            
            %             update_project_tree(this)
        end %fun
        
        function update_project_tree(this)
            %temporarly deactivate selection callback
            set(this.hProjectTree,'NodeSelectedCallback',[])
            
            store_tree_expansion(this)
            this.hProjectTree.reloadNode(this.hRootNode)
            restore_tree_expansion(this)
            
            %restore node selection callback
            set(this.hProjectTree,'NodeSelectedCallback',...
                @(src,evnt)show_node_details(this,evnt))
        end %fun
        function store_tree_expansion(this)
            objSLIMfast = this.Parent;
            for idxProject = 1:numel(objSLIMfast.Projects)
                store_project_node_expansion(this,objSLIMfast.Projects(idxProject))
            end %for
        end %fun
        function store_project_node_expansion(this,objProject)
            %check project node for expansion
            this.hProjectTree.setSelectedNode(...
                objProject.hProjectNode)
            drawnow
            %save state of project node expansion
            objProject.StateNodeExpansion.ProjectNode = ...
                this.jProjectTree.isExpanded(...
                this.jProjectTree.getRowForPath(...
                this.jProjectTree.getSelectionPath));
            drawnow
            
            if objProject.StateNodeExpansion.ProjectNode %(=project node is expanded)
                %check on data channels for expansion
                for idx = 1:5
                    %check if data within respective class exists
                    if ~isempty(objProject.hClassNodes{idx})
                        this.hProjectTree.setSelectedNode(...
                            objProject.hClassNodes{idx})
                        drawnow
                        %save state of class node expansion
                        objProject.StateNodeExpansion.ClassNodes(idx) = ...
                            this.jProjectTree.isExpanded(...
                            this.jProjectTree.getRowForPath(...
                            this.jProjectTree.getSelectionPath));
                        drawnow
                    end %if
                end %for
                
                %check if composite node exists
                if ~isempty(objProject.hClassNodes{end})
                    %check if composite node is expanded
                    if objProject.StateNodeExpansion.ClassNodes(end)
                        %check on composite channels for expansion
                        numComposite = numel(objProject.objData{end});
                        for compIdx = 1:numComposite
                            this.hProjectTree.setSelectedNode(...
                                objProject.objData{end}(compIdx).hCompositeNode)
                            drawnow
                            %save state of composite node expansion
                            objProject.StateNodeExpansion.CompositeNodes(compIdx) = ...
                                this.jProjectTree.isExpanded(...
                                this.jProjectTree.getRowForPath(...
                                this.jProjectTree.getSelectionPath));
                            drawnow
                            
                            if objProject.StateNodeExpansion.CompositeNodes(compIdx)
                                objComposite = objProject.objData{end}(compIdx);
                                %check on composite subchannels for expansion
                                for channelIdx = 1:6
                                    this.hProjectTree.setSelectedNode(...
                                        objComposite.hChannelNodes{channelIdx})
                                    drawnow
                                    objProject.StateNodeExpansion.ChannelNodes{compIdx}(channelIdx) = ...
                                        this.jProjectTree.isExpanded(...
                                        this.jProjectTree.getRowForPath(...
                                        this.jProjectTree.getSelectionPath));
                                    drawnow
                                end %for
                            end %if
                        end %for
                    end %if
                end %if
            end %if
        end %fun
        function restore_tree_expansion(this)
            objSLIMfast = this.Parent;
            for idxProject = 1:numel(objSLIMfast.Projects)
                restore_project_node_expansion(this,objSLIMfast.Projects(idxProject))
            end %for
        end %fun
        function restore_project_node_expansion(this,objProject)
            %check on project node
            if objProject.StateNodeExpansion.ProjectNode
                this.hProjectTree.expand(objProject.hProjectNode)
                drawnow
                
                %check on data nodes
                for idx = 1:5
                    if ~isempty(objProject.hClassNodes{idx})
                        if objProject.StateNodeExpansion.ClassNodes(idx)
                            this.hProjectTree.expand(...
                                objProject.hClassNodes{idx})
                            drawnow
                        end %if
                    end %if
                end %for
                
                %check if composite node exists
                if ~isempty(objProject.hClassNodes{end})
                    if objProject.StateNodeExpansion.ClassNodes(end)
                        %check on composite nodes
                        numComposite = numel(objProject.objData{end});
                        for compIdx = 1:numComposite
                            if objProject.StateNodeExpansion.CompositeNodes(compIdx)
                                objComposite = objProject.objData{end}(compIdx);
                                
                                this.hProjectTree.expand(...
                                    objComposite.hCompositeNode)
                                drawnow
                                
                                %check on composite subnodes
                                for channelIdx = 1:6
                                    if objProject.StateNodeExpansion.ChannelNodes{compIdx}(channelIdx)
                                        this.hProjectTree.expand(...
                                            objComposite.hChannelNodes{channelIdx})
                                        drawnow
                                    end %if
                                end %for
                            end %if
                        end %for
                    end %if
                end %if
            end %if
            
            %move to root node if no other node has focus
            if isempty(this.jProjectTree.getLastSelectedPathComponent)
                this.hProjectTree.setSelectedNode(this.hRootNode)
            end %if
        end %fun
        
        function show_node_details(this,evnt)
            hNode = get(evnt,'CurrentNode');
            if this.IsExpNotesEdit
                this.hProjectTree.setSelectedNode(this.hLastSelectedLeaf)
            elseif strcmp(get(hNode,'Value'),'IsRootNode')
                set(this.hNameEdit,...
                    'String', '',...
                    'Enable','inactive')
                
                set(this.hCreatedText,...
                    'String', '')
                set(this.hFileList,...
                    'String', '',...
                    'Value',1)
                
                set(this.hExpNotesEdit,...
                    'String', '')
                set(this.hExpNotesEditButton,...
                    'Enable','off')
                
                set(this.hShowDataButton,...
                    'Enable','off')
            elseif strcmp(get(hNode,'Value'),'IsProjectNode')
                this.hLastSelectedLeaf = hNode;
                
                objProject = get(hNode,'UserData');
                
                set(this.hNameEdit,...
                    'String', objProject.Name,...
                    'Callback', @(src,evnt)set_name(this,src),...
                    'Enable','on')
                
                set(this.hCreatedText,...
                    'String', objProject.Created)
                set(this.hFileList,...
                    'String', '',...
                    'Value',1)
                
                set(this.hExpNotesEdit,...
                    'String', objProject.ExpNotes)
                set(this.hExpNotesEditButton,...
                    'Enable','on')
                
                set(this.hShowDataButton,...
                    'Enable','off')
            elseif any(strcmp(get(hNode,'Value'),...
                    {'IsLeaf','IsChannelLeaf','IsCompNode'}))
                this.hLastSelectedLeaf = hNode;
                
                objData = get(hNode,'UserData');
                
                set(this.hNameEdit,...
                    'String', objData.Name,...
                    'Callback', @(src,evnt)set_name(this,src),...
                    'Enable','on')
                
                set(this.hCreatedText,...
                    'String', objData.Created)
                if any(strcmp(get(hNode,'Value'),{'IsLeaf','IsChannelLeaf'}))
                    set(this.hFileList,...
                        'String', objData.objImageFile.ImageNames)
                end %if
                
                set(this.hExpNotesEdit,...
                    'String', objData.ExpNotes)
                set(this.hExpNotesEditButton,...
                    'Enable','on')
                
                set(this.hShowDataButton,...
                    'Enable','on')
            else
                idxSelectedLeaf = this.jProjectTree.getSelectionRows;
                this.hProjectTree.setSelectedNode(this.hLastSelectedLeaf)
                idxLastLeaf = this.jProjectTree.getSelectionRows;
                if idxSelectedLeaf < idxLastLeaf
                    hNextLeaf = hNode.getPreviousNode;
                    this.hProjectTree.setSelectedNode(hNextLeaf)
                else
                    hNextLeaf = hNode.getNextNode;
                    this.hProjectTree.setSelectedNode(hNextLeaf)
                end %if
                if isempty(hNextLeaf)
                    this.hProjectTree.setSelectedNode(this.hRootNode)
                end %if
            end %if
        end %fun
        function set_name(this,src)
            name = get(src,'String');
            
            selection = this.hProjectTree.getSelectedNodes;
            numSelected = numel(selection);
            if numSelected == 0 %(=no selection)
                %do nothing
            else
                for idxLeaf = 1:numSelected
                    if strcmp(get(selection(idxLeaf),'Value'),'IsProjectNode')
                        objProject = get(selection(idxLeaf),'UserData');
                        
                        objProject.Name = name;
                        set(objProject.hProjectNode,'Name',objProject.Name)
                    elseif strcmp(get(selection(idxLeaf),'Value'),'IsLeaf')
                        objData = get(selection(idxLeaf),'UserData');
                        
                        objData.Name = name;
                        set(objData.hExplorerLeaf,'Name',objData.Name)
                        
                        %check if visualization figure is open, then update title
                        if ishandle(objData.hImageFig)
                            set(objData.hImageFig,'Name',name)
                        end %if
                    elseif strcmp(get(selection(idxLeaf),'Value'),'IsCompNode')
                        objComposite = get(selection(idxLeaf),'UserData');
                        
                        objComposite.Name = name;
                        set(objComposite.hCompositeNode,'Name',objComposite.Name)
                        
                        %check if visualization figure is open, then update title
                        if ishandle(objComposite.hImageFig)
                            set(objComposite.hImageFig,'Name',name)
                        end %if
                    else
                        %do nothing
                    end %if
                end %for
                update_project_tree(this)
                this.hProjectTree.setSelectedNodes(selection)
            end %if
        end %fun
        
        function edit_exp_notes(this,src)
            this.hProjectTree.setSelectedNode(this.hLastSelectedLeaf)
            obj = get(this.hLastSelectedLeaf,'UserData');
            
            if get(src,'Value')
                this.IsExpNotesEdit = true;
                
                set(this.hExpNotesEdit,...
                    'String', obj.ExpNotes,...
                    'Enable','on')
            else
                this.IsExpNotesEdit = false;
                
                obj.ExpNotes = get(this.hExpNotesEdit,'String');
                set(this.hExpNotesEdit,...
                    'String', obj.ExpNotes,...
                    'Enable','inactive')
            end %if
        end %fun
        
        function select_leafs(this,targetClass)
            this.SelectedLeafs = [];
            
            idxClass = strcmp(this.ClassNames,targetClass);
            switch targetClass
                case 'ClassComposite'
                    objSLIMfast = this.Parent;
                    for idxProject = 1:numel(objSLIMfast.Projects)
                        objProject = objSLIMfast.Projects(idxProject);
                        %check if project contains data type
                        if ~isempty(objProject.objData{idxClass})
                            this.SelectedLeafs = vertcat(this.SelectedLeafs,...
                                objProject.objData{idxClass}.hCompositeNode);
                        end %if
                    end %for
                otherwise
                    objSLIMfast = this.Parent;
                    for idxProject = 1:numel(objSLIMfast.Projects)
                        objProject = objSLIMfast.Projects(idxProject);
                        %check if project contains data type
                        if ~isempty(objProject.objData{idxClass})
                            this.SelectedLeafs = vertcat(this.SelectedLeafs,...
                                objProject.objData{idxClass}.hExplorerLeaf);
                        end %if
                    end %for
            end %switch
            
            if isempty(this.SelectedLeafs)
                this.hProjectTree.setSelectedNode(this.hRootNode)
                waitfor(errordlg(sprintf('No %s data found',...
                    strrep(targetClass,'Class','')),'','modal'))
            elseif numel(this.SelectedLeafs) == 1
                this.hProjectTree.setSelectedNode(this.SelectedLeafs)
            else
                this.hProjectTree.setSelectedNodes(this.SelectedLeafs)
            end %if
        end %fun
        
        function expand_all(this)
            selection = this.hProjectTree.getSelectedNodes;
            
            cnt = 1;
            while ~isempty(this.jProjectTree.getPathForRow(cnt))
                this.jProjectTree.expandRow(cnt)
                cnt = cnt + 1;
            end
            
            this.hProjectTree.setSelectedNodes(selection)
        end %fun
        function collapse_all(this)
            this.hProjectTree.setSelectedNode(this.hRootNode)
            
            for leaf = this.jProjectTree.getRowCount:-1:1
                this.jProjectTree.collapseRow(leaf)
            end
        end %fun
        
        function keyboard_action(this,evnt)
            [hSelectedList,numSelected,flag] = ...
                get_user_selected_nodes(this);
            if flag == 0 %(=no selection)
                %do nothing
                return
            end %if
            
            switch evnt.getKeyCode
                case 17
                case 45 %(=CTRL -)
                    collapse_all(this)
                case 82 %(=CTRL R)
                    %rename selected leaf(s)
                case 127 %(=DEL)
                    %generate node paths
                    leafPath = cell(numSelected,1);
                    for idxSelection = 1:numSelected
                        hLeaf = hSelectedList(idxSelection);
                        leafPath(idxSelection) = cellstr(...
                            ProjectExplorer.get_full_leaf_path(hLeaf));
                    end %for
                    %confirm operation (for security)
                    answer = questdlg(char(leafPath),...
                        'DELETE?','Yes','No','Yes');
                    switch answer
                        case 'Yes'
                            for idxSelection = 1:numSelected
                                %check type of selected leaf
                                leafType = get(hSelectedList(idxSelection),'Value');
                                if strcmp(leafType,'IsProjectNode')
                                    objProject = get(hSelectedList(idxSelection),'UserData');
                                    objSLIMfast = objProject.Parent;
                                    log_out_project(objSLIMfast,objProject)
                                elseif any(strcmp(leafType,{'IsLeaf','IsCompNode'}))
                                    objData = get(hSelectedList(idxSelection),'UserData');
                                    objProject = objData.Parent;
                                    remove_data_from_project(objProject,objData)
                                elseif strcmp(leafType,'IsChannelLeaf')
                                    objData = get(hSelectedList(idxSelection),'UserData');
                                    objComposite = objData.Parent;
                                    remove_data_from_composite(objComposite,objData)
                                end %if
                            end %for
                            this.hProjectTree.setSelectedNode(this.hRootNode)
                            update_project_tree(this)
                        case 'No'
                            %do nothing
                    end %switch
                case 521 %(=CTRL +)
                    expand_all(this)
            end %switch
        end %fun
        
        %% query
        function [hSelectedList,numSelected,flag] = ...
                get_user_selected_nodes(this)
            %get actually selected objects within explorer
            flag = 1;
            
            %query explorer selection
            hSelectedList = this.hProjectTree.getSelectedNodes;
            if isempty(hSelectedList) %(=no selection)
                flag = 0;
                numSelected = [];
                typeSelected = {};
                return
            else %get number of selected objects
                numSelected = numel(hSelectedList);
            end %if            
        end %fun       
    end %methods
    
    methods(Static)
        function node = generate_node(varargin)
            %input validation
            objInputParser = inputParser;
            addParamValue(objInputParser,...
                'Parent', [], @(x)ishandle(x));
            addParamValue(objInputParser,...
                'Name', [], @(x)ischar(x));
            addParamValue(objInputParser,...
                'Type', [], @(x)ischar(x));
            addParamValue(objInputParser,...
                'UserData', [], @(x)isobject(x));
            addParamValue(objInputParser,...
                'Icon', [], @(x)isnumeric(x));
            addParamValue(objInputParser,...
                'IsLeaf', false, @(x)islogical(x));
            parse(objInputParser,varargin{:});
            inputs = objInputParser.Results;
            
            %generate data node
            node = uitreenode('v0',...
                inputs.Type,inputs.Name,[],inputs.IsLeaf);
            node.setIcon(im2java(inputs.Icon))
            %link project object to data node
            set(node,'UserData', inputs.UserData)
            %append data node to project node
            inputs.Parent.add(node)
        end %fun
        function check_for_empty_class_node(objProject)
            for idx = 1:5
                %check if data node exists
                if ~isempty(objProject.hClassNodes{idx})
                    %check if data node is empty
                    if objProject.hClassNodes{idx}.getChildCount == 0 %(=empty)
                        %remove class node
                        objProject.hClassNodes{idx}.removeFromParent
                        objProject.hClassNodes{idx} = [];
                    end %if
                end %if
            end %for
        end %fun
        function node_drag_and_drop(evnt)
            hSrcNode = get(evnt,'SourceNode');
            hTargetNode = get(evnt,'TargetNode');
            
            %check if source is leaf
            if ~strcmp(get(hSrcNode,'Value'),'IsLeaf')
                return
            end %if
            
            %check if target is channel node
            if any(strcmp(get(hTargetNode,'Name'),...
                    {'Red','Green','Blue','Grey','Cluster','Track'}))
                
                %deep copy object to respective channel node
                objComposite = get(hTargetNode.getParent,'UserData');
                objData = get(hSrcNode,'UserData');
                copy_data_to_composite(objComposite,objData,hTargetNode.getName)
                
                %check if target is project node
            elseif strcmp(get(hTargetNode,'Value'),'IsProjectNode')
                
                %check if transfer is allowed
                if ~isRoot(getSharedAncestor(hSrcNode,hTargetNode))
                    return
                end %if
                
                %deep copy object to new project
                objProject = get(hTargetNode,'UserData');
                objData = get(hSrcNode,'UserData');
                copy_data_to_project(objProject,objData)
            end %if
        end %fun
        function leafPath = get_full_leaf_path(hLeaf)
            %track preceeding leaf path until project node is reached
            jPath = hLeaf.getPath;
            numPath = numel(jPath);
            leafPath = cell(1,numPath);
            for idxPath = 1:numPath
                leafPath(idxPath) = cellstr(get(jPath(idxPath),'Name'));
            end %for
            leafPath = fullfile(leafPath{:});
        end %fun
    end %methods
end %classdef