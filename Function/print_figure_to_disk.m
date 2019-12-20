function print_figure_to_disk(hFig)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

list = localExportTypes;
[filename,pathname,isOK] =...
    uiputfile(list(:,1:2),...
    'Save Figure as',...
    getappdata(0,'searchPath'));
if isOK
    setappdata(0,'searchPath',pathname)
    %     set(hFig,'renderer','painters')
    [pathname filename ext] = fileparts([pathname filename]);
    if strcmp(list{isOK,3},'.fig')
        hFigOut = figure(...
            'Color',  [1 1 1],...
            'NumberTitle', 'off',...
            'Units', get(hFig,'Units'),...
            'Position', get(hFig,'Position'),...
            'IntegerHandle','off',...
            'Visible','off');
        hAx = findall(hFig,'Type','axes');
        copyobj(hAx,hFigOut)
        set(findobj(hFigOut,'Tag','legend'),'Position',...
            get(findobj(hFig,'Tag','legend'),'Position'))
        saveas(hFigOut,[pathname '\' filename], ext(2:end))
        close(hFigOut)
    else
        hgexport(hFig, [pathname '\' filename list{isOK,3}], ...
            hgexport('factorystyle'), 'Format', list{isOK,4})
    end %if
    
    waitfor(msgbox(sprintf(...
        'Figure successfully saved to:\n%s',...
        [pathname '\' filename list{isOK,3}]),'modal'))
end %if

    function list=localExportTypes
        %Copyright 1984-2011 The MathWorks, Inc.
        
        % build the list dynamically from printtables.m
        [a,opt,ext,d,e,output,name]=printtables;                                %#ok
        
        % only use those marked as export types (rather than print types)
        % and also have a descriptive name
        valid=strcmp(output,'X') & ~strcmp(name,'') & ~strcmp(d, 'QT');
        name = name(valid);
        ext  = ext(valid);
        opt  = opt(valid);
        
        % remove eps formats except for the first one
        iseps = strncmp(name,'EPS',3);
        inds = find(iseps);
        name(inds(2:end),:) = [];
        ext(inds(2:end),:) = [];
        opt(inds(2:end),:) = [];
        
        for i=1:length(ext)
            ext{i} = ['.' ext{i}];
        end
        star_ext = ext;
        for i=1:length(ext)
            star_ext{i} = ['*' ext{i}];
        end
        description = name;
        for i=1:length(name)
            description{i} = [name{i} ' (*' ext{i} ')'];
        end
        
        % add fig file support to front of list
        star_ext = {'*.fig',star_ext{:}};
        description = {'MATLAB Figure (*.fig)',description{:}};
        ext = {'.fig',ext{:}};
        opt = {'fig',opt{:}};
        
        [description,sortind] = sort(description);
        star_ext = star_ext(sortind);
        ext = ext(sortind);
        opt = opt(sortind);
        
        list = [star_ext(:), description(:), ext(:), opt(:)];
    end %nested0
end %fun