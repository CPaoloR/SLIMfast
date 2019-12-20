classdef ClassLocalization < SuperclassData
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Data
        NumParticles
        DetectionMap
    end %properties
    properties (Hidden, Dependent)
        IsInsideRoi
    end %properties
    properties (Hidden, Transient)
        hInfoFig
        
        hLabel
        hDiffRadii
        
        Header = struct(...
            'Particle_ID', 'Unique Emitter Identifier',...
            'Particle_ID_Hex', 'Unique Emitter Identifier Hexadecimal',...
            'Time', 'Time of Emitter Localization [frame]',...
            'Position_X', 'X-Coordinate of Emitter Center [px]',...
            'Position_Y', 'Y-Coordinate of Emitter Center [px]',...
            'Position_Z', 'Z-Coordinate of Emitter Center [px]',...
            'Signalpower', 'Emitters'' Signalpower [counts^2]',...
            'Background', 'Average Backgroundlevel around Emitter [counts]',...
            'Noisepower', 'Emitters'' Noisepower [counts^2]',...
            'Photons', 'Emitters'' Signal [photons]',...
            'PSFradius', 'Std of Emitters'' PSF [px]',...
            'Precision', 'Emitter Localization Precision [nm]',...
            'SNR', 'Emitters'' Signal to Noise Ratio [db]',...
            'NN', 'Emitter Distance to next nearest Emitter [µm]',...
            'PSFradius_Y', 'X-Std of Emitters'' PSF [px]',...
            'PSFradius_X', 'Y-Std of Emitters'' PSF [px]',...
            'PSFcov', 'Cov of Emitters'' PSF [px^2]');
        
        %% Tooltips
        ToolTips = struct(...
            'Toolbar', struct(...
            'SaveImage', sprintf('Save Image as TIFF'),...
            'SaveMovie', sprintf('Save Image Sequence as AVI'),...
            'SaveData', sprintf('Save Data as ASCII'),...
            'DisplayManager', sprintf('Adjust Image Display Settings'),...
            'CloneData', sprintf('Duplicate actual Data'),...
            'IntDist', sprintf('Show Emitter Intensity Distribution'),...
            'S2NDist', sprintf('Show Signal to Noise Distribution'),...
            'LocPrecDist', sprintf('Show Localization Precision Distribution'),...
            'SigSizeDist', sprintf('Show Signal Size Distribution'),...
            'NNDist', sprintf('Show Nearest Neighbor Distribution'),...
            'LocDensDist', sprintf('Show Localization Density Distribution'),...
            'ClusterManager', sprintf('Find Cluster within Data (DBSCAN)'),...
            'TrackManager', sprintf('Track Single Emitter'),...
            'RoiManager', sprintf('Create/Load Region of Interest')))
    end %properties
    
    methods
        %% constructors
        function this = ClassLocalization
            %initialize parental class
            this = this@SuperclassData;
        end %fun
        
        function show_data_information(this)
            %check if info already open
            if ishandle(this.hInfoFig)
                waitfor(msgbox('INFORMATION TABLE already open','INFO','help','modal'))
                figure(this.hInfoFig)
                return
            end %if
            
            y0 = 100;
            
            scrSize = get(0, 'ScreenSize');
            this.hInfoFig = ...
                figure(...
                'Units','pixels',...
                'Position', ...
                [0.5*(scrSize(3)-100) 0.5*(scrSize(4)-y0) 100 y0],...
                'Name', 'INFORMATION TABLE',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'DockControls', 'off',...
                'Color', this.FamilyColor,...
                'IntegerHandle','off',...
                'Resize','off',...
                'Visible','off');
            
            hTable = ...
                uitable(...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'ColumnName', {'Parameter','Value'},...
                'ColumnFormat', {'char','char'},...
                'ColumnEditable', [false false],...
                'ColumnWidth',{400 150},...
                'RowName',[],...
                'RowStriping','on',...
                'FontSize', 18);
            
            paramName = [...
                {'Total # Localizations'},...
                {'Localization Range'},...
                {'Int. Thresh [counts]'},...
                {'Error Probability [10^]'},...
                {'Evaluation Box [px]'},...
                {'# Deflation Loops'},...
                {'PSF Model'},...
                {'PSF Radius [px]'},...
                {'Radius Mode'}];
            paramValue = [...
                cellstr(num2str(this.NumParticles)),...
                cellstr([num2str(this.objLocSettings.LocStart) ...
                '-' num2str(this.objLocSettings.LocEnd)]),...
                cellstr(num2str(this.objLocSettings.MinInt)),...
                cellstr(num2str(this.objLocSettings.ErrRate)),...
                cellstr([num2str(this.objLocSettings.WinX) ...
                'x' num2str(this.objLocSettings.WinY)]),...
                cellstr(num2str(this.objLocSettings.NumDeflat)),...
                cellstr(num2str(this.objLocSettings.LocModel)),...
                cellstr(num2str(this.objLocSettings.RadiusPSF)),...
                cellstr(num2str(this.objLocSettings.TypePSF))];
            data = [paramName; paramValue];
            set(hTable,'Data',data')
            
            set(hTable,'Units','pixels')
            tablePos = get(hTable,'Extent')+[0 0 0 20];
            figPos = [0.5*(scrSize(3)-tablePos(3)) ...
                0.5*(scrSize(4)-tablePos(4)) ...
                tablePos(3) tablePos(4)];
            tablePos = [0 0 figPos(3:4)];
            if tablePos(3) > scrSize(3)
                figPos(1) = 50;
                figPos(3) = scrSize(3)-100;
                tablePos(3) = figPos(3);
            end %if
            if tablePos(4) > scrSize(4)
                figPos(2) = 50;
                tablePos(3) = figPos(3)+10;
                
                figPos(4) = scrSize(4)-100;
                tablePos(4) = figPos(4);
            end %if
            setpixelposition(this.hInfoFig,figPos)
            setpixelposition(hTable,tablePos,1)
            set(hTable,'Units','normalized')
            set(this.hInfoFig,'Visible','on')
        end %fun
        
        %%
        function display_frame(this)
            %image post processing
            imageData = this.RawImagedata;
            
            %check if image filter is selected
            if this.objDisplaySettings.UseFilter
                switch this.objDisplaySettings.FilterModel
                    case 'Hypothesis Map'
                        T = this.objDisplaySettings.FilterSettings(1)*...
                            this.objDisplaySettings.FilterSettings(1) ;
                        
                        %% Hypothese H0
                        %% pas de particule dans la fenetre
                        m = ones(this.objDisplaySettings.FilterSettings(1),...
                            this.objDisplaySettings.FilterSettings(1)) ;
                        
                        hm = zeros(this.objImageFile.ChannelHeight*this.ActExp,...
                            this.objImageFile.ChannelWidth*this.ActExp) ;
                        nc = floor(this.objImageFile.ChannelHeight*this.ActExp/2 - ...
                            this.objDisplaySettings.FilterSettings(1)/2) ;
                        mc = floor(this.objImageFile.ChannelWidth*this.ActExp/2 - ...
                            this.objDisplaySettings.FilterSettings(1)/2) ;
                        hm((nc+1):(nc+this.objDisplaySettings.FilterSettings(1)) ,...
                            (mc+1):(mc+this.objDisplaySettings.FilterSettings(1))) = m ;
                        
                        tfhm = fft2(hm) ;
                        tfim = fft2(imageData) ;
                        m0 = real(fftshift(ifft2(tfhm .* tfim))) /T ;
                        
                        im2 = imageData .* imageData ;
                        tfim2 = fft2(im2) ;
                        Sim2 = real(fftshift(ifft2(tfhm .* tfim2)));
                        
                        %% H0 = T/2*log(2*pi*sig0^2)-T/2 ;
                        T_sig0_2 = Sim2 - T*m0.^2 ;
                        
                        %% Hypothèse H1
                        %% une particule est au centre de la fenetre
                        %% amplitude inconnue, rayon fixe
                        
                        i = 0.5 + (0:(this.objDisplaySettings.FilterSettings(1)-1)) - ...
                            this.objDisplaySettings.FilterSettings(1)/2 ;
                        j = 0.5 + (0:(this.objDisplaySettings.FilterSettings(1)-1)) - ...
                            this.objDisplaySettings.FilterSettings(1)/2 ;
                        ii = i' * ones(1,this.objDisplaySettings.FilterSettings(1)) ;
                        jj = ones(this.objDisplaySettings.FilterSettings(1),1) * j ;
                        
                        %%% puissance unitaire
                        g = (1/(sqrt(pi)*this.objDisplaySettings.FilterSettings(2)))*...
                            exp(-(1/(2*this.objDisplaySettings.FilterSettings(2)^2))*(ii.*ii + jj.*jj)) ;
                        gc = g - sum(g(:))/T ;
                        Sgc2 = sum(gc(:).^2) ;
                        
                        hm((nc+1):(nc+this.objDisplaySettings.FilterSettings(1)) ,...
                            (mc+1):(mc+this.objDisplaySettings.FilterSettings(1))) = gc ;
                        
                        tfhgc = fft2(hm) ;
                        
                        alpha = real(fftshift(ifft2(tfhgc .* tfim))) / Sgc2 ;
                        
                        test = 1 - (Sgc2 * alpha.^2) ./ T_sig0_2 ;
                        test = (test > 0) .* test + (test <= 0) ;
                        loglikeMap = - T * log(test) ;
                        loglikeMap(isnan(loglikeMap)) = 0;
                        imageData = circshift(loglikeMap,[1 1]);
                    case 'Difference of Gaussian'
                        %apply DoG-Filter
                        imageData = imfilter(imageData,...
                            fspecial('gaussian', this.objDisplaySettings.FilterSettings(1), ...
                            this.objDisplaySettings.FilterSettings(2))-...
                            fspecial('gaussian', this.objDisplaySettings.FilterSettings(1), ...
                            this.objDisplaySettings.FilterSettings(3)));
                    case 'Wiener Adaptive Noise'
                        imageData = wiener2(imageData, ...
                            [this.objDisplaySettings.FilterSettings(1) ...
                            this.objDisplaySettings.FilterSettings(1)]);
                    case 'Blind Deconvolution'
                        imageData = deconvblind(imageData, ...
                            fspecial('gaussian',(this.objDisplaySettings.FilterSettings(1)), ...
                            this.objDisplaySettings.FilterSettings(2)),...
                            this.objDisplaySettings.FilterSettings(3));
                end %switch
            end %if
            
            %calculate pixel region for superresolution image
            imageData = crop_image(imageData,this.FieldOfView(1:4),this.ActExp);
            
            %check for roi
            if this.objRoi.HasRoi
                if this.objRoi.FocusRoi
                    maskData = crop_image(this.Maskdata,this.FieldOfView(1:4),this.ActExp);
                    imageData = imageData.*maskData;
                end %if
            end %if
            
            update_intensity_data(this.objContrastSettings,imageData);
            if ishandle(this.objContrastSettings.hFig)
                plot_intensity_data(this.objContrastSettings)
            end %if
            
            %save postprocessed image
            this.Imagedata = imageData;
            
            display_frame@SuperclassData(this)
            
            if ishandle(this.objLineProfile.hFig)
                update_profile_plot(this.objLineProfile)
            end %if
        end %fun
        function initialize_image_visualization(this)
            initialize_image_visualization@SuperclassData(this)
            set(this.hImageFig,'Visible','on')
            
            t(:,1) = this.objLocSettings.LocStart:this.objLocSettings.LocEnd;
            if numel(t) == 1
                cnt = numel(this.Data.Time);
            else
                cnt(:,1) =  hist(this.Data.Time,t);
            end %if
            this.ExportBin = struct(...
                'Header', catstruct(this.Header, struct(...
                'Number_Localizations_over_Time','Number of localized Emitters over Time (Time [s] | # Emitter [count])')),...
                'Data',catstruct(this.Data, struct(...
                'Number_Localizations_over_Time',[t*this.Frame2msec/1000 cnt])));
        end %fun
        function construct_image_toolbar(this)
            hToolbar = uitoolbar('Parent',this.hImageFig);
            icon = getappdata(0,'icon');
            hFileInfo = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('File_Information'),...
                'ClickedCallback', @(src,evnt)show_data_information(this));
            hCloneData = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Generate_Subset'),...
                'TooltipString', this.ToolTips.Toolbar.CloneData,...
                'ClickedCallback', @(src,evnt)generate_filtered_data_set(this));
            hDispMan = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Visualization_2D'),...
                'TooltipString', this.ToolTips.Toolbar.DisplayManager,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)set_parameter(this.objDisplaySettings));
            hSaveImage = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Save_Image'),...
                'Separator','on',...
                'TooltipString', this.ToolTips.Toolbar.SaveImage,...
                'ClickedCallback', @(src,evnt)save_image(this));
            hSaveMovie = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Save_Movie'),...
                'TooltipString', this.ToolTips.Toolbar.SaveMovie,...
                'ClickedCallback', @(src,evnt)save_movie(this));
            hSaveData = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Save_Data'),...
                'TooltipString', this.ToolTips.Toolbar.SaveData,...
                'ClickedCallback', @(src,evnt)write_variable_to_ascii(this));
            hIntDist = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Signal_Intensity_Distribution'),...
                'TooltipString', this.ToolTips.Toolbar.IntDist,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,...
                'Signal Intensity Distribution',this));
            hS2NDist = ...
                uipushtool(...
                'Parent',hToolbar,...
                'Tag', 'Signal to Noise Distribution',...
                'CData', icon.('Signal_to_Noise_Distribution'),...
                'TooltipString', this.ToolTips.Toolbar.S2NDist,...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,...
                'Signal to Noise Distribution',this));
            hLocPrecDist = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Localization_Precision_Distribution'),...
                'TooltipString', this.ToolTips.Toolbar.LocPrecDist,...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,...
                'Localization Precision Distribution',this));
            hSigSizeDist = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Signal_Size_Distribution'),...
                'TooltipString', this.ToolTips.Toolbar.SigSizeDist,...
                'ClickedCallback', @(src,evnt)ClassHistogram(this,...
                'Signal Size Distribution',this));
            hNNDist = [];
            %             hNNDist = ...
            %                 uipushtool(...
            %                 'Parent',hToolbar,...
            %                 'CData', icon.('Nearest_Neighbor_Distance_Distribution'),...
            %                 'TooltipString', this.ToolTips.Toolbar.NNDist,...
            %                 'ClickedCallback', @(src,evnt)ClassHistogram(this,...
            %                 'Nearest Neighbor Distance Distribution',this));
            hLocDensDist = [];
            %           hLocDensDist = ...
            %                 uipushtool(...
            %                 'Parent',hToolbar,...
            %                 'CData', icon.('Localization_Density_Distribution'),...
            %                 'TooltipString', this.ToolTips.Toolbar.LocDensDist,...
            %                 'ClickedCallback', @(src,evnt)ClassHistogram(this,...
            %                 'Localization Density Distribution',this));
            hClusterMan = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Cluster'),...
                'TooltipString', this.ToolTips.Toolbar.ClusterManager,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)set_parameter(this.objClusterSettings));
            hTrackMan = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('Track'),...
                'TooltipString', this.ToolTips.Toolbar.TrackManager,...
                'ClickedCallback', @(src,evnt)set_parameter(this.objTrackSettings));
            hRoiMan = ...
                uipushtool(...
                'Parent',hToolbar,...
                'CData', icon.('ROI'),...
                'TooltipString', this.ToolTips.Toolbar.RoiManager,...
                'Separator','on',...
                'ClickedCallback', @(src,evnt)set_parameter(this.objRoi),...
                'Enable','on');
            hLineProf = ...
                uipushtool(...
                'Parent', hToolbar,...
                'CData', icon.('LineProfile'),...
                'ClickedCallback', @(src,evnt)set_parameter(this.objLineProfile));
            
            this.hImageToolbar = struct(...
                'Toolbar', hToolbar,...
                'FileInfo', hFileInfo,...
                'SaveImage', hSaveImage,...
                'SaveMovie', hSaveMovie,...
                'SaveData', hSaveData,...
                'DisplayManager', hDispMan,...
                'CloneData', hCloneData,...
                'IntDist', hIntDist,...
                'S2NDist', hS2NDist,...
                'LocPrecDist', hLocPrecDist,...
                'SigSizeDist', hSigSizeDist,...
                'NNDist', hNNDist,...
                'LocDensDist', hLocDensDist,...
                'ClusterManager', hClusterMan,...
                'TrackManager', hTrackMan,...
                'RoiManager', hRoiMan,...
                'LineProfile', hLineProf);
        end %fun
        
        function isOK = get_frame(this,imageFrames,mode)
            if strcmp(mode,'Cumulative')
                good = ismembc(this.Data.Time,imageFrames);
                [finalFrameImg,isOK] = calculate_frame(this,good);
                if ~isOK
                    return
                end %if
            else
                good = (this.Data.Time == imageFrames(1));
                [finalFrameImg,isOK] = calculate_frame(this,good);
                if ~isOK
                    return
                end %if
                numFrames = numel(imageFrames);
                if numFrames > 1
                    for idx = 2:numFrames
                        good = (this.Data.Time == imageFrames(idx));
                        [frameImg, isOK] = calculate_frame(this,good);
                        if ~isOK
                            return
                        end %if
                        switch mode
                            case 'Minimum'
                                finalFrameImg = min(...
                                    finalFrameImg, frameImg);
                            case 'Maximum'
                                finalFrameImg = max(...
                                    finalFrameImg, frameImg);
                            case 'Average'
                                delta = frameImg - finalFrameImg;
                                finalFrameImg = finalFrameImg + delta/idx;
                            case 'Variance'
                                if idx == 2
                                    sumSquaredDiff = zeros(size(frameOut));
                                    
                                    delta = frameImg - finalFrameImg;
                                    average = finalFrameImg + delta/idx;
                                else
                                    delta = frameImg - average;
                                    average = average + delta/idx;
                                end %if
                                
                                sumSquaredDiff = sumSquaredDiff +...
                                    delta.*(frameImg - average);
                                finalFrameImg = sumSquaredDiff/idx;
                        end %switch
                    end %for
                end %if
            end %if
            
            this.RawImagedata = finalFrameImg;
        end %fun
        function [frameOut, isOK] = calculate_frame(this,good)
            isOK = 1;
            
            dx = transform_mag_to_orig(...
                0.5:this.objImageFile.ChannelWidth*this.ActExp+0.5,this.ActExp,0.5);
            dy = transform_mag_to_orig(...
                0.5:this.objImageFile.ChannelHeight*this.ActExp+0.5,this.ActExp,0.5);
            switch this.objDisplaySettings.KernelModel
                case 'Loc. Precision'
                    blockSize = 1e5;
                    %preallocate
                    pxIdxList = zeros(blockSize,2,'uint16');
                    signal = zeros(blockSize,1);
                    
                    actExp = this.ActExp;
                    srWidth = this.objImageFile.ChannelWidth*actExp;
                    srHeight = this.objImageFile.ChannelHeight*actExp;
                    frameOut = zeros(srHeight,srWidth);
                    
                    %spatial pixel sampling
                    dPx = 1/actExp;
                    
                    %get emitters central image target pixel
                    [~, pxCtrX] = histc(this.Data.Position_X(good), dx);
                    [~, pxCtrY] = histc(this.Data.Position_Y(good), dy);
                    
                    %calculate std for gaussian emitter blur
                    locPrecPx = this.Data.Precision(good)/this.Px2nm;
                    pxRange = ceil((3*actExp)*locPrecPx); % >99% of signal
                    critNumPx = 15^2;
                    if any(pxRange > critNumPx)
                        %to avoid full memory break down
                        pxRange(pxRange > critNumPx) = critNumPx;
                        sprintf(['Computation of Gaussian Particle is limited to 15px^2\n' ...
                            'Excessive Radii set to 15px^2!'])
                    end %if
                    
                    %sub-pixel location of respective emitter
                    remainder = ...
                        [this.Data.Position_X(good)-dx(pxCtrX)' ...
                        this.Data.Position_Y(good)-dy(pxCtrY)']-dPx/2; %changed 2011/05/09
                    
                    %number of pixels to be processed by accumarray
                    cnt = 0;
                    for p = 1:sum(good)
                        %expected pixelnumber of this emitter
                        expDataCnt = (2*pxRange(p)+1)^2;
                        if cnt+expDataCnt > blockSize
                            %process data blocks to avoid memory break down (5e7 ~ 3-4GB RAM)
                            frameOut = frameOut + accumarray(pxIdxList(1:cnt,:),...
                                signal(1:cnt),[srHeight srWidth],[],0);
                            
                            %reset count
                            cnt = 0;
                            pxIdxList = zeros(blockSize,2,'uint16');
                            signal = zeros(blockSize,1);
                        end %if
                        
                        %generate emitter mask
                        yPos = ones(2*pxRange(p)+1,1)*(-pxRange(p):pxRange(p));
                        xPos = yPos';
                        %indices to image pixels
                        pxIdx = uint16([yPos(:)+pxCtrY(p) xPos(:)+pxCtrX(p)]);
                        
                        %check if pixels are inside image region
                        good = pxIdx(:,1) > 0 & pxIdx(:,1) < srHeight+1 & ...
                            pxIdx(:,2) > 0 & pxIdx(:,2) < srWidth+1;
                        dataCnt = sum(good);
                        
                        %add pixel indices to the list
                        pxIdxList(cnt+1:cnt+dataCnt,:) = pxIdx(good,:);
                        
                        %calculate respective pixel signal from 2d-Gaussian PDF
                        X0 = bsxfun(@minus,dPx*[xPos(:) yPos(:)],remainder(p,:));
                        signal(cnt+1:cnt+dataCnt) = exp(-0.5*sum((X0(good,:)/locPrecPx(p)).^2, 2) - ...
                            sum(log([locPrecPx(p) locPrecPx(p)])) - log(2*pi));
                        
                        cnt = cnt + dataCnt;
                    end %for
                    
                    frameOut = frameOut + accumarray(pxIdxList(1:cnt,:),...
                        signal(1:cnt),[srHeight srWidth],[],0);
                case 'Fixed Radius'
                    %construct 2d-map of emitter positions. Positions
                    %Accuracy is limited to spatial Sampling (1/ActExp)
                    frameOut = hist3([this.Data.Position_Y(good) ...
                        this.Data.Position_X(good)],...
                        'edges',{dy; dx});
                    %remove last row & column (hist3 edge artefact)
                    frameOut = frameOut(1:end-1,1:end-1);
                    
                    if this.objDisplaySettings.RadWeight > 0
                        %generate gaussian KernelModel for emitter blurring
                        r = this.objDisplaySettings.RadWeight;
                        psf = fspecial('gaussian', ceil(6*r+1), r);
                        %convolution of emitter position with gaussian KernelModel
                        frameOut = imfilter(frameOut, psf);
                    end %if
            end %switch
        end %fun
        
        %%
        function objClone = generate_filtered_data_set(this)
            %apply time filter and spatial mask
            good = this.IsInsideRoi;
            
            objClone = generate_new_data_set(this,good);
        end %fun
        function objClone = generate_new_data_set(this,good)
            %initialize cloned localization object
            objClone = clone_object(this,this.Parent);
            %reset roi list
            objClone.objRoi.SrcContainer.RoiList = [];
            
            mask = this.Maskdata;
            this.DetectionMap = ...
                imresize(this.DetectionMap,size(mask),...
                'Method','Nearest') & mask;
            
            if this.objRoi.CropRoi
                objClone.FieldOfView = this.MaskRect;
            else
                objClone.FieldOfView = [0.5 0.5 ...
                    this.objImageFile.ChannelWidth+0.5 ...
                    this.objImageFile.ChannelHeight+0.5 ...
                    this.objImageFile.ChannelWidth ...
                    this.objImageFile.ChannelHeight];
            end %if
            
            objClone.NumParticles = sum(good);
            objClone.Data = ...
                structfun(@(x)x(good),this.Data,'Un',0);
            [~,dNN] = knnsearch(...
                [objClone.Data.Position_X objClone.Data.Position_Y],...
                [objClone.Data.Position_X objClone.Data.Position_Y],'K',2);
            if isempty(dNN)
                objClone.Data.NN = [];
            else
                objClone.Data.NN = dNN(:,2)*this.Px2nm/1000;
            end %if
            
            %update image data
            show_frame(objClone,objClone.Frame);
            
            %check if actual data object is visualized
            if ishandle(this.hImageFig)
                initialize_visualization(objClone)
            end %if
            
            %update project explorer
            add_data_to_project(...
                get_parental_object(this,'ClassProject'),objClone)
        end %fun
        
        %%
        function test_tracking_settings(~)
        end %fun
        function objTraj = reconstruct_trajectories(this)
            %close tracking manager
            if ishandle(this.objTrackSettings.hFig)
                delete(this.objTrackSettings.hFig)
            end %if
            
            if eq(this.TrackStart,this.TrackEnd)
                waitfor(errordlg('Tracking not possible for < 2 frames','','modal'))
                return
            end %if
            
            %convert matrix data to structure format used by u-track
            movieInfo(this.TrackEnd-this.TrackStart+1,1) = ...
                struct('xCoord',[],'yCoord',[],'amp',[]);
            for frame = this.TrackStart:this.TrackEnd
                good = this.Data.Time == frame;
                movieInfo(frame) = ...
                    struct(...
                    'xCoord', [this.Data.Position_X(good) this.Data.Precision(good)/this.Px2nm],...
                    'yCoord', [this.Data.Position_Y(good)  this.Data.Precision(good)/this.Px2nm],...
                    'amp', [this.Data.Photons(good)  zeros(sum(good),1)]);
            end %for
            
            %% Cost functions
            
            %Frame-to-frame linking
            costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
            %Gap closing, merging and splitting
            costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
            %% Kalman filter functions
            %Memory reservation
            kalmanFunctions.reserveMem = 'kalmanResMemLM';
            %Filter initialization
            kalmanFunctions.initialize = 'kalmanInitLinearMotion';
            %Gain calculation based on linking history
            kalmanFunctions.calcGain = 'kalmanGainLinearMotion';
            %Time reversal for second and third rounds of linking
            kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';
            
            %% General tracking parameters
            dim = this.objTrackSettings.Dim+1;
            
            %% Cost function specific parameters: Frame-to-frame linking
            
            %Flag for linear motion
            parameters.linearMotion = this.objTrackSettings.UseLinModel;
            %Search radius lower limit
            parameters.minSearchRadius = this.objTrackSettings.InitMinSearchRad;
            %Search radius upper limit
            parameters.maxSearchRadius = this.objTrackSettings.InitMaxSearchRad;
            %Standard deviation multiplication factor
            parameters.brownStdMult = this.objTrackSettings.InitSearchExpFac;
            %Flag for using local density in search radius estimation
            parameters.useLocalDensity = this.objTrackSettings.InitUseLocDens;
            %Number of past frames used in nearest neighbor calculation
            parameters.nnWindow = this.objTrackSettings.LocDensWin;
            %Optional input for diagnostics: To plot the histogram of linking distances
            %up to certain frames. For example, if parameters.diagnostics = [2 35],
            %then the histogram of linking distance between frames 1 and 2 will be
            %plotted, as well as the overall histogram of linking distance for frames
            %1->2, 2->3, ..., 34->35. The histogram can be plotted at any frame except
            %for the first and last frame of a movie.
            %To not plot, enter 0 or empty
            parameters.diagnostics = 0;
            %Store parameters for function call
            costMatrices(1).parameters = parameters;
            
            %% Cost function specific parameters: Gap closing, merging and splitting
            
            %Gap closing time window
            gapCloseParam.timeWindow = this.objTrackSettings.MaxGap+1;
            %Flag for merging and splitting
            gapCloseParam.mergeSplit = this.objTrackSettings.UseMergeSplit;
            %Minimum track segment length used in the gap closing, merging and
            %splitting step
            gapCloseParam.minTrackLen = this.objTrackSettings.MinCompoundLength;
            %Time window diagnostics: 1 to plot a histogram of gap lengths in
            %the end of tracking, 0 or empty otherwise
            gapCloseParam.diagnostics = 0;
            
            %Same parameters as for the frame-to-frame linking cost function
            parameters.linearMotion = this.objTrackSettings.UseLinModel;
            parameters.useLocalDensity = this.objTrackSettings.UseLocDens;
            parameters.minSearchRadius = this.objTrackSettings.MinSearchRad;
            parameters.maxSearchRadius = this.objTrackSettings.MaxSearchRad;
            parameters.brownStdMult = this.objTrackSettings.SearchExpFac*ones(gapCloseParam.timeWindow,1);
            parameters.nnWindow = this.objTrackSettings.LocDensWin;
            %Formula for scaling the Brownian search radius with time.
            %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            parameters.brownScaling = [this.objTrackSettings.FreeScaleFast this.objTrackSettings.FreeScaleSlow];
            %before timeReachConfB, the search radius grows with time with the power in brownScaling(1);
            %after timeReachConfB it grows with the power in brownScaling(2).
            parameters.timeReachConfB = this.objTrackSettings.FreeScaleTrans;
            %Amplitude ratio lower and upper limits
            parameters.ampRatioLimit = [this.objTrackSettings.MinAmpRatio this.objTrackSettings.MaxAmpRatio];
            %Minimum length (frames) for track segment analysis
            parameters.lenForClassify = this.objTrackSettings.LinClassifyLength;
            %Standard deviation multiplication factor along preferred direction of motion
            parameters.linStdMult = this.objTrackSettings.LinSearchExpFac*ones(gapCloseParam.timeWindow,1);
            %Formula for scaling the linear search radius with time.
            %power for scaling the linear search radius with time (similar to brownScaling).
            parameters.linScaling = [this.objTrackSettings.LinScaleFast this.objTrackSettings.LinScaleSlow];
            %similar to timeReachConfB, but for the linear part of the motion.
            parameters.timeReachConfL = this.objTrackSettings.LinScaleTrans;
            %Maximum angle between the directions of motion of two linear track
            %segments that are allowed to get linked
            parameters.maxAngleVV = this.objTrackSettings.LinMaxAngle;
            %Gap length penalty (disappearing for n frames gets a penalty of
            %gapPenalty^n)
            %Note that a penalty = 1 implies no penalty, while a penalty < 1 implies
            %that longer gaps are favored
            parameters.gapPenalty = this.objTrackSettings.GapPenalty;
            %Resolution limit in pixels, to be used in calculating the merge/split search radius
            %Generally, this is the Airy disk radius, but it can be smaller when
            %iterative Gaussian mixture-model fitting is used for detection
            parameters.resLimit = this.objTrackSettings.ResLimit;
            %Store parameters for function call
            costMatrices(2).parameters = parameters;
            
            %% additional input
            saveResults = 0;
            
            %% tracking function call
            hProgressbar = ClassProgressbar({'Tracking Process...', ...
                'Linking features forwards...',...
                'Linking features backwards...',...
                'Linking features forwards...',...
                'Constructing Trajectories...'},...
                'IsInterruptable',true);
            
            [tracksFinal,~,~] = trackCloseGapsKalmanSparse(movieInfo,...
                costMatrices,gapCloseParam,kalmanFunctions,dim,saveResults,hProgressbar);
            
            if check_for_process_interruption(hProgressbar)
                close_progressbar(hProgressbar)
                return
            end %if
            
            objTraj = ClassTrajectory;
            set_parent(objTraj,this.Parent)
            objTraj.Name = this.Name;
            objTraj.DetectionMap = this.DetectionMap;
            objTraj.Dim = dim;
            
            objTraj.objImageFile = copy(this.objImageFile);
            set_parent(objTraj.objImageFile,objTraj)
            objTraj.objUnitConvFac = copy(this.objUnitConvFac);
            set_parent(objTraj.objUnitConvFac,objTraj)
            objTraj.objLocSettings = copy(this.objLocSettings);
            set_parent(objTraj.objLocSettings,objTraj)
            objTraj.objTrackSettings = copy(this.objTrackSettings);
            set_parent(objTraj.objTrackSettings,objTraj)
            
            objTraj.objContrastSettings = ManagerContrastSettings(objTraj);
            objTraj.objDisplaySettings = ManagerDisplaySettings(objTraj);
            objTraj.objJumpSeries = ManagerJumpSeries(objTraj);
            objTraj.objDiffCoeffFit = ManagerMsdCurveFit(objTraj);
            objTraj.objConfManager = ManagerConfSettings(objTraj);
            
            objTraj.objColormap = ManagerColormap(objTraj);
            objTraj.objGrid = ManagerGrid(objTraj);
            objTraj.objRoi = ManagerRoi(objTraj);
            objTraj.objScalebar = ManagerScalebar(objTraj);
            objTraj.objTimestamp = ManagerTimestamp(objTraj);
            objTraj.objTextstamp = ManagerTextstamp(objTraj);
            
            if this.objRoi.CropRoi
                objTraj.FieldOfView = this.MaskRect;
            else
                objTraj.FieldOfView = this.FieldOfView;
            end %if
            
            objTraj.objIndividual = ClassSingleTrajectory.empty;
            
            %generate black background
            objTraj.RawImagedata = zeros(objTraj.FieldOfView(6),...
                objTraj.FieldOfView(5));
            objTraj.Imagedata = objTraj.RawImagedata;
            
            %convert to trajectory cell structure
            partCnt = [0; cumsum(accumarray(this.Data.Time,1))];
            objTraj.NumIndividual = numel(tracksFinal);
            
            %             good = cell(objTraj.NumIndividual,1);
            %             for trajIdx = 1:objTraj.NumIndividual
            %                 if all([2 3] ~= trajIdx)
            %                 trajStart = tracksFinal(trajIdx).seqOfEvents(1);
            %                 frame = find(tracksFinal(trajIdx).tracksFeatIndxCG)+trajStart-1;
            %                 good{trajIdx} = double(nonzeros(tracksFinal(trajIdx).tracksFeatIndxCG))+...
            %                         partCnt(frame);
            %                 end %if
            %             end %for
            %             good = vertcat(good{:});
            %             listLocalizedTrack = structfun(@(x)x(good),this.Data,'Un',0);
            %             objTraj.objIndividual(trajIdx) = ...
            %                         ClassSingleTrajectory(objTraj,listLocalizedTrack);
            %             close_progressbar(hProgressbar)
            
            for trajIdx = 1:objTraj.NumIndividual
                trajStart = tracksFinal(trajIdx).seqOfEvents(1);
                frame = find(tracksFinal(trajIdx).tracksFeatIndxCG)+trajStart-1;
                good = double(nonzeros(tracksFinal(trajIdx).tracksFeatIndxCG))+...
                    partCnt(frame);
                
                listLocalizedTrack = structfun(@(x)x(good),this.Data,'Un',0);
                objTraj.objIndividual(trajIdx) = ...
                    ClassSingleTrajectory(objTraj,listLocalizedTrack);
                if check_for_process_interruption(hProgressbar)
                    delete(objTraj)
                    close_progressbar(hProgressbar)
                    return
                else
                    update_progressbar(hProgressbar,{(3+trajIdx/objTraj.NumIndividual)/4,...
                        [],[],[],trajIdx/objTraj.NumIndividual})
                end %if
            end %for
            
            add_data_to_project(...
                get_parental_object(this,'ClassProject'),objTraj)
            
            %close
            close_progressbar(hProgressbar)
            
            %check if actual data object is visualized
            if ishandle(this.hImageFig)
                initialize_visualization(objTraj)
            end %if
        end %fun
        
        %%
        function objCluster = construct_density_based_cluster(this)
            %close cluster manager
            if ishandle(this.objClusterSettings.hFig)
                close_object(this.objClusterSettings)
            end %if
            
            if isempty(this.objClusterSettings.NumCluster)
                waitfor(errordlg('No Cluster found','','modal'))
                return
            end %if
            
            objCluster = ClassCluster;
            set_parent(objCluster,this.Parent)
            objCluster.Name = this.Name;
            objCluster.DetectionMap = this.DetectionMap;
            
            objCluster.objImageFile = copy(this.objImageFile);
            set_parent(objCluster.objImageFile,objCluster)
            objCluster.objUnitConvFac = copy(this.objUnitConvFac);
            set_parent(objCluster.objUnitConvFac,objCluster)
            objCluster.objLocSettings = copy(this.objLocSettings);
            set_parent(objCluster.objLocSettings,objCluster)
            objCluster.objDisplaySettings = copy(this.objDisplaySettings);
            set_parent(objCluster.objDisplaySettings,objCluster)
            objCluster.objTrackSettings = copy(this.objTrackSettings);
            set_parent(objCluster.objTrackSettings,objCluster)
            objCluster.objClusterSettings = copy(this.objClusterSettings);
            set_parent(objCluster.objClusterSettings,objCluster)
            
            objCluster.objContrastSettings = ManagerContrastSettings(objCluster);
            objCluster.objDisplaySettings = ManagerDisplaySettings(objCluster);
            
            objCluster.objColormap = ManagerColormap(objCluster);
            objCluster.objGrid = ManagerGrid(objCluster);
            objCluster.objRoi = ManagerRoi(objCluster);
            objCluster.objScalebar = ManagerScalebar(objCluster);
            objCluster.objTimestamp = ManagerTimestamp(objCluster);
            objCluster.objTextstamp = ManagerTextstamp(objCluster);
            
            if this.objRoi.CropRoi
                objCluster.FieldOfView = this.MaskRect;
            else
                objCluster.FieldOfView = this.FieldOfView;
            end %if
            
            %initialize
            hProgressbar = ClassProgressbar(...
                {'Constructing Cluster...'});
            
%             if any(this.objClusterSettings.PntType == -1)
%                 hasNoise = 1;
%             else
%                 hasNoise = 0;
%             end %if
            
            objCluster.objIndividual = ClassSingleCluster.empty;
            
            
            clusterID = unique(this.objClusterSettings.ClusterID);
            objCluster.NumIndividual = numel(clusterID);
            for clusterIdx = 1:objCluster.NumIndividual
                good = this.objClusterSettings.ClusterID == clusterID(clusterIdx);
                
                dataClustered = structfun(@(x)x(good),this.Data,'Un',0);
                
                objCluster.objIndividual(clusterIdx) = ...
                    ClassSingleCluster(objCluster,sum(good),...
                    dataClustered,...
                    this.objClusterSettings.PntType(good),...
                    this.objClusterSettings.PntType(good));
                
                %update
                update_progressbar(hProgressbar,...
                    {clusterIdx/objCluster.NumIndividual})
            end %for
            add_data_to_project(...
                get_parental_object(this,'ClassProject'),objCluster)
            
            %close
            close_progressbar(hProgressbar)
            
            %check if actual data object is visualized
            if ishandle(this.hImageFig)
                initialize_visualization(objCluster)
            end %if
        end %fun
        
        %% particle filter
        function isinsideroi = get.IsInsideRoi(this)
            %calculate linear indices for bins inside
            %arbitrary shaped user defined region of interest
            mask = this.Maskdata;
            linMask = find(mask);
            
            %calculate linear indices of bins which contain point
            actExp = this.ActExp;
            dx = transform_mag_to_orig(...
                0.5:this.objImageFile.ChannelWidth*actExp+0.5,actExp,0.5);
            dy = transform_mag_to_orig(...
                0.5:this.objImageFile.ChannelHeight*actExp+0.5,actExp,0.5);
            
            [~, row] = histc(this.Data.Position_Y, dy);
            [~, col] = histc(this.Data.Position_X, dx);
            linCoords = col*this.objImageFile.ChannelHeight*actExp+row;
            
            isinsideroi = ismembc(linCoords,linMask);
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassData(this);
        end %fun
        function close_object(this)
            close_object@SuperclassData(this)
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
        end %fun
        function delete_object(this)
            delete_object@SuperclassData(this)
            
            if ishandle(this.hImageFig)
                delete(this.hImageFig)
            end %if
            
            delete(this)
        end %fun
    end %methods
    
    methods (Static)
        function this = loadobj(S)
            this = ClassLocalization;
            this = loadobj@SuperclassData(this,S);
        end %fun
    end %methods
end %classdef