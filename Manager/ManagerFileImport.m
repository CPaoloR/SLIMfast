classdef ManagerFileImport < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent %SLIMfast
    end %properties
    
    methods
        %constructor
        function this = ManagerFileImport(parent)
            this.Parent = parent;
        end %fun
        
        function import_SLIMfast_old_generation(this)
            [filename, filepath,isOK] = uigetfile({...
                '*.mat', 'SLIMfast Data Container(.mat)'},...
                'Select File', getappdata(0,'searchPath'),...
                'MultiSelect', 'off');
            if ~isOK
                return
            end %if
            setappdata(0,'searchPath',filepath)
            
            hProgressbar = ClassProgressbar({'Project Import...'});
            
            import = load([filepath filename]);
            if isfield(import,'imageBin')
                dataType = 'Localization';
            else
                dataType = 'Tracking';
            end %if
            update_progressbar(hProgressbar,{0.05})
            
            objSLIMfast = this.Parent;
            objProject = ClassProject;
            set_parent(objProject,objSLIMfast)
            log_in_project(objSLIMfast,objProject)
            
            %generate raw object
            objRaw = ClassRaw;
            set_parent(objRaw,objProject)
            
            %import conversion factors
            objRaw.objUnitConvFac = ManagerUnitConvFac(objRaw);
            switch dataType
                case 'Localization'
                    candidates = {'pxSize'};
                    good = isfield(import.imageBin,candidates);
                    if any(good)
                        objRaw.objUnitConvFac.SrcContainer.('Px2nm') = ...
                            import.imageBin.(candidates{good})*1000;
                    end %if
                    candidates = {'timestampInkrement'};
                    good = isfield(import.imageBin,candidates);
                    if any(good)
                        objRaw.objUnitConvFac.SrcContainer.('Frame2msec') = ...
                            import.imageBin.(candidates{good})*1000;
                    end %if
                    candidates = {'cntsPerPhoton'};
                    good = isfield(import.imageBin,candidates);
                    if any(good)
                        objRaw.objUnitConvFac.SrcContainer.('Count2photon') = ...
                            round(1000/import.imageBin.(candidates{good}))/1000;
                    end %if
                case 'Tracking'
                    candidates = {'px2micron'};
                    good = isfield(import.settings,candidates);
                    if any(good)
                        objRaw.objUnitConvFac.SrcContainer.('Px2nm') = ...
                            import.settings.(candidates{good})*1000;
                    end %if
                    candidates = {'Delay'};
                    good = isfield(import.settings,candidates);
                    if any(good)
                        objRaw.objUnitConvFac.SrcContainer.('Frame2msec') = ...
                            import.settings.(candidates{good})*1000;
                    end %if
                    objRaw.objUnitConvFac.SrcContainer.('Count2photon') = 0.05;
                    
                    [filenameCorrect, filepathCorrect,isOK] = uigetfile({...
                        '*.tif;*.btf', 'Supported Imageformats TIFF or BigTIFF (.tif, .btf)'},...
                        'Select Imagestack', getappdata(0,'searchPath'));
                    if isOK
                        setappdata(0,'searchPath',filepathCorrect)
                        import.imageBin.imageName = [filepathCorrect filenameCorrect];
                    else
                        return
                    end %if
            end %switch
            set_parameter(objRaw.objUnitConvFac)
            waitfor(objRaw.objUnitConvFac.hFig)
            
            objRaw.Channel = 1;
            objChannelConfig = ChannelConfig;
            
            update_progressbar(hProgressbar,{0.1})
            
            %check if image file exists (in case it was renamed or
            %moved to a different directory)
            if exist(import.imageBin.imageName,'file') == 2
                isOK = 1;
            else
                answer = questdlg(sprintf('%s not found',import.imageBin.imageName),'ERROR',...
                    'Set new Filename','Abort','Set new Filename');
                switch answer
                    case 'Set new Filename'
                        [filenameCorrect, filepathCorrect,isOK] = uigetfile({...
                            '*.tif;*.btf', 'Supported Imageformats TIFF or BigTIFF (.tif, .btf)'},...
                            'Select Imagestack', getappdata(0,'searchPath'));
                        if isOK
                            setappdata(0,'searchPath',filepathCorrect)
                            import.imageBin.imageName = [filepathCorrect filenameCorrect];
                        else
                            return
                        end %if
                    case 'Abort'
                        isOK = 0;
                        return
                end %switch
            end %if
            objRaw.objImageFile = ManagerImageFile(objRaw,...
                {import.imageBin.imageName},objChannelConfig,[]);
            
            update_progressbar(hProgressbar,{0.2})
            
            objRaw.objContrastSettings = ManagerContrastSettings(objRaw);
            objRaw.objLocSettings = ManagerLocSettings(objRaw);
            switch dataType
                case 'Localization'
                    %import localization options
                    locFields = struct(...
                        'ErrRate',{{'errorRate'}},...
                        'WinX',{{'w2d'}},...
                        'WinY',{{'w2d'}},...
                        'NumDeflat',{{'dfltnLoops'}},...
                        'MinInt',{{'minInt'}},...
                        'MaxIter',{{'maxOptimIter'}},...
                        'TermTol',{{'termTol'}},...
                        'MaxPosRef',{{'posTol'}},...
                        'LocPar',{{'locParallel'}},...
                        'nCores',{{'nCores'}},...
                        'LocLive',{{'rLive'}},...
                        'NA',{{'NA'}},...
                        'CorrFactor',{{'psfScale'}},...
                        'UserEmWavelength',{{'emWvlnth'}});
                    for field = reshape(fieldnames(locFields),1,[])
                        %check if variable exists
                        candidates = locFields.(field{:});
                        good = isfield(import.imageBin,candidates);
                        if any(good)
                            objRaw.objLocSettings.SrcContainer.(field{:}) = ...
                                import.imageBin.(candidates{good});
                        end %if
                    end %for
                case 'Tracking'
            end %switch
            objRaw.objLocSettings.SrcContainer.Chromophor = 'User Supplied';
            objRaw.objLocSettings.SrcContainer.hEditEmWavelengthState = 'on';
            objRaw.objLocSettings.SrcContainer.EmWavelength = ...
                objRaw.objLocSettings.SrcContainer.UserEmWavelength;
            
            update_progressbar(hProgressbar,{0.3})
            
            objRaw.objColormap = ManagerColormap(objRaw);
            objRaw.objGrid = ManagerGrid(objRaw);
            objRaw.objRoi = ManagerRoi(objRaw);
            objRaw.objScalebar = ManagerScalebar(objRaw);
            objRaw.objTimestamp = ManagerTimestamp(objRaw);
            objRaw.objTextstamp = ManagerTextstamp(objRaw);
            objRaw.objLineProfile = ManagerLineProfile(objRaw);            
            objRaw.objDisplaySettings = ManagerDisplaySettings(objRaw);
            
            objRaw.FieldOfView = ...
                [0.5 0.5 ...
                objRaw.objImageFile.ChannelWidth+0.5 ...
                objRaw.objImageFile.ChannelHeight+0.5 ...
                objRaw.objImageFile.ChannelWidth ...
                objRaw.objImageFile.ChannelHeight];
            
            isOK = show_frame(objRaw,1);
            add_data_to_project(objProject,objRaw)
            
            update_progressbar(hProgressbar,{0.4})
            
            switch dataType
                case 'Localization'
                    objLoc = ClassLocalization;
                    set_parent(objLoc,objProject)
                    objLoc.Dim = 2;
                    
                    objLoc.objImageFile = copy(objRaw.objImageFile);
                    set_parent(objLoc.objImageFile,objLoc)
                    objLoc.objUnitConvFac = copy(objRaw.objUnitConvFac);
                    set_parent(objLoc.objUnitConvFac,objLoc)
                    objLoc.objLocSettings = copy(objRaw.objLocSettings);
                    set_parent(objLoc.objLocSettings,objLoc)
                    
                    objLoc.objContrastSettings = ManagerContrastSettings(objLoc);
                    objLoc.objDisplaySettings = ManagerDisplaySettings(objLoc);
                    objLoc.objTrackSettings = ManagerTrackSettings(objLoc);
                    objLoc.objClusterSettings = ManagerClusterSettings(objLoc);
                    
                    objLoc.objColormap = ManagerColormap(objLoc);
                    objLoc.objGrid = ManagerGrid(objLoc);
                    objLoc.objRoi = ManagerRoi(objLoc);
                    objLoc.objScalebar = ManagerScalebar(objLoc);
                    objLoc.objTimestamp = ManagerTimestamp(objLoc);
                    objLoc.objTextstamp = ManagerTextstamp(objLoc);
                    objLoc.objLineProfile = ManagerLineProfile(objLoc);
                    objLoc.objDisplaySettings = ManagerDisplaySettings(objLoc);
                    
                    objLoc.NumParticles = sum(import.imageBin.ctrsN);
                    objLoc.DetectionMap = 0;
                    objLoc.FieldOfView = objRaw.FieldOfView;
                    
                    update_progressbar(hProgressbar,{0.5})
                    
                    varNames = {...
                        'radius', ...
                        'frame', ...
                        'ctrsX', ...
                        'ctrsY', ...
                        'signal', ...
                        'noise', ...
                        'offset'};
                    %load data from disk
                    for varIdx = 1:7
                        if exist([filepath filename(1:end-3) varNames{varIdx}],'file') == 2
                            fid = fopen([filepath filename(1:end-3) varNames{varIdx}], 'r');
                            varImport = fread(fid,inf,'real*8');
                            fclose(fid);
                            
                            switch varNames{varIdx}
                                case 'frame'
                                    data.Time = varImport;
                                case 'ctrsX'
                                    data.Position_X = varImport+1;
                                case 'ctrsY'
                                    data.Position_Y = varImport+1;
                                case 'signal'
                                    data.Signalpower = (varImport*sqrt(pi).*data.PSFradius).^2;
                                case 'noise'
                                    data.Noisepower = varImport.^2;
                                case 'offset'
                                    data.Background = varImport;
                                case 'radius'
                                    data.PSFradius = varImport;
                            end %switch
                        else
                            answer = questdlg(sprintf('%s not found',[filepath filename(1:end-3) varNames{varIdx}]),'ERROR',...
                                'Set new Filename','Abort','Set new Filename');
                            switch answer
                                case 'Set new Filename'
                                    [filenameCorrect, filepathCorrect,isOK] = uigetfile({...
                                        ['*.' varNames{varIdx}], sprintf('Binary Data File (.%s)',varNames{varIdx})},...
                                        'Select File', getappdata(0,'searchPath'));
                                    if isOK
                                        setappdata(0,'searchPath',filepathCorrect)
                                        
                                        fid = fopen([filepathCorrect filenameCorrect], 'r');
                                        varImport = fread(fid,inf,'real*8');
                                        fclose(fid);
                                        
                                        switch varNames{varIdx}
                                            case 'frame'
                                                data.Time = varImport;
                                            case 'ctrsX'
                                                data.Position_X = varImport;
                                            case 'ctrsY'
                                                data.Position_Y = varImport;
                                            case 'signal'
                                                data.Signalpower = (varImport*sqrt(pi).*data.PSFradius).^2;
                                            case 'noise'
                                                data.Noisepower = varImport;
                                            case 'offset'
                                                data.Background = varImport;
                                            case 'radius'
                                                data.PSFradius = varImport;
                                        end %switch
                                    else
                                        return
                                    end %if
                                case 'Abort'
                                    isOK = 0;
                                    return
                            end %switch
                        end %if
                        
                        update_progressbar(hProgressbar,{0.5+0.4*varIdx/7})
                    end %for
                    data.Particle_ID = reshape(1:objLoc.NumParticles,[],1)*datenum(clock);
                    data.Particle_ID_Hex = num2hex(data.Particle_ID);
                    data.Photons = sqrt(data.Signalpower).*...
                        data.PSFradius*2*sqrt(pi)*objLoc.Count2photon;
                    data.Precision = model_localization_precision(data.PSFradius, objLoc.Px2nm, ...
                        data.Photons, (sqrt(data.Noisepower)-sqrt(data.Photons))*objLoc.Count2photon); %(RMSE in Position Estimate)
                    data.SNR = 10*log10(data.Signalpower./data.Noisepower);
                    [~,dNN] = knnsearch([data.Position_X data.Position_Y],...
                        [data.Position_X data.Position_Y],'K',2);
                    data.NN = dNN(:,2)*objLoc.Px2nm/1000;
                    
                    objLoc.Data = data;
                    isOK = show_frame(objLoc,1);
                    
                    update_progressbar(hProgressbar,{1})
                    
                    add_data_to_project(objProject,objLoc)
                case 'Tracking'
                    objTraj = ClassTrajectory;
                    set_parent(objTraj,objProject)
                    objTraj.DetectionMap = 0;
                    objTraj.FieldOfView = objRaw.FieldOfView;
                    objTraj.Dim = 2;
                    
                    objTraj.objImageFile = copy(objRaw.objImageFile);
                    set_parent(objTraj.objImageFile,objTraj)
                    objTraj.objUnitConvFac = copy(objRaw.objUnitConvFac);
                    set_parent(objTraj.objUnitConvFac,objTraj)
                    objTraj.objLocSettings = copy(objRaw.objLocSettings);
                    set_parent(objTraj.objLocSettings,objTraj)
                    
                    objTraj.objTrackSettings = ManagerTrackSettings(objTraj);
                    objTraj.objContrastSettings = ManagerContrastSettings(objTraj);
                    objTraj.objDisplaySettings = ManagerDisplaySettings(objTraj);
                    objTraj.objJumpSeries = ManagerJumpSeries(objTraj);
                    objTraj.objDiffCoeffFit = ManagerMsdCurveFit(objTraj);
                    
                    objTraj.objColormap = ManagerColormap(objTraj);
                    objTraj.objGrid = ManagerGrid(objTraj);
                    objTraj.objRoi = ManagerRoi(objTraj);
                    objTraj.objScalebar = ManagerScalebar(objTraj);
                    objTraj.objTimestamp = ManagerTimestamp(objTraj);
                    objTraj.objTextstamp = ManagerTextstamp(objTraj);
                    
                    %generate black background
                    objTraj.RawImagedata = zeros(objTraj.FieldOfView(6),...
                        objTraj.FieldOfView(5));
                    objTraj.Imagedata = objTraj.RawImagedata;
                    
                    update_progressbar(hProgressbar,{0.5})
                    
                    %convert to trajectory cell structure
                    [numObs, ~] = cellfun(@size,import.data.tr,'Un',0);
                    import.data.tr(cell2mat(numObs)==1) = [];
                    objTraj.NumIndividual = numel(import.data.tr);
                    for trajIdx = 1:objTraj.NumIndividual
                        particleID = reshape(1:size(import.data.tr{trajIdx},1),[],1)*datenum(clock);
                        listLocalizedTrack = struct(...
                            'Particle_ID', particleID,...
                            'Particle_ID_Hex', num2hex(particleID),...
                            'Time', import.data.tr{trajIdx}(:,3),...
                            'Position_X', import.data.tr{trajIdx}(:,1)+1,...
                            'Position_Y', import.data.tr{trajIdx}(:,2)+1,...
                            'Signalpower', import.data.tr{trajIdx}(:,5).^2,...
                            'Background', zeros(size(import.data.tr{trajIdx},1),1),...
                            'Noisepower', import.data.tr{trajIdx}(:,6),...
                            'PSFradius', ones(size(import.data.tr{trajIdx},1),1)*...
                            import.settings.TrackingOptions.GaussianRadius);
                        
                        listLocalizedTrack.Photons = sqrt(listLocalizedTrack.Signalpower).*...
                            listLocalizedTrack.PSFradius*2*sqrt(pi)*objTraj.Count2photon;
                        listLocalizedTrack.Precision = model_localization_precision(listLocalizedTrack.PSFradius, objTraj.Px2nm, ...
                            listLocalizedTrack.Photons, (sqrt(listLocalizedTrack.Noisepower)-sqrt(listLocalizedTrack.Photons))*objTraj.Count2photon); %(RMSE in Position Estimate)
                        listLocalizedTrack.SNR = 10*log10(listLocalizedTrack.Signalpower./listLocalizedTrack.Noisepower);
                        
                        objTraj.objIndividual(trajIdx) = ClassSingleTrajectory(...
                            objTraj,listLocalizedTrack);
                        
                        update_progressbar(hProgressbar,{0.5+0.5*trajIdx/objTraj.NumIndividual})
                    end %for
                    
                    add_data_to_project(objProject,objTraj)
            end %switch
            close_progressbar(hProgressbar)
            waitfor(msgbox('Project Import Done','modal'))
        end %fun
        function import_localization_from_ascii(this)
            [filename, filepath,isOK] = uigetfile({...
                '*.tif;*.btf', 'Supported Imageformats TIFF or BigTIFF (.tif, .btf)'},...
                'Select Imagestack', getappdata(0,'searchPath'));
            if isOK
                setappdata(0,'searchPath',filepath)
            else
                return
            end %if
            
            objProject = ClassProject(this.Parent,'Imported Project');

            %generate raw object
            objRaw = ClassRaw(objProject);
            %import conversion factors
            objRaw.objUnitConvFac = ManagerUnitConvFac(objRaw);
            set_parameter(objRaw.objUnitConvFac)
            waitfor(objRaw.objUnitConvFac.hFig)
            
            objRaw.Channel = 1;
            objChannelConfig = ChannelConfig;
            objRaw.objImageFile = ManagerImageFile(objRaw,...
                {[filepath filename]},objChannelConfig,[]);
            
            objRaw.objContrastSettings = ManagerContrastSettings(objRaw);
            objRaw.objLocSettings = ManagerLocSettings(objRaw);
            set_parameter(objRaw.objLocSettings)
            waitfor(objRaw.objLocSettings.hFig)
            
            objRaw.objColormap = ManagerColormap(objRaw);
            objRaw.objGrid = ManagerGrid(objRaw);
            objRaw.objRoi = ManagerRoi(objRaw);
            objRaw.objScalebar = ManagerScalebar(objRaw);
            objRaw.objTimestamp = ManagerTimestamp(objRaw);
            objRaw.objTextstamp = ManagerTextstamp(objRaw);
            
            objRaw.objDisplaySettings = ManagerDisplaySettings(objRaw);
            
            objRaw.FieldOfView = ...
                [0.5 0.5 ...
                objRaw.objImageFile.ChannelWidth+0.5 ...
                objRaw.objImageFile.ChannelHeight+0.5 ...
                objRaw.objImageFile.ChannelWidth ...
                objRaw.objImageFile.ChannelHeight];
            
            isOK = show_frame(objRaw,1);
            add_data_to_project(objProject,objRaw)
            
            objLoc = ClassLocalization(objProject);
            objLoc.Dim = 2;
            
            objLoc.objImageFile = copy(objRaw.objImageFile);
            set_parent(objLoc.objImageFile,objLoc)
            objLoc.objUnitConvFac = copy(objRaw.objUnitConvFac);
            set_parent(objLoc.objUnitConvFac,objLoc)
            objLoc.objLocSettings = copy(objRaw.objLocSettings);
            set_parent(objLoc.objLocSettings,objLoc)
            
            objLoc.objContrastSettings = ManagerContrastSettings(objLoc);
            objLoc.objDisplaySettings = ManagerDisplaySettings(objLoc);
            objLoc.objTrackSettings = ManagerTrackSettings(objLoc);
            objLoc.objClusterSettings = ManagerClusterSettings(objLoc);
            
            objLoc.objColormap = ManagerColormap(objLoc);
            objLoc.objGrid = ManagerGrid(objLoc);
            objLoc.objRoi = ManagerRoi(objLoc);
            objLoc.objScalebar = ManagerScalebar(objLoc);
            objLoc.objTimestamp = ManagerTimestamp(objLoc);
            objLoc.objTextstamp = ManagerTextstamp(objLoc);
            
            objLoc.objDisplaySettings = ManagerDisplaySettings(objLoc);
            
            objLoc.NumParticles = 463687;
            objLoc.DetectionMap = 0;
            objLoc.FieldOfView = objRaw.FieldOfView;
            
            import = csvread('C:\Users\Chris\Desktop\Hamamatsu WTM\point_list.txt');
            
            data.Time = import(:,5);
            data.Position_X = import(:,2);
            data.Position_Y = import(:,3);
            data.Signalpower = (import(:,4)*22815.5).^2;
            data.Noisepower = nan(objLoc.NumParticles,1);
            data.Background = nan(objLoc.NumParticles,1);
            data.PSFradius = ones(objLoc.NumParticles,1)*1.15;
            
            data.Particle_ID = reshape(1:objLoc.NumParticles,[],1)*datenum(clock);
            data.Particle_ID_Hex = num2hex(data.Particle_ID);
            data.Photons = sqrt(data.Signalpower).*...
                data.PSFradius*2*sqrt(pi)*objLoc.Count2photon;
            data.Precision = model_localization_precision(data.PSFradius, objLoc.Px2nm, ...
                data.Photons, (sqrt(data.Noisepower)-sqrt(data.Photons))*objLoc.Count2photon); %(RMSE in Position Estimate)
            data.SNR = 10*log10(data.Signalpower./data.Noisepower);
            [~,dNN] = knnsearch([data.Position_X data.Position_Y],...
                [data.Position_X data.Position_Y],'K',2);
            data.NN = dNN(:,2)*objLoc.Px2nm/1000;
            
            objLoc.Data = data;
            isOK = show_frame(objLoc,1);
            
            add_data_to_project(objProject,objLoc)
        end %fun
    end %methods
end %classdef