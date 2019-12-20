function write_variable_to_ascii(obj)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

% if isfield(obj.ExportBin.Data,'Traj_ID') && ...
%         isfield(obj.ExportBin.Data,'Position_X') && ...
%         isfield(obj.ExportBin.Data,'Position_Y') && ...
%         isfield(obj.ExportBin.Data,'Time')
%     answer = questdlg('Export Type?','','Selection','InferenceMAP','Selection');
% else
    answer = 'Selection';
% end %if

switch answer
    case ''
        return
    case 'Selection'
        if ~isempty(obj.ExportBin)
            %check if header information is supplied
            if isfield(obj.ExportBin,'Header')
                hasColHeader = true;
            end %if
            
            if isfield(obj.ExportBin,'Data')
                varNames = fieldnames(obj.ExportBin.Data);
                
                figPos = set_figure_position(1,0.5,'center');
                [selection, isSelected] =...
                    listdlg(...
                    'Name', 'EXPORT MANAGER',...
                    'ListSize', figPos(3:4),...
                    'PromptString','Select a Variable:',...
                    'OKString', 'Export',...
                    'ListString',strrep(varNames,'_',' '));
                
                if isSelected
                    [filename,pathname,isOK] =...
                        uiputfile({'.txt','ASCII File Format (*.txt)'} ,'Save to', ...
                        getappdata(0,'searchPath'));
                    %             pathname = uigetdir(getappdata(0,'searchPath'),...
                    %                 'Select Exportfolder');
                    for var = selection
                        if hasColHeader
                            %check if there is header information for respective
                            %variable
                            if isfield(obj.ExportBin.Header,varNames{var})
                                dlmwrite([pathname filename(1:end-4) '_' varNames{var} '.txt'],...
                                    obj.ExportBin.Header.(varNames{var}),...
                                    'delimiter','','newline', 'pc')
                            end %if
                        end %if
                        %write data column vector to file
                        dlmwrite([pathname filename(1:end-4) '_' varNames{var} '.txt'], ...
                            obj.ExportBin.Data.(varNames{var}), 'delimiter', '\t',...
                            'precision', '%.16e', 'newline', 'pc', '-append')
                    end %for
                    waitfor(msgbox(sprintf(...
                        'Data successfully exported to:\n%s',pathname),'modal'))
                else
                    waitfor(errordlg('No Data for Export selected','','modal'))
                end %if
            else
                waitfor(errordlg('No Data for Export defined','','modal'))
            end %if
        else
            waitfor(errordlg('No Data for Export defined','','modal'))
        end %if
    case 'InferenceMAP'
        [filename,pathname,isOK] =...
            uiputfile({'.trxyt','InferenceMAP Format (*.trxyt)'} ,'Save to', ...
            getappdata(0,'searchPath'));
        
        IDs = unique(obj.ExportBin.Data.Traj_ID);
        data = [ismembc2(obj.ExportBin.Data.Traj_ID,IDs) ...
            obj.ExportBin.Data.Position_X*obj.Px2nm/1000 ...
            obj.ExportBin.Data.Position_Y*obj.Px2nm/1000 ...
            obj.ExportBin.Data.Time*obj.Frame2msec/1000];
        
        fid = fopen(fullfile(pathname,filename),'w');
        fprintf(fid,'%d\t%.4f\t%.4f\t%.4f\t\n',transpose(data));
        fclose(fid);
        
        %         dlmwrite(fullfile(pathname,filename),...
        %             data,'precision','%.4f',...
        %             'delimiter','\t','newline', 'unix')
end %switch
end %fun