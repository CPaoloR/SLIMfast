classdef ClassRoi < matlab.mixin.Copyable
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent %Roi Manager
        Name
        
        Shape
        Type = 'inclusive';
        Units = 'pixel'
        
        ShowLabel = 1;
        
        VerticesRel
    end %properties
    properties (Hidden, Transient)
        hRoi = nan;
        hPatch
        hLabel
        
        hRoiUpdateFcn
        
        hMenuSync
        hSyncListener
        IsSyncDonor
        SyncList = ClassRoi.empty;
        IsSyncAcceptor
        
        listenerDestruction
    end %properties
    properties (Hidden, Dependent)
        Typecolor
        Borderrect %[x0 y0 xEnd yEnd width height]
        Roilabel
    end %properties
    properties (Hidden, SetObservable)
        VerticesAbs
    end %properties
    
    events
        roiDeleted
    end %events
    
    methods
        %constructor
        function this = ClassRoi(parent)
            if nargin > 0
                set_parent(this,parent)
            end %if
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %link destructor to new parent
            this.listenerDestruction = ...
                event.listener(this.Parent,'ObjectDestruction',...
                @(src,evnt)delete_object(this));
        end %fun
        
        function reconstruct_roi(this)
            if ishandle(this.Parent.hFig)
                delete(this.Parent.hFig)
            end %if
            
            %image limits
            imLim = [0 this.Parent.Parent.FieldOfView(5)*this.Parent.Parent.ActExp ...
                0 this.Parent.Parent.FieldOfView(6)*this.Parent.Parent.ActExp]+0.5;
            
            %correct for FieldOfView
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    this.VerticesRel = roi_orig_to_mag(...
                        [this.VerticesAbs(1)-(this.Parent.Parent.FieldOfView(1)-0.5), ...
                        this.VerticesAbs(2)-(this.Parent.Parent.FieldOfView(2)-0.5), ...
                        this.VerticesAbs(3:4)],...
                        this.Parent.Parent.ActExp,this.Shape);
                case 'Polygon'
                    this.VerticesRel = roi_orig_to_mag(...
                        [this.VerticesAbs(:,1)-(this.Parent.Parent.FieldOfView(1)-0.5), ...
                        this.VerticesAbs(:,2)-(this.Parent.Parent.FieldOfView(2)-0.5)], ...
                        this.Parent.Parent.ActExp,this.Shape);
            end %switch
            
            switch this.Shape
                case 'Rectangle'
                    fun = 'imrect';
                case 'Ellipse'
                    fun = 'imellipse';
                case 'Polygon'
                    fun = 'impoly';
            end %switch
            
            this.hRoi = feval(str2func(fun),...
                this.Parent.Parent.hImageAx,this.VerticesRel);
            fcn = makeConstrainToRectFcn(fun,imLim(1:2),imLim(3:4));
            setPositionConstraintFcn(this.hRoi,fcn);
            this.hRoiUpdateFcn = addNewPositionCallback(...
                this.hRoi,@this.update_roilabel);
            
            setColor(this.hRoi, this.Typecolor)
            this.hPatch = ...
                findobj(this.hRoi,'Type','patch');
            set(this.hPatch, ...
                'FaceColor', 'none',...
                'UIContextmenu', construct_roi_contextmenu(this))
            
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    xCtr = this.VerticesRel(1)+0.5*this.VerticesRel(3);
                    yCtr = this.VerticesRel(2)+0.5*this.VerticesRel(4);
                case 'Polygon'
                    xCtr = mean(this.VerticesRel(:,1));
                    yCtr = mean(this.VerticesRel(:,2));
            end %switch
            this.hLabel = text(...
                xCtr, yCtr,...
                this.Roilabel,...
                'Parent', this.Parent.Parent.hImageAx,...
                'FontSize', 12,...
                'FontWeight', 'bold',...
                'Color', [0 1 0],...
                'HorizontalAlignment','center',...
                'VerticalAlignment', 'middle',...
                'HitTest', 'off',...
                'Visible','off');
            if this.ShowLabel
                set(this.hLabel,'Visible','on')
            end %if
        end %fun
        function hContextmenu = construct_roi_contextmenu(this)
            hContextmenu = uicontextmenu(...
                'Parent', this.Parent.Parent.hImageFig);
            hMenuShowLabel = ...
                uimenu(hContextmenu,...
                'Label', 'Show Pos. Info',...
                'Callback', @(src,evnt)change_label_state(this,src));
            if this.ShowLabel
                set(hMenuShowLabel,'Checked', 'on')
            end %if
            hMenuUnits = ...
                uimenu(hContextmenu,...
                'Label', 'Units');
            uimenu(hMenuUnits,...
                'Label', 'pixel',...
                'Callback', @(src,evnt)change_units(this,src));
            uimenu(hMenuUnits,...
                'Label', 'micron',...
                'Callback', @(src,evnt)change_units(this,src));
            set(findobj(hMenuUnits,'Label',this.Units),'Checked','on')
            
            hMenuType = ...
                uimenu(hContextmenu,...
                'Label', 'Type');
            uimenu(hMenuType,...
                'Label', 'inclusive',...
                'Callback', @(src,evnt)change_type(this,src));
            uimenu(hMenuType,...
                'Label', 'exclusive',...
                'Callback', @(src,evnt)change_type(this,src));
            set(findobj(hMenuType,'Label',this.Type),'Checked','on')
            
            uimenu(hContextmenu,...
                'Label', 'Set Position',...
                'Callback', @(src,evnt)change_roi_position(this));
            
            this.hMenuSync = ...
                uimenu(hContextmenu,...
                'Label', 'Sync Position',...
                'Callback', @(src,evnt)sync_roi_position(this,src));
            if any([this.IsSyncDonor,this.IsSyncAcceptor])
                set(this.hMenuSync,'Checked','on')
            end %if
            
            uimenu(hContextmenu,...
                'Label', 'Save ROI',...
                'Separator', 'on',...
                'Callback', @(src,evnt)save_roi(this));
            uimenu(hContextmenu,...
                'Label', 'Delete ROI',...
                'Callback', @(src,evnt)delete_roi(this));
        end %fun
        
        function typecolor = get.Typecolor(this)
            switch this.Type
                case 'inclusive'
                    typecolor = [1 1 1];
                case 'exclusive'
                    typecolor = [1 0 0];
            end %switch
        end %fun
        function borderrect = get.Borderrect(this)
            %[x0 y0 xEnd yEnd width height]
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    x0 = this.VerticesAbs(1);
                    xEnd = this.VerticesAbs(1)+this.VerticesAbs(3);
                    y0 = this.VerticesAbs(2);
                    yEnd = this.VerticesAbs(2)+this.VerticesAbs(4);
                case 'Polygon'
                    x0 = min(this.VerticesAbs(:,1));
                    xEnd = max(this.VerticesAbs(:,1));
                    y0 = min(this.VerticesAbs(:,2));
                    yEnd = max(this.VerticesAbs(:,2));
            end %switch
            borderrect = [...
                floor(x0-0.5)+0.5 ...
                floor(y0-0.5)+0.5 ...
                ceil(xEnd-0.5)+0.5 ...
                ceil(yEnd-0.5)+0.5];
            borderrect = [borderrect ...
                borderrect(3)-borderrect(1) ...
                borderrect(4)-borderrect(2)];
        end %fun
        function roilabel = get.Roilabel(this)
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    x0 = this.VerticesAbs(1);
                    width = this.VerticesAbs(3);
                    y0 = this.VerticesAbs(2);
                    height = this.VerticesAbs(4);
                case 'Polygon'
                    x0 = min(this.VerticesAbs(:,1));
                    width = max(this.VerticesAbs(:,1))-x0;
                    y0 = min(this.VerticesAbs(:,2));
                    height = max(this.VerticesAbs(:,2))-y0;
            end %switch
            
            switch this.Units
                case 'pixel'
                    roilabel = sprintf(...
                        'x0 = %.3f px \n y0 = %.3f px \n width = %.3f px \n height = %.3f px',...
                        x0-0.5,y0-0.5,width,height);
                case 'micron'
                    roilabel = sprintf(...
                        'x0 = %.3f µm \n y0 = %.3f µm \n width = %.3f µm \n height = %.3f µm',...
                        (x0-0.5)*this.Parent.Parent.Px2nm/1000,...
                        (y0-0.5)*this.Parent.Parent.Px2nm/1000,...
                        width*this.Parent.Parent.Px2nm/1000,...
                        height*this.Parent.Parent.Px2nm/1000);
            end %switch
        end %fun
        
        function change_label_state(this,src)
            if strcmp(get(src, 'Checked'),'on')
                set(src, 'Checked', 'off')
                set(this.hLabel,'Visible', 'off')
            else
                set(src, 'Checked', 'on')
                set(this.hLabel,'Visible', 'on')
            end %if
        end
        function change_units(this,src)
            this.Units = get(src, 'Label');
            update_roilabel(this, getPosition(this.hRoi))
            
            %update context menu
            set_contextmenu_state(src,1)
        end %fun
        function change_type(this,src)
            this.Type = get(src, 'Label');
            setColor(this.hRoi, this.Typecolor)
            
            %update context menu
            set_contextmenu_state(src,1)
            
            display_frame(this.Parent.Parent)
        end %fun
        function change_roi_position(this)
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    newPos = zeros(1,4);
                    
                    
                    oldPos = getPosition(this.hRoi)-[0.5 0.5 0 0];
                    setPos = inputdlg(...
                        {'x0 [px] ='; 'y0 [px] = '; 'width [px] = '; 'height [px] = '},...
                        'Position',1,cellstr(num2str(oldPos','%.3f')),struct('WindowStyle','modal'));
                    good = ~cellfun('isempty',setPos);
                    
                    newPos(~good) = oldPos(~good);
                    newPos(good) = str2num(char(setPos{good}));
                    
                    if any(good)
                        setConstrainedPosition(this.hRoi,newPos+[0.5 0.5 0 0])
                    end %if
                otherwise
                    waitfor(errordlg('Not supported for polygonial RoI','','modal'))
            end %switch
        end %fun
        
        function save_roi(this)
            [filename,pathname,isOK] =...
                uiputfile({'*.roi', 'ROI Object (.roi)'},...
                'Save Roi to',[getappdata(0, 'searchPath') ...
                strrep(strrep(this.Name,' ','-'),':','-')]);
            if isOK
                setappdata(0, 'searchPath', pathname)
                
                parent = this.Parent;
                this.Parent = [];
                save([pathname filename],'this', '-mat')
                this.Parent = parent;
                
                waitfor(msgbox(sprintf(...
                    'Roi successfully saved to:\n%s',[pathname filename]),'modal'))
            end %if
        end %fun
        function delete_roi(this)
            delete_roi_reference(this.Parent,this)
            
            %clean up roi object
            delete(this.hRoi)
            delete(this.hLabel)
            delete(this.hSyncListener)
            delete(this)
        end %fun
        
        function update_roilabel(this, position)
            this.VerticesRel = position;
            this.VerticesAbs = roi_mag_to_orig(...
                position,this.Parent.Parent.ActExp,this.Shape);
            
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    this.VerticesAbs(1:2) = [...
                        this.VerticesAbs(1)+(this.Parent.Parent.FieldOfView(1)-0.5) ...
                        this.VerticesAbs(2)+(this.Parent.Parent.FieldOfView(2)-0.5)];
                    xCtr = this.VerticesRel(1)+0.5*this.VerticesRel(3);
                    yCtr = this.VerticesRel(2)+0.5*this.VerticesRel(4);
                case 'Polygon'
                    this.VerticesAbs = [...
                        this.VerticesAbs(:,1)+(this.Parent.Parent.FieldOfView(1)-0.5)...
                        this.VerticesAbs(:,2)+(this.Parent.Parent.FieldOfView(2)-0.5)];
                    xCtr = mean(this.VerticesRel(:,1));
                    yCtr = mean(this.VerticesRel(:,2));
            end %switch
            
            set(this.hLabel, ...
                'Position', [xCtr,yCtr],...
                'String', this.Roilabel)
            
            display_frame(this.Parent.Parent)
        end %fun
        
        function sync_roi_position(this,src)
            if strcmp(get(src, 'Checked'),'on')
                set(src, 'Checked', 'off')
                if this.IsSyncDonor
                    this.IsSyncDonor = 0;
                    for roiIdx = 1:numel(this.SyncList)
                        set(this.SyncList(roiIdx).hMenuSync, 'Checked', 'off')
                        delete(this.SyncList(roiIdx).hSyncListener)
                    end %for
                    this.SyncList = ClassRoi.empty;
                elseif this.IsSyncAcceptor
                    this.IsSyncAcceptor = 0;
                    delete(this.hSyncListener)
                end %if
            else
                syncList = ClassRoi.empty;
                
                hSLIMfast = get_parental_object(this,'SLIMfast');
                %search projects
                for projectIdx = 1:numel(hSLIMfast.Projects)
                    %search classes
                    for classIdx = 1:numel(hSLIMfast.Projects(projectIdx).objData)
                        %search data objects
                        numData = numel(hSLIMfast.Projects(projectIdx).objData{classIdx});
                        if numData > 0
                            for dataIdx = 1:numData
                                %check if object contains a region of interest
                                if hSLIMfast.Projects(projectIdx).objData{classIdx}(dataIdx).objRoi.HasRoi
                                    for roiIdx = 1:hSLIMfast.Projects(projectIdx).objData{classIdx}(dataIdx).objRoi.NumRoi
                                        %ckeck if roi shapes match
                                        if strcmp(this.Shape,...
                                                hSLIMfast.Projects(projectIdx).objData{classIdx}(dataIdx).objRoi.RoiList(roiIdx).Shape)
                                            %add to list
                                            syncList = [syncList; ...
                                                hSLIMfast.Projects(projectIdx).objData{classIdx}(dataIdx).objRoi.RoiList(roiIdx)];
                                        end %if
                                    end %for
                                end %if
                            end %if
                        end %for
                    end %for
                end %for
                
                %remove actual roi
                syncList(eq(this,syncList)) = [];
                
                if isempty(syncList)
                    waitfor(errordlg('No shape matching RoI''s found','','modal'))
                else
                    %select roi to become synced
                    [selection,isOK] = listdlg('PromptString','Select RoI to link:',...
                        'ListString',{syncList.Name});
                    this.SyncList = syncList(selection);
                    if isOK
                        this.IsSyncDonor = 1;
                        %generate sync listener to donors roi position
                        for roiIdx = 1:numel(this.SyncList)
                            this.SyncList(roiIdx).IsSyncAcceptor = 1;
                            this.SyncList(roiIdx).hSyncListener = addlistener(this,'VerticesAbs','PostSet',...
                                @(src,evnt)adjust_position(this.SyncList(roiIdx),this.VerticesAbs));
                            set(this.SyncList(roiIdx).hMenuSync, 'Checked', 'on')
                        end %for
                        set(src, 'Checked', 'on')
                        
                        %sync actual position immediatly
                        this.VerticesAbs = this.VerticesAbs;
                    end %if
                end %if
            end %if
        end %fun
        function update_position(this,position)
            this.VerticesAbs = position;
        end %fun
        function adjust_position(this,position)
            %correct for FieldOfView
            switch this.Shape
                case {'Rectangle', 'Ellipse'}
                    this.VerticesRel = roi_orig_to_mag(...
                        [position(1)-(this.Parent.Parent.FieldOfView(1)-0.5), ...
                        position(2)-(this.Parent.Parent.FieldOfView(2)-0.5), ...
                        position(3:4)],...
                        this.Parent.Parent.ActExp,this.Shape);
                case 'Polygon'
                    this.VerticesRel = roi_orig_to_mag(...
                        [position(:,1)-(this.Parent.Parent.FieldOfView(1)-0.5), ...
                        position(:,2)-(this.Parent.Parent.FieldOfView(2)-0.5)], ...
                        this.Parent.Parent.ActExp,this.Shape);
            end %switch
            
            setPosition(this.hRoi,this.VerticesRel)
            
            %image limits
            imLim = [0 this.Parent.Parent.FieldOfView(5)*this.Parent.Parent.ActExp ...
                0 this.Parent.Parent.FieldOfView(6)*this.Parent.Parent.ActExp]+0.5;
            
            switch this.Shape
                case 'Rectangle'
                    fun = 'imrect';
                case 'Ellipse'
                    fun = 'imellipse';
                case 'Polygon'
                    fun = 'impoly';
            end %switch
            fcn = makeConstrainToRectFcn(fun,imLim(1:2),imLim(3:4));
            setPositionConstraintFcn(this.hRoi,fcn);
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
            this = ClassRoi;
            
            if isobject(S)
                S = saveobj(S);
            end
            
            this = reload(this,S);
        end %fun
    end %methods
end %classdef