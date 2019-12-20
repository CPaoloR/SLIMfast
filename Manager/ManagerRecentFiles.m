classdef ManagerRecentFiles < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties (Hidden)
        Parent %SLIMfast
        
        ListFilename = 'Recent_Files.txt'
        NumListEntries = 10;
    end %properties
    
    methods
        %constructor
        function this = ManagerRecentFiles(parent)
            this.Parent = parent;
            
            %read list of recent files
            [content,cnt] = read_recent_files_ascii(this);
            if cnt > 0
                initialize_menu_entries(this,content,cnt)
            end %if
        end %fun
               
        function initialize_menu_entries(this,content,cnt)
            for fileIdx = 1:cnt
                uimenu(...
                    'Parent', this.Parent.hMenuBar.Project.Load,...
                    'Label', content{fileIdx},...
                    'Callback', @(src,evnt)open_project(this.Parent,content{fileIdx}));
            end %for
            %move "Select File"-Entry to the bottom of the List
            set(this.Parent.hMenuBar.Project.Load,'Children',...
                flipud(get(this.Parent.hMenuBar.Project.Load,'Children')))
        end %fun
        function update_menu_entries(this,filename)
            %1st is "Select File"-Entry, then older->newer
            hMenuEntries = get(this.Parent.hMenuBar.Project.Load,'Children');
            
            %get actual list from file
            [content,cnt] = read_recent_files_ascii(this);
            if cnt < 10 %append new entry
                %check if file is already in the list
                matchIdx = strcmp(filename,content);
                if any(matchIdx)
                   %update file order
                    content = [content(~matchIdx(1:cnt));...
                        content(matchIdx(1:cnt))];
                    %update menu order
                    set(this.Parent.hMenuBar.Project.Load,'Children',...
                        [hMenuEntries([true;~matchIdx(1:cnt)]);...
                        hMenuEntries([false;matchIdx(1:cnt)])])                   
                else
                    %append to the end of the list (=most recent)
                    cnt = cnt +1;
                    content(cnt) = cellstr(filename);
                    
                    %add new entry
                    hMenuEntry = ...
                        uimenu(...
                        'Parent', this.Parent.hMenuBar.Project.Load,...
                        'Label', content{cnt},...
                        'Callback', @(src,evnt)open_project(this.Parent,content{cnt}));
                    
                    %adjust children order
                    set(this.Parent.hMenuBar.Project.Load,'Children',...
                        [hMenuEntries(1:cnt);hMenuEntry;])
                end %if
            else
                %check if file is already in the list
                matchIdx = strcmp(filename,content);
                if any(matchIdx)
                    %update file order
                    content = [content(~matchIdx);content(matchIdx)];
                    %update menu order
                    set(this.Parent.hMenuBar.Project.Load,'Children',...
                        [hMenuEntries([true;~matchIdx]);...
                        hMenuEntries([false;matchIdx])])   
                else
                    %remove 2nd menu entry (=oldest)
                    delete(hMenuEntries(2))
                    hMenuEntries(2) = [];
                    
                    %remove oldest entry
                    content(1) = [];
                    %append to the end of the list (=most recent)
                    content(cnt) = cellstr(filename);
                    
                    %add new entry
                    hMenuEntry = ...
                        uimenu(...
                        'Parent', this.Parent.hMenuBar.Project.Load,...
                        'Label', content{cnt},...
                        'Callback', @(src,evnt)open_project(this.Parent,content{cnt}));
                    
                    %adjust children order
                    set(this.Parent.hMenuBar.Project.Load,'Children',...
                        [hMenuEntries(1:cnt);hMenuEntry;])
                end %if
            end %if
            %write updated list to file
            write_recent_files_ascii(this,content,cnt)
        end %fun
        
        function [content,cnt] = read_recent_files_ascii(this)
            SLIMfastPath = getappdata(0,'SLIMfastPath');
            fid = fopen([SLIMfastPath filesep this.ListFilename],'r');
            if fid >= 3 %successfully opened
                content = cell(this.NumListEntries,1);
                
                cnt = 0;
                string = fgetl(fid);
                while ischar(string)
                    cnt = cnt +1;
                    content(cnt) = cellstr(string);
                    string = fgetl(fid);
                end %while
                flag = fclose(fid);
                if flag == -1 %error handling
                end %if
            else %error handling
                %check if file exists
            end %if
        end %fun
        function write_recent_files_ascii(this,content,cnt)
            SLIMfastPath = getappdata(0,'SLIMfastPath');
            fid = fopen([SLIMfastPath filesep this.ListFilename],'w');
            if fid >= 3 %successfully opened
                for fileIdx = 1:cnt
                    fprintf(fid, '%s\r\n', content{fileIdx});
                end %for
                flag = fclose(fid);
                if flag == -1 %error handling
                end %if
            else %error handling
                %check if file exists
            end %if
        end %fun
    end %methods
end %classdef