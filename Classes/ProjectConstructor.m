classdef ProjectConstructor < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent %SLIMfast
        Title = 'Nameless Project';
        
        objChannelConfig
    end %properties
    properties(Hidden, Transient)
        hFileFig = nan;
        hFileList
        hProceedButton
        
        listenerDestruction
    end %fun
    
    events
        ObjectDestruction
    end %events
    
    methods
        %constructor
        function this = ProjectConstructor(parent)
            this.Parent = parent;
            
            %fired when parent (SLIMfast) gets closed
            this.listenerDestruction = ...
                event.listener(parent,'ObjectDestruction',...
                @(src,evnt)delete_object(this));
        end %fun
        function open_project_constructor(this)
            this.objChannelConfig = ChannelConfig;
            
            %check if gui already open
            if ~ishandle(this.hFileFig)
                %                 scrSize = get(0, 'ScreenSize');
                
                this.hFileFig =...
                    figure(...
                    'Units','normalized',...
                    'Position', [0.3 0.4 0.4 0.2],...
                    'Name', 'IMAGE CONTAINER',...
                    'NumberTitle', 'off',...
                    'MenuBar', 'none',...
                    'ToolBar', 'none',...
                    'IntegerHandle','off',...
                    'Resize', 'off');
                
                %                 uicontrol(...
                %                     'Style', 'text',...
                %                     'Parent', this.hFileFig,...
                %                     'Units','normalized',...
                %                     'Position', [0 0.8 0.3 0.2],...
                %                     'FontSize', 20,...
                %                     'String', 'Title:');
                %
                %                 uicontrol(...
                %                     'Style', 'edit',...
                %                     'Parent', this.hFileFig,...
                %                     'Units','normalized',...
                %                     'Position', [0.3 0.8 0.6 0.2],...
                %                     'BackgroundColor', [1 1 1],...
                %                     'FontSize', 18,...
                %                     'String', this.Title,...
                %                     'Callback', @(src,evnt)set_Title(this,src));
                
                uicontrol(...
                    'Style', 'text',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0 0 0.3 0.2],...
                    'FontSize', 20,...
                    'String', 'Options:');
                
                uicontrol(...
                    'Style', 'checkbox',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.3 0 0.3 0.2],...
                    'FontSize', 18,...
                    'String', 'catenate',...
                    'Value', 0,...
                    'Callback', @(src,evnt)set_UseCatenate(this,src));
                
                uicontrol(...
                    'Style', 'checkbox',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.6 0 0.3 0.2],...
                    'FontSize', 18,...
                    'String', 'multicolor',...
                    'Value', 0,...
                    'Callback', @(src,evnt)set_IsMultiColor(this,src));
                
                this.hFileList =...
                    uicontrol(...
                    'Style', 'listbox',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0 0.2 0.9 0.8],...
                    'BackgroundColor', [1 1 1],...
                    'FontSize', 14);
                
                uicontrol(...
                    'Style', 'pushbutton',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.9 0.8 0.1 0.2],...
                    'FontSize', 25,...
                    'String', '+',...
                    'Callback', @(src,evnt)add_file_to_list(this))
                
                uicontrol(...
                    'Style', 'pushbutton',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.9 0.6 0.1 0.2],...
                    'FontSize', 30,...
                    'String', '-',...
                    'Callback', @(src,evnt)delete_file_from_list(this))
                
                uicontrol(...
                    'Style', 'pushbutton',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.9 0.4 0.1 0.2],...
                    'FontSize', 10,...
                    'String', 'UP',...
                    'Callback', @(src,evnt)move_file_up(this))
                
                uicontrol(...
                    'Style', 'pushbutton',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.9 0.2 0.1 0.2],...
                    'FontSize', 10,...
                    'String', 'DOWN',...
                    'Callback', @(src,evnt)move_file_down(this))
                
                this.hProceedButton = ...
                    uicontrol(...
                    'Style', 'pushbutton',...
                    'Parent', this.hFileFig,...
                    'Units','normalized',...
                    'Position', [0.9 0 0.1 0.2],...
                    'FontSize', 10,...
                    'String', 'OK',...
                    'Callback',@(src,evnt)initialize_project(this));
            end %if
        end %fun
        
        function add_file_to_list(this)
            bfCheckJavaPath;
            [filename,filepath,isOK] = uigetfile(bfGetFileExtensions,...
                'Select Imagestack', getappdata(0,'searchPath'),...
                'MultiSelect', 'on');
            
            %             [filename, filepath,isOK] = uigetfile({...
            %                 '*.tif;*.btf', 'Supported Imageformats TIFF or BigTIFF (.tif, .btf)'},...
            %                 'Select Imagestack', getappdata(0,'searchPath'),...
            %                 'MultiSelect', 'on');
            if isOK
                setappdata(0,'searchPath',filepath)
                
                fileList = get(this.hFileList, 'String');
                fileListNew = cellstr(strcat(filepath, filename));
                fileList = [fileList',fileListNew];
                set(this.hFileList, 'String', fileList,...
                    'Value', size(fileList,1))
            else
                return
            end %if
        end %nested0
        function delete_file_from_list(this)
            bad = get(this.hFileList, 'Value');
            fileList = get(this.hFileList, 'String');
            if isempty(fileList)
                return
            else
                fileList(bad) = [];
                set(this.hFileList, 'String', fileList,...
                    'Value', min(bad,size(fileList,1)))
            end %if
        end %nested0
        function move_file_up(this)
            pos = get(this.hFileList, 'Value');
            if pos > 1
                fileList = get(this.hFileList, 'String');
                fileList(pos-1:pos) = [fileList(pos); fileList(pos-1)];
                set(this.hFileList, 'String', fileList, 'Value', pos-1)
            else
                return
            end %if
        end %nested0
        function move_file_down(this)
            pos = get(this.hFileList, 'Value');
            fileList = get(this.hFileList, 'String');
            if pos < numel(fileList)
                fileList(pos:pos+1) = [fileList(pos+1); fileList(pos)];
                set(this.hFileList, 'String', fileList, 'Value', pos+1)
            else
                return
            end %if
        end %nested0
        
        function set_Title(this,src)
            string = get(src,'String');
            %check for unallowed characters within title
            this.Title = string;
        end %fun
        function set_UseCatenate(this,src)
            this.objChannelConfig.UseCatenate = get(src,'Value');
        end %fun
        function set_IsMultiColor(this,src)
            this.objChannelConfig.IsMultiColor = get(src,'Value');
            
            if this.objChannelConfig.IsMultiColor
                set(this.hProceedButton,...
                    'Callback',@(src,evnt)initialize_multicolor_configuration(this))
            else
                set(this.hProceedButton,...
                    'Callback',@(src,evnt)initialize_project(this))
            end %if
        end %fun
        
        function initialize_project(this)
            fileList = get(this.hFileList, 'String');
            if isempty(fileList) %(=no files selected)
                initialize_empty_project(this)
            else
                set(this.hFileFig,'Visible','off')
                hProgressbar = ClassProgressbar({'Project Initialization...',...
                    'Processing Channel...','Loading File...'});
                
                %get # channels in case of multi-color data
                numChannels = max(...
                    this.objChannelConfig.NumAlternatingChannels,...
                    this.objChannelConfig.NumParallelChannels);
                
                objSLIMfast = this.Parent;
                if this.objChannelConfig.UseCatenate %(=superstack)
                    %initialize project
                    objProject = ClassProject;
                    set_parent(objProject,objSLIMfast)
                    log_in_project(objSLIMfast,objProject)
                    
                    for channelIdx = 1:numChannels
                        %initialize raw data object
                        objRaw = ClassRaw;
                        objRaw.Channel = channelIdx;
                        set_parent(objRaw,objProject)
                        
                        %recognize image file
                        objRaw.objImageFile = ManagerImageFile(objRaw,...
                            fileList,this.objChannelConfig,hProgressbar);
                        
                        %check image dimensions (in case of superstack)
                        if numel(objRaw.objImageFile.ImageWidth) > 1 ||...
                                numel(objRaw.objImageFile.ImageHeight) > 1
                            waitfor(errordlg('Images have different size','','modal'))
                            log_out_project(objSLIMfast,objProject)
                            close_progressbar(hProgressbar)
                            
                            set(this.hFileFig,'Visible','on')
                            figure(this.hFileFig)
                            
                            return
                        end %if
                        
                        %initialize all associated manager objects
                        objRaw.objContrastSettings = ManagerContrastSettings(objRaw);
                        objRaw.objUnitConvFac = ManagerUnitConvFac(objRaw);
                        objRaw.objLocSettings = ManagerLocSettings(objRaw);
                        objRaw.objColormap = ManagerColormap(objRaw);
                        objRaw.objGrid = ManagerGrid(objRaw);
                        objRaw.objRoi = ManagerRoi(objRaw);
                        objRaw.objScalebar = ManagerScalebar(objRaw);
                        objRaw.objTimestamp = ManagerTimestamp(objRaw);
                        objRaw.objTextstamp = ManagerTextstamp(objRaw);
                        objRaw.objDisplaySettings = ManagerDisplaySettings(objRaw);
                        objRaw.objLineProfile = ManagerLineProfile(objRaw);
                        
                        %set initial field of view (=image size)
                        objRaw.FieldOfView = ...
                            [0.5 0.5 ...
                            objRaw.objImageFile.ChannelWidth+0.5 ...
                            objRaw.objImageFile.ChannelHeight+0.5 ...
                            objRaw.objImageFile.ChannelWidth ...
                            objRaw.objImageFile.ChannelHeight];
                        
                        isOK = show_frame(objRaw,1);
                        if ~isOK
                            waitfor(errordlg(sprintf(...
                                'Error loading\n%s\Project discarded',fileList{1}),'','modal'))
                            log_out_project(objSLIMfast,objProject)
                            close_progressbar(hProgressbar)
                            
                            set(this.hFileFig,'Visible','on')
                            figure(this.hFileFig)
                            
                            return
                        end %if
                        add_data_to_project(objProject,objRaw)
                        
                        %                         initialize_visualization(objRaw)
                        update_progressbar(hProgressbar,...
                            {[],channelIdx/numChannels,[]})
                    end %for
                else
                    numFiles = numel(fileList);
                    for file = 1:numFiles
                        %initialize project
                        objProject = ClassProject;
                        set_parent(objProject,objSLIMfast)
                        log_in_project(objSLIMfast,objProject)
                        
                        for channelIdx = 1:numChannels
                            %initialize raw data object
                            objRaw = ClassRaw;
                            objRaw.Channel = channelIdx;
                            set_parent(objRaw,objProject)
                            
                            %recognize image file
                            objRaw.objImageFile = ManagerImageFile(objRaw,...
                                fileList(file),this.objChannelConfig,hProgressbar);
                            
                            %initialize all associated manager objects
                            objRaw.objContrastSettings = ManagerContrastSettings(objRaw);
                            objRaw.objUnitConvFac = ManagerUnitConvFac(objRaw);
                            objRaw.objLocSettings = ManagerLocSettings(objRaw);
                            objRaw.objColormap = ManagerColormap(objRaw);
                            objRaw.objGrid = ManagerGrid(objRaw);
                            objRaw.objRoi = ManagerRoi(objRaw);
                            objRaw.objScalebar = ManagerScalebar(objRaw);
                            objRaw.objTimestamp = ManagerTimestamp(objRaw);
                            objRaw.objTextstamp = ManagerTextstamp(objRaw);
                            objRaw.objDisplaySettings = ManagerDisplaySettings(objRaw);
                            objRaw.objLineProfile = ManagerLineProfile(objRaw);
                            
                            %set initial field of view (=image size)
                            objRaw.FieldOfView = ...
                                [0.5 0.5 ...
                                objRaw.objImageFile.ChannelWidth+0.5 ...
                                objRaw.objImageFile.ChannelHeight+0.5 ...
                                objRaw.objImageFile.ChannelWidth ...
                                objRaw.objImageFile.ChannelHeight];
                            
                            isOK = show_frame(objRaw,1);
                            if ~isOK
                                errordlg(sprintf(...
                                    'Error loading\n%s\Project discarded',fileList{file}),'')
                                log_out_project(objSLIMfast,objProject)
                                
                                break
                            end %if
                            add_data_to_project(objProject,objRaw)
                            
                            %                             initialize_visualization(objRaw)
                            update_progressbar(hProgressbar,...
                                {[],channelIdx/numChannels,[]})
                        end %for
                        
                        update_progressbar(hProgressbar,{file/numFiles,[],[]})
                    end %for
                end %if
                pause(0.1)
                update_progressbar(hProgressbar,{1,[],[]})
                pause(0.1)
                
                delete(this.hFileFig)
                close_progressbar(hProgressbar)
            end %if
        end %nested0
        function initialize_empty_project(this)
            objProject = ClassProject;
            objSLIMfast = this.Parent;
            set_parent(objProject,objSLIMfast)
            log_in_project(objSLIMfast,objProject)
            
            delete(this.hFileFig)
        end %fun
        
        function initialize_multicolor_configuration(this)
            objCal = ClassCalibration;
            set_parent(objCal,this)
            set_multicolor_configuration(objCal)
        end %fun
        
        %%
        function delete_object(this)
            notify(this,'ObjectDestruction')
            
            if ishandle(this.hFileFig)
                delete(this.hFileFig)
            end %if
            
            delete(this)
        end %fun
    end %methods
end %classdef