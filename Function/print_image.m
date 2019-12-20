function print_image(hAx,cmap,climits)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

hFig = ...
    figure(...
    'Units',get(hAx,'Units'),...
    'Position', get(hAx,'Position'),...
    'NumberTitle', 'off',...
    'IntegerHandle','off',...
    'Resize', 'off',...
    'Visible','off');
hAxClone = copyobj(hAx,hFig);
set(hAxClone,...
    'Units','normalized',...
    'Position', [0 0 1 1])
if ~isempty(cmap)
    colormap(hAxClone,cmap)
end %if
if ~isempty(climits)
    caxis(hAxClone,climits)
end %if

list = localExportTypes;
[filename,pathname,isOK] =...
    uiputfile(list(:,1:2),...
    'Save Image as',...
    getappdata(0,'searchPath'));
if isOK
    setappdata(0,'searchPath',pathname)
    %     set(hFig,'renderer','painters')
    [pathname filename ext] = fileparts([pathname filename]);
    
    set(hFig,'ResizeFcn','set(gcf,''Visible'',''on'')')
    
    if strcmp(list{isOK,3},'.fig')
        saveas(hFig,[pathname '\' filename], ext(2:end))
    else
        print(hFig,list{isOK,5},'-painters',...
            [pathname '\' filename list{isOK,3}])
    end %if
    
    delete(hFig)
        
    waitfor(msgbox(sprintf(...
        'Successfully saved to:\n%s',...
        [pathname '\' filename list{isOK,3}]),'modal'))
else
    
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
        
        list = [star_ext(:), description(:), ext(:), opt(:),...
            {'-dill'; '-dbmp'; '-depsc2'; '-dmeta'; '-djpeg'; ''; '-dpcx24b'; ...
            '-dpbmraw'; '-dpdf'; '-dpgmraw'; '-dpng'; '-dppmraw'; ''; '-dtiff'; '-dtiffn'}]; %CPR
        list(13,:) = [];
    end %nested0
end %fun