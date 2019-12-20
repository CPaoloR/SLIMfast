classdef SuperclassContainer < matlab.mixin.Copyable
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden)
        Parent
        
        Profile = 'None'
    end %properties
    properties (Hidden,Transient)
        Profiles
        
        listenerDestruction
    end %fun
    
    methods
        %constructor
        function this = SuperclassContainer(parent)
            if ~isempty(parent)
                this.Parent = parent;
                
                %load settings from profile (disc)
                initialize_settings(this)
                
                %initialize listener
                this.listenerDestruction = ...
                    event.listener(this.Parent,'ObjectDestruction',...
                    @(src,evnt)delete_object(this));
            end %if
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %link destructor to new parent
            this.listenerDestruction = ...
                event.listener(this.Parent,'ObjectDestruction',...
                @(src,evnt)delete_object(this));
        end %fun
        
        function initialize_settings(this)
            %get actually selected profile
            objSLIMfast = getappdata(0,'objSLIMfast');
            this.Profiles = [get(allchild(...
                objSLIMfast.hMenuBar.Extra.Profile),'Label');...
                cellstr('None')];
            
            %initialize container with actually selected profile
            this.Profile = get(findobj(objSLIMfast.hMenuBar.Extra.Profile,...
                'Checked','on'),'Label');
            if ~strcmp(this.Profile,'Standard')
                %load user profile
                SLIMfastPath = getappdata(0,'SLIMfastPath');
                filename = fullfile(SLIMfastPath,...
                    'Profiles', [this.Profile '.txt']);
                load_settings_from_disc(this,filename)
            end %if
        end %fun
        function load_settings_from_disc(this,filename)
            %check that profile exists
            if ~exist(filename,'file') == 2
                %if profile file not found switch to internal standard
                this.Profile = 'Standard';
                return
            end %if
            
            %construct meta properties object
            classInfo = metaclass(this);
            classProbs = classInfo.PropertyList;
            classProp2Load = ~([classProbs.Hidden]);
            if ~any(classProp2Load)
                %there is no parameter to load
                return
            else
                classPropNames = cellstr(char(classProbs(classProp2Load).Name));
            end %if
            
            %open profile file
            fid = fopen(filename);
            if fid < 3 %(file error)
                %if profile file cannot be opended switch to internal standard
                this.Profile = 'Standard';
                return
            end %if
            
            %find respective container headline
            string = '';
            while ~strcmp(string,this.ProfileStartMarker)
                if feof(fid) %end of file
                    disp(sprintf('%s not found inside %s',...
                        this.ProfileStartMarker,filename))
                    %if headline not found switch to internal standard
                    this.Profile = 'Standard';
                    return
                end %if
                %read until properties for respective object start
                string = fgetl(fid);
            end %while
            
            %iterate until all properties are defined
            classPropLoaded = false(1,sum(classProp2Load));
            while ~all(classPropLoaded)
                string = fgetl(fid);
                %check for empty line
                if ~isempty(string)
                    %scan assuming data is character
                    data = textscan(string,'%s %q','delimiter','=');
                    %check if param is valid container class property
                    classProb = data{1}{1};
                    isClassProp = strcmp(classProb,classPropNames);
                    if any(isClassProp)
                        classPropLoaded(isClassProp) = true;
                        
                        %check final property format
                        if isa(this.(classProb),'logical')
                            this.(classProb) = logical(str2num(data{2}{1}));
                        elseif isa(this.(classProb),'char')
                            this.(classProb) = data{2}{1};
                        elseif isa(this.(classProb),'numeric')
                            this.(classProb) = str2num(data{2}{1});
                        end %if
                    end %if
                    
                    %break loop when container end is reached
                    if strcmp(string(1),'[') && strcmp(string(end),']')
                        disp(char(strcat(classPropNames(~classPropLoaded),...
                            ' not found within: ', filename)))
                        %properties not found will have internal standard
                        break
                    end %if
                end %if
            end %while
            fclose(fid);
        end %fun
        function set_standard_properties(this)
            %reset to internal standard
            objContainer = feval(class(this));
            classInfo = metaclass(objContainer);
            classProp = classInfo.PropertyList;
            classPropNames = cellstr(char(classProp(...
                ~([classProp.Hidden])).Name));
            
            for idxClassProp = 1:numel(classPropNames)
                this.(classPropNames{idxClassProp}) = ...
                    objContainer.(classPropNames{idxClassProp});
            end %for
        end %fun
        
        function get_actual_profiles(this)
            %get actually selected profile
            objSLIMfast = getappdata(0,'objSLIMfast');
            this.Profiles = [get(allchild(...
                objSLIMfast.hMenuBar.Extra.Profile),'Label');...
                cellstr('None')];
            if ~any(strcmp(this.Profile,this.Profiles))
                %used profile no longer within profiles folder
                this.Profile = 'None';
            end %if
        end %fun
        
        function save_actual_properties_as_profile(this)
            %construct meta properties object
            classInfo = metaclass(this);
            classProbs = classInfo.PropertyList;
            classProp2Save = ~([classProbs.Hidden]);
            classPropNames = cellstr(char(classProbs(classProp2Save).Name));
            
            %generate new profile
            [filename,pathname,isOK] =...
                uiputfile({'*.txt', 'SLIMfast Profile (.txt)'},...
                'Save Profile to',[getappdata(0, 'SLIMfastPath') '\Profiles']);
            if ~isOK
                return
            end %if
            
            if exist([pathname filename],'file') ~= 2
                %create new profile
                fid = fopen([pathname filename],'a');
                append_profile_block_to_file(this,fid,classPropNames)
            else %update existing profile
                %check for existence of respective profile properties
                fid = fopen([pathname filename],'r');
                [startPos, endPos, isOK] = find_profile_block_within_file(this,fid);
                fclose(fid);
                if isOK
                    %rename actual profile
                    movefile([pathname filename],...
                        [pathname filename(1:end-4) '_old.txt'])
                    %open old profile for reading
                    fidOldProfile = fopen([pathname filename(1:end-4) '_old.txt'],'r');
                    %create new profile
                    fidNewProfile = fopen([pathname filename],'w');
                    
                    %copy old profile except actually modified profile
                    %block
                    while ~feof(fidOldProfile)
                        string = fgetl(fidOldProfile);
                        %loop through complete file
                        actPos = ftell(fidOldProfile);
                        if actPos == startPos
                            %move to the end of profile block
                            fseek(fidOldProfile,endPos-startPos,'cof');
                            string = fgetl(fidOldProfile);
                            if string == -1
                                %end of file reached
                                break
                            end %if
                        end %if
                        %copy
                        fprintf(fidNewProfile,'%s\r\n',string);
                    end %while
                    %append profile property block to the end
                    append_profile_block_to_file(this,fidNewProfile,classPropNames)
                    fclose(fidNewProfile);
                    fclose(fidOldProfile);
                    delete([pathname filename(1:end-4) '_old.txt'])
                else %profile block not found
                    %append profile property block to the end
                    fid = fopen([pathname filename],'a');
                    append_profile_block_to_file(this,fid,classPropNames)
                    fclose(fid);
                end %if
            end %if
            
            waitfor(msgbox(sprintf(...
                'Profile saved to:\n%s',[pathname filename]),'modal'))
        end %fun
        function append_profile_block_to_file(this,fid,classPropNames)
            fprintf(fid,'\r\n%s\r\n',this.ProfileStartMarker);
            for idxProp = 1:numel(classPropNames)
                if isa(this.(classPropNames{idxProp}),'logical') || ...
                        isa(this.(classPropNames{idxProp}),'numeric')
                    value = num2str(this.(classPropNames{idxProp}));
                else
                    value = this.(classPropNames{idxProp});
                end %if
                fprintf(fid, '%s="%s"\r\n', ...
                    classPropNames{idxProp},value);
            end %for
            fprintf(fid,'%s\r\n',this.ProfileEndMarker);
        end %fun
        
        function [startPos, endPos, isOK] = find_profile_block_within_file(this,fid)
            %initialize output variables
            startPos = [];
            endPos = [];
            isOK = true;
            
            %find start marker
            string = '';
            while ~strcmp(string,this.ProfileStartMarker)
                if feof(fid) %end of file
                    %start marker not found
                    isOK = false;
                    return
                end %if
                %read successive file line
                string = fgetl(fid);
            end %while
            startPos = ftell(fid);
            
            %find end marker
            while ~strcmp(string,this.ProfileEndMarker)
                if feof(fid) %end of file
                    %end marker missing -> put it now
                    fprintf(fid,'%s',this.ProfileEndMarker);
                end %if
                %read successive file line
                string = fgetl(fid);
            end %while
            endPos = ftell(fid);
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
            delete(this)
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