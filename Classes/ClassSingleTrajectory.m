classdef ClassSingleTrajectory < matlab.mixin.Copyable
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    properties
        Parent
        Identifier
        
        Data
        %Px2nm
        %Frame2msec
        %Count2photon
        
        UserSetColor = [1 1 1];
        Color %actual trajectory color
        
        NumPoints
        TotalObsTime %[frames] -> NumObsFrames
        Position % -> delete var
        Hit % -> FrameObs
        HitIdx % -> IdxObs
        Miss% -> FrameNonObs
        MissIdx % -> IdxNonObs
        
        MinData
        MaxData
        
        nObs
        SdDeltaT %[frames]
        SD %[µm^2]
        MsdDeltaT %[frames]
        MSD %[µm^2]
        MSDerr
        StepAngle %[deg]
        StepSize %[nm]
        
        DiffCoeff %[µm^2 s^-1]
        CiDiffCoeff
        AnomalousCoeff
        CiAnomalousCoeff
        TransportCoeff %[µm s^-1]
        CiTransportCoeff
        DiffOffset %[µm]
        CiDiffOffset
        Rsquare
        
        ExportBin
    end %properties
    properties (Hidden, Transient)
        IsSelected = 0; %true, when selected on map
        IsPlotted = 0; %true, when plotted on map
        
        IsSingleLine
        
        IsSegmentSelected = 0;
        TrajSplitTool
        
        hLine
        hLineContextmenu
        LineExpFac
        LineOffset
        LineCoord
        
        listenerDestruction
    end %properties
    properties (Hidden, Dependent)
        Formula
    end %properties
    properties (Hidden, SetObservable)
        IsActive = 1;
    end
    
    methods
        %constructor
        function this = ClassSingleTrajectory(parent,data)
            if nargin > 0
                tStart = tic;
                
                %initialize class
                this.Identifier = now;
                
                this.NumPoints = numel(data.Time);
                
                this.Data = catstruct(struct(...
                    'Traj_ID', ones(this.NumPoints,1)*this.Identifier,...
                    'Traj_ID_Hex', num2hex(ones(this.NumPoints,1)*this.Identifier)),data);
                
                this.MinData = structfun(@(x) min(x),data,'un',0);
                this.MaxData = structfun(@(x) max(x),data,'un',0);
                
                this.TotalObsTime = this.MaxData.Time-this.MinData.Time+1; %[frames]
                this.Position(:,1) = 1:this.TotalObsTime;
                
                timeAdj = this.Data.Time-this.MinData.Time+1; %corrected to t0 = 1
                [this.Hit(:,1),~,this.HitIdx(:,1)] = intersect(1:this.TotalObsTime,timeAdj);
                [this.Miss(:,1),this.MissIdx(:,1)] = setdiff(1:this.TotalObsTime,timeAdj);
                
                set_parent(this,parent)
                
                %%
                calculate_particle_square_displacement(this)
                calculate_particle_mean_square_displacement(this)
                calculate_particle_mean_square_displacement_error(this)
                calculate_particle_displacement_magnitude_and_angle(this)
                %             fit_diffusion_coefficient(this.Parent.objDiffCoeffFit,this)
                
                %% this makes sure each traj gets a unique id (15ms resolution of "now")
                pause(max(0,0.015-toc(tStart)))
            end %if
        end %fun
        function set_parent(this,parent)
            this.Parent = parent;
            
            %             this.listenerDestruction = ...
            %                 event.listener(parent,'ObjectDestruction',...
            %                 @(src,evnt)delete_object(this));
        end %fun
        
        %% getter
        function formula = get.Formula(this)
            switch this.Parent.objDiffCoeffFit.DiffModel
                case 'Free Diffusion'
                    formula = sprintf('D[µm^2 s^{-1}] = %.1e\\pm%.1e; \\sigma[µm] = %.1e\\pm%.1e \n(R^2 = %.2f)',...
                        this.DiffCoeff, this.CiDiffCoeff, ...
                        sqrt(abs(this.DiffOffset))/4, sqrt(abs(this.CiDiffOffset))/4, this.Rsquare);
                case 'Anomalous Diffusion'
                    formula = sprintf('D[µm^2 s^{-1}] = %.1e\\pm%.1e; \\alpha = %.3f\\pm%.3f;\n \\sigma[µm] = %.1e\\pm%.1e (R^2 = %.2f)',...
                        this.DiffCoeff, this.CiDiffCoeff, ...
                        this.AnomalousCoeff, this.CiAnomalousCoeff,...
                        sqrt(abs(this.DiffOffset))/4, sqrt(abs(this.CiDiffOffset))/4, this.Rsquare);
                case 'Transport'
                    formula = sprintf('D[µm^2 s^{-1}] = %.1e\\pm%.1e; V[µm s^{-1}] = %.1e\\pm%.1e;\n \\sigma[µm] = %.1e\\pm%.1e (R^2 = %.2f)',...
                        this.DiffCoeff, this.CiDiffCoeff, ...
                        this.TransportCoeff, this.CiTransportCoeff,...
                        sqrt(abs(this.DiffOffset))/4, sqrt(abs(this.CiDiffOffset))/4, this.Rsquare);
            end %switch
        end %fun
        
        %%
        function calculate_particle_displacement_magnitude_and_angle(this)
            x = accumarray(this.Hit,this.Data.Position_X,[this.TotalObsTime 1],[],nan);
            y = accumarray(this.Hit,this.Data.Position_Y,[this.TotalObsTime 1],[],nan);
            
            this.StepSize(:,1) = sqrt(diff(x).^2+diff(y).^2)*this.Parent.Px2nm; %[nm]
            
            % angle between steps -> theta(n+1) - theta(n)
            %neg. deg. = left turn
            this.StepAngle(:,1) = [nan; diff(atan2(diff(y),diff(x)))*180/pi; nan];
            this.StepAngle(this.StepAngle < -180) = ...
                this.StepAngle(this.StepAngle < -180) + 360;
            this.StepAngle(this.StepAngle > 180) = ...
                this.StepAngle(this.StepAngle > 180) - 360;
        end %fun
        function calculate_particle_square_displacement(this)
            %construct index vectors
            imat = repmat(1:this.NumPoints,this.NumPoints,1)';
            good = tril(true(this.NumPoints),-1);
            i1 = imat(good);
            i0 = imat(flipud(good));
            
            %calculate square displacement & n*dt
            this.SD = ((this.Data.Position_X(i1)-this.Data.Position_X(i0)).^2 +...
                (this.Data.Position_Y(i1)-this.Data.Position_Y(i0)).^2)*...
                (this.Parent.Px2nm/1000)^2; %[µm^2]
            this.SdDeltaT = this.Data.Time(i1)-this.Data.Time(i0); %[frames]
        end %fun
        function calculate_particle_mean_square_displacement(this)
            msd = [0; accumarray(this.SdDeltaT,...
                this.SD,[max(this.SdDeltaT) 1],@mean,nan)]; %[µm^2]
            msdDeltaT = reshape(0:this.TotalObsTime-1,[],1);
            
            %interpolate, where there are no observations
            miss = isnan(msd);
            msd(miss,1) = interp1(...
                msdDeltaT(~miss), msd(~miss), ...
                find(miss)-1, 'linear','extrap');
            
            this.MSD = msd(2:end);
            this.MsdDeltaT = msdDeltaT(2:end);
        end %fun
        function calculate_particle_mean_square_displacement_error(this)
            %msd error estimates following Quian et al.
            this.nObs = accumarray(this.SdDeltaT,1,[],[],1);
            nDt(:,1) = 1:this.TotalObsTime-1;
            good = this.nObs >= max(this.nObs)/2;
            
            msdErr(good,1) = sqrt((4*nDt(good).^2.*this.nObs(good)+...
                2.*this.nObs(good)+nDt(good)-nDt(good).^3)./(6.*nDt(good).*this.nObs(good).^2));
            msdErr(~good,1) = sqrt(1+(this.nObs(~good).^3-...
                4.*nDt(~good).*this.nObs(~good).^2+4.*nDt(~good)-this.nObs(~good))./...
                (6.*nDt(~good).^2.*this.nObs(~good)));
            this.MSDerr = this.MSD.*msdErr;
        end %fun
        
        function [nSeg idxSeg flag] = ...
                segmentize_trajectory(this,winSize)
            %Segmentizes a track using a constant moving time-window
            %
            % INPUT:
            %
            % OUTPUT:
            %           nSeg (Scalar; Number of segments)
            %           idxSeg (Matrix; Indizes of segments as columnvectors)
            %           ptsSeg (Vector; Number of detections in each segment)
            %           lifeTime (Scalar; Time the particle was observed)
            %
            
            %window spans constant time
            nSeg = this.TotalObsTime-winSize+1;
            if nSeg < 1
                idxSeg = [];
                flag = false;
                return
            else
                flag = true;
            end %if
            
            [segMat,windowMat] = meshgrid(1:nSeg ,0:winSize-1);
            idxSeg = segMat + windowMat;
        end %fun
        function [diffCoeff anomalousCoeff diffOffset rsquare] = ...
                window_analysis(this,useWin,winSize,cutOffMode,...
                cutOffVal,diffusionModel)
            
            [diffCoeff anomalousCoeff diffOffset rsquare] = deal([]);
            
            if ~useWin
                winSize = this.TotalObsTime;
            end %if
            [nSeg idxSeg isOK] = ...
                segmentize_trajectory(this,winSize);
            
            if isOK
                t = (1:this.TotalObsTime)';
                x = accumarray(this.Hit,this.Data.Position_X,[this.TotalObsTime 1],[],nan);
                y = accumarray(this.Hit,this.Data.Position_Y,[this.TotalObsTime 1],[],nan);
                
                iMat = repmat(idxSeg(:,1),1,winSize);
                good = tril(true(winSize),-1);
                i1 = iMat(good);
                i0 = iMat(flipud(good));
                
                iSeg = repmat(0:nSeg-1,sum(idxSeg(1:end-1,1)),1);
                i1 = repmat(i1,1,nSeg)+iSeg;
                i0 = repmat(i0,1,nSeg)+iSeg;
                
                sd = ((x(i1)-x(i0)).^2 +...
                    (y(i1)-y(i0)).^2)*...
                    (this.Parent.Px2nm/1000)^2; %[µm^2];
                ndt = t(i1)-t(i0);
                
                subs = bsxfun(@plus,ndt,...
                    0:winSize-1:(nSeg-1)*(winSize-1));
                
                msd = reshape(accumarray(subs(:),sd(:),...
                    [(winSize-1)*nSeg 1],@nanmean, nan),...
                    (winSize-1), nSeg);
                
                %interpolate, where there are no observations
                idxWin = 1:winSize-1;
                for col = 1:size(msd,2)
                    miss = isnan(msd(:,col));
                    if sum(~miss) >= 2
                        msd(miss,col) = interp1(...
                            idxWin(~miss), msd(~miss,col), ...
                            find(miss), 'linear','extrap');
                    end
                end %for
                
                switch cutOffMode
                    case 'absolute'
                        %cutOffVal <= Traj
                        cutoff = min(winSize-1,cutOffVal);
                    case 'relative'
                        cutoff = max(floor((winSize-1)*cutOffVal/100),2);
                end %switch
                
                dt = (1:this.TotalObsTime-1)'*this.Parent.Frame2msec/1000;
                switch diffusionModel
                    case 'linear'
                        x = [ones(cutoff,1) dt(1:cutoff)];
                        yHat = x\(msd(1:cutoff,:));
                        
                        SST = sum(bsxfun(@minus,msd(1:cutoff,:),...
                            mean(msd(1:cutoff,:))).^2);
                        SSR = sum((msd(1:cutoff,:)-x*yHat).^2);
                        rsquare = 1-SSR./SST;
                        
                        diffOffset = yHat(1,:);
                        diffCoeff = yHat(2,:)/4;
                        anomalousCoeff = [];
                    case 'power'
                        x = [ones(cutoff,1) log(dt(1:cutoff))];
                        yHat = x\log(msd(1:cutoff,:));
                        
                        SST = sum(bsxfun(@minus,log(msd(1:cutoff,:)),...
                            mean(log(msd(1:cutoff,:)))).^2);
                        SSR = sum((log(msd(1:cutoff,:))-x*yHat).^2);
                        rsquare = 1-SSR./SST;
                        
                        diffCoeff = exp(yHat(1,:))/4; %[µm^2/s]
                        anomalousCoeff = yHat(2,:);
                        diffOffset = [];
                end %switch
            end %if
        end %fun
        
        %%
        function insert_individual_data(this)
            %draw MSD/dt-Curve
            fit_diffusion_coefficient(this.Parent.objDiffCoeffFit,this)
            patch([this.MsdDeltaT; flipud(this.MsdDeltaT)]*...
                this.Parent.Frame2msec/1000,...
                [this.MSD-this.MSDerr; ...
                flipud(this.MSD+this.MSDerr)],...
                [0.8627 0.8627 0.8627], ...
                'Parent', this.Parent.hDetailAx(2))
            line(...
                'XData',this.MsdDeltaT*this.Parent.Frame2msec/1000,...
                'YData',this.MSD,....
                'Parent',this.Parent.hDetailAx(2),...
                'Color', [0 0 0],...
                'Marker', '.',...
                'MarkerSize', 5)
            
            yhat = evaluate_model(this.Parent.objDiffCoeffFit,this,...
                this.MsdDeltaT*this.Parent.Frame2msec/1000);
            line(...
                'XData',this.MsdDeltaT*this.Parent.Frame2msec/1000,...
                'YData',yhat,...
                'Parent', this.Parent.hDetailAx(2),...
                'Color', [1 0 0],...
                'LineStyle', '--',...
                'LineWidth',2)
            axis(this.Parent.hDetailAx(2), 'tight')
            
            ylimits = get(this.Parent.hDetailAx(2),'YLim');
            line(...
                'XData',[1 1]*this.Parent.objDiffCoeffFit.EffFitStart*...
                this.Parent.Frame2msec/1000, ...
                'YData',[ylimits(1) ylimits(2)], ...
                'Parent', this.Parent.hDetailAx(2),...
                'Color', [1 0 0],...
                'LineStyle', ':',...
                'LineWidth',2)
            line(...
                'XData',[1 1]*this.Parent.objDiffCoeffFit.EffFitEnd*...
                this.Parent.Frame2msec/1000, ...
                'YData',[ylimits(1) ylimits(2)], ...
                'Parent', this.Parent.hDetailAx(2),...
                'Color', [1 0 0],...
                'LineStyle', ':',...
                'LineWidth',2)
            
            title(this.Parent.hDetailAx(2),this.Formula,'FontSize',12)
            xlabel(this.Parent.hDetailAx(2), 'Delay Time [s]')
            ylabel(this.Parent.hDetailAx(2), 'MSD [µm^2]')
            
            %draw trajectory
            time(this.Hit) = this.Data.Time;
            time(this.Miss) = nan;
            positionX(this.Hit) = this.Data.Position_X;
            positionX(this.Miss) = nan;
            positionY(this.Hit) = this.Data.Position_Y;
            positionY(this.Miss) = nan;
            
            line(...
                'XData',positionX,...
                'YData',positionY,...
                'ZData',time, ...
                'Parent',this.Parent.hDetailAx(1),...
                'Color', [0 0 0], ...
                'LineWidth',1)
            
            %mark trajectory start
            line(...
                'XData',[positionX(1);positionX(1)], ...
                'YData',[positionY(1);positionY(1)], ...
                'ZData',[time(1);time(1)],...
                'Parent', this.Parent.hDetailAx(1), ...
                'Color', [1 0 1], ...
                'Marker', '.',...
                'Markersize', 20, ...
                'LineStyle', 'none')
            
            %calculate indices of blinking states
            idx = true(this.TotalObsTime,1);
            idx(unique([this.Miss-1; ...
                this.Miss+1])) = false;
            time(idx) = nan;
            time(this.Miss) = [];
            positionX(idx) = nan;
            positionX(this.Miss) = [];
            positionY(idx) = nan;
            positionY(this.Miss) = [];
            
            line(...
                'XData',positionX,...
                'YData',positionY,...
                'ZData',time,...
                'Parent',this.Parent.hDetailAx(1),...
                'Color', [1 0 0], ...
                'LineWidth',1)
            
            %             axis(this.Parent.hDetailAx(1),'vis3d')
            set(this.Parent.hDetailAx(1),...
                'DataAspectRatio', [1 1 range(this.Data.Time)/min(range(this.Data.Position_X),range(this.Data.Position_Y))],...
                'XLim', [floor(min(this.Data.Position_X)) ceil(max(this.Data.Position_X))],...
                'XTick', [floor(min(this.Data.Position_X)) ...
                mean([floor(min(this.Data.Position_X)) ceil(max(this.Data.Position_X))]) ...
                ceil(max(this.Data.Position_X))],...
                'XTickLabel', char(num2str(floor(min(this.Data.Position_X))), 'x [px]', ...
                num2str(ceil(max(this.Data.Position_X)))),...
                'YLim', [floor(min(this.Data.Position_Y)) ceil(max(this.Data.Position_Y))],...
                'YTick', [floor(min(this.Data.Position_Y)) ...
                mean([floor(min(this.Data.Position_Y)) ceil(max(this.Data.Position_Y))]) ...
                ceil(max(this.Data.Position_Y))],...
                'YTickLabel', char(num2str(floor(min(this.Data.Position_Y))), 'y [px]', ...
                num2str(ceil(max(this.Data.Position_Y)))),...
                'ZLim', [floor(min(this.Data.Time)) ceil(max(this.Data.Time))],...
                'ZTick', [floor(min(this.Data.Time)) ...
                mean([floor(min(this.Data.Time)) ceil(max(this.Data.Time))]) ...
                ceil(max(this.Data.Time))],...
                'ZTickLabel', char(num2str(floor(min(this.Data.Time))), 't [frame]', ...
                num2str(ceil(max(this.Data.Time)))))
            
            %step magnitude between successive frames
            line(...
                'XData',this.Position(1:end-1)+0.5,...
                'YData',this.StepSize,...
                'Parent', this.Parent.hDetailAx(3),...
                'Color', [0 0 0], ...
                'Marker', '.',...
                'Markersize', 5, ...
                'LineStyle', '-')
            
            dataQuantiles = quantile(this.StepSize,[0.25 0.5 0.75]);
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(1),... %(=25th)
                'Parent', this.Parent.hDetailAx(3),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(2),... %(=median)
                'Parent', this.Parent.hDetailAx(3),...
                'Color', [0.9 0 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(3),... %(=75th)
                'Parent', this.Parent.hDetailAx(3),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            
            nbins = calcnbins(this.StepSize(...
                ~isnan(this.StepAngle)), 'fd', 50, 250);
            [~,pdfMag(:,1),xmeshDispMag(:,1),cdfMag(:,1)] =...
                kde(this.StepSize,nbins);
            patch([0; pdfMag; 0],...
                [xmeshDispMag(1); xmeshDispMag; xmeshDispMag(end)],...
                [0.8627 0.8627 0.8627],...
                'Parent', this.Parent.hDetailAx(4))
            linkaxes(this.Parent.hDetailAx(3:4),'y')
            axis(this.Parent.hDetailAx(4),'tight')
            ylabel(this.Parent.hDetailAx(3), sprintf('Magnitude \n[nm]'))
            
            % angle between steps (theta(n+1) - theta(n), neg. deg. = left turn)
            line(...
                'XData',this.Position, ...
                'YData',this.StepAngle, ...
                'Parent', this.Parent.hDetailAx(5),...
                'Color', [0 0 0], ...
                'Marker', '.',...
                'Markersize', 5, ...
                'LineStyle', '-')
            
            dataQuantiles = quantile(this.StepAngle,[0.25 0.5 0.75]);
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(1),... %(=25th)
                'Parent', this.Parent.hDetailAx(5),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(2),... %(=median)
                'Parent', this.Parent.hDetailAx(5),...
                'Color', [0.9 0 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(3),... %(=75th)
                'Parent', this.Parent.hDetailAx(5),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            
            nbins = calcnbins(this.StepAngle(...
                ~isnan(this.StepAngle)), 'fd', 50, 250);
            [~,pdfAngle(:,1),xmeshAngle(:,1),cdfAngle(:,1)] =...
                kde(this.StepAngle,nbins,-180,180);
            patch([0; pdfAngle; 0],...
                [-180; xmeshAngle; 180],...
                [0.8627 0.8627 0.8627],...
                'Parent', this.Parent.hDetailAx(6))
            linkaxes(this.Parent.hDetailAx(5:6),'y')
            axis(this.Parent.hDetailAx(6),'tight')
            ylabel(this.Parent.hDetailAx(5), sprintf('Angle \n[deg]'))
            
            %localization precision
            precision(this.Hit,1) = this.Data.Precision;
            precision(this.Miss,1) = nan;
            line(...
                'XData',this.Position, ...
                'YData',precision, ...
                'Parent', this.Parent.hDetailAx(7),...
                'Color', [0 0 0], ...
                'Marker', '.',...
                'Markersize', 5, ...
                'LineStyle', '-')
            
            dataQuantiles = quantile(precision,[0.25 0.5 0.75]);
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(1),... %(=25th)
                'Parent', this.Parent.hDetailAx(7),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(2),... %(=median)
                'Parent', this.Parent.hDetailAx(7),...
                'Color', [0.9 0 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            line(...
                'XData',[this.Position(1) this.Position(end)],...
                'YData',[1 1]*dataQuantiles(3),... %(=75th)
                'Parent', this.Parent.hDetailAx(7),...
                'Color', [0 0.9 0], ...
                'Marker', 'none',...
                'LineWidth', 1.5,...
                'LineStyle', '--')
            
            nbins = calcnbins(precision(...
                ~isnan(precision)), 'fd', 50, 250);
            [~,pdfLocPrec(:,1),xmeshLocPrec(:,1),cdfLocPrec(:,1)] =...
                kde(precision,nbins);
            patch([0; pdfLocPrec; 0],...
                [xmeshLocPrec(1); xmeshLocPrec; xmeshLocPrec(end)],...
                [0.8627 0.8627 0.8627],...
                'Parent', this.Parent.hDetailAx(8))
            linkaxes(this.Parent.hDetailAx(7:8),'y')
            axis(this.Parent.hDetailAx(8),'tight')
            ylabel(this.Parent.hDetailAx(7), sprintf('Localization \n Precision \n[nm]'))
            xlabel(this.Parent.hDetailAx(8), sprintf('Probability \nDensity'))
            xlabel(this.Parent.hDetailAx(7), 'Trajectory Position')
            
            linkaxes(this.Parent.hDetailAx([3 5 7]),'x')
            xlim(this.Parent.hDetailAx(7), [this.Position(1) this.Position(end)])
            set(this.Parent.hDetailAx(7),'XTick', ...
                this.Position(1):ceil(this.Position(end)/5):this.Position(end-1))
            
            % fill ExportBin
            this.ExportBin = struct(...
                'Header',catstruct(this.Parent.Header, struct(...
                'Number_Points', 'Number Localizations within Trajectory',...
                'Trajectory_Observation_Time', 'Trajectories'' Observation Time [s]',...
                'Step_Magnitude_Data', 'Magnitude of Emitters'' Displacement (pos | mag [nm])',...
                'Step_Magnitude_Empiric_Probability_Density', ...
                'Estimated Probabilitydensity of respective Displacement Magnitude (mag [nm] | pdf(mag))',...
                'Step_Magnitude_Empiric_Cumulative_Probability', ...
                'Estimated Cumulative Probability of respective Displacement Magnitude (mag [nm] | cdf(mag))',...
                'Step_Angle_Data', 'Angle between successive Emitters'' Displacements (pos | angle [deg])',...
                'Step_Angle_Empiric_Probability_Density', ...
                'Estimated Probabilitydensity of respective Displacement Angle (angle [deg] | pdf(angle))',...
                'Step_Angle_Empiric_Cumulative_Probability', ...
                'Estimated Cumulative Probability of respective Displacement Angle (angle [deg] | cdf(angle))',...
                'Localization_Precision_Data', 'Precision of Emitter Localization (pos | prec [nm])',...
                'Localization_Precision_Empiric_Probability_Density', ...
                'Estimated Probabilitydensity of respective Localization Precision (prec [nm] | pdf(prec))',...
                'Localization_Precision_Empiric_Cumulative_Probability', ...
                'Estimated Cumulative Probability of respective Localization Precision (prec [nm] | cdf(prec))',...
                'Square_Displacement_Data', 'Calculated Emitters'' Square Displacements (dt [s] | dx^2 [µm^2])',...
                'Mean_Square_Displacement_Data', 'Calculated Emitters'' Mean Square Displacements (dt [s] | <dx^2>) [µm^2] | err [µm^2]')),...
                'Data',catstruct(this.Data, struct(...
                'Number_Points', this.NumPoints,...
                'Trajectory_Observation_Time', this.TotalObsTime*this.Parent.Frame2msec/1000,...
                'Step_Magnitude_Data', [this.Position(1:end-1)+0.5 this.StepSize],...
                'Step_Magnitude_Empiric_Probability_Density', [xmeshDispMag pdfMag],...
                'Step_Magnitude_Empiric_Cumulative_Probability', [xmeshDispMag pdfMag],...
                'Step_Angle_Data', [this.Position this.StepAngle],...
                'Step_Angle_Empiric_Probability_Density', [xmeshDispMag pdfAngle],...
                'Step_Angle_Empiric_Cumulative_Probability', [xmeshDispMag cdfAngle],...
                'Localization_Precision_Data', [this.Position precision],...
                'Localization_Precision_Empiric_Probability_Density', [xmeshLocPrec pdfLocPrec],...
                'Localization_Precision_Empiric_Cumulative_Probability', [xmeshLocPrec cdfLocPrec],...
                'Square_Displacement_Data', [this.SdDeltaT*this.Parent.Frame2msec/1000 this.SD],...
                'Mean_Square_Displacement_Data', [this.MsdDeltaT*this.Parent.Frame2msec/1000 this.MSD this.MSDerr])));
        end %fun
        function update_individual_data(this,src)
            %close diff. coeff. settings
            if ishandle(this.Parent.objDiffCoeffFit.hFig)
                delete(this.Parent.objDiffCoeffFit.hFig)
            end %if
            
            if isempty(src)
                objIndividual = this;
            else
                %set new list position
                switch get(src,'Tag')
                    case 'goto previous'
                        this.Parent.IndividualSelectIdx = ...
                            max(this.Parent.IndividualSelectIdx-1,1);
                    case 'goto next'
                        this.Parent.IndividualSelectIdx = ...
                            min(this.Parent.IndividualSelectIdx+1,this.Parent.NumIndividual);
                end %switch
                objIndividual = this.Parent.objIndividual(this.Parent.IndividualSelectIdx);
            end %if
            
            %update graphs
            for ax = 1:8
                cla(this.Parent.hDetailAx(ax))
            end %for
            
            insert_individual_data(objIndividual)
            
            set(this.Parent.hDetailToolbar.MsdCurveEst,...
                'ClickedCallback', @(src,evnt)set_parameter(...
                this.Parent.objDiffCoeffFit,objIndividual));
            set(this.Parent.hDetailToolbar.SaveData,...
                'ClickedCallback', @(src,evnt)write_variable_to_ascii(objIndividual))
        end %fun
        
        %%
        function hLine = initialize_map_individual(this)
            this.IsPlotted = 1;
            
            if isempty(this.IsSingleLine)
                if any(strcmp(this.Parent.MapColorType,...
                        {'User','Random','State','Lifetime','Diff. Coeff.'}))
                    this.IsSingleLine = true;
                else
                    this.IsSingleLine = false;
                end %if
            end %if
            
            if this.IsSingleLine
                hLine = line(...
                    'Parent', this.Parent.hImageAx,...
                    'Marker','none',...
                    'LineStyle',this.Parent.objDisplaySettings.TrajLineStyle,...
                    'LineWidth', this.Parent.objDisplaySettings.TrajLineWidth,...
                    'XData', this.Data.Position_X,...
                    'YData', this.Data.Position_Y,...
                    'ButtonDownFcn', @(src,evnt)update_individual_selection_on_map(this),...
                    'Hittest','off');
            else
                for segIdx = this.NumPoints-1:-1:1
                    hLine(segIdx,1) = line(...
                        'Parent', this.Parent.hImageAx,...
                        'Marker','none',...
                        'LineStyle',this.Parent.objDisplaySettings.TrajLineStyle,...
                        'LineWidth', this.Parent.objDisplaySettings.TrajLineWidth,...
                        'XData', [this.Data.Position_X(segIdx) this.Data.Position_X(segIdx+1)],...
                        'YData', [this.Data.Position_Y(segIdx) this.Data.Position_Y(segIdx+1)],...
                        'ButtonDownFcn', @(src,evnt)update_individual_selection_on_map(this),...
                        'Hittest','off');
                end %for
            end %if
            this.hLine = hLine;
            this.LineExpFac = 1;
            this.LineOffset = [0.5 0.5];
            
            update_individual_color_coding(this)
        end %fun
        function hide_non_visible_line_parts(this,isVisible)
            if this.IsSingleLine
                xData = this.Data.Position_X(isVisible);
                xData = transform_orig_to_mag(xData,this.LineExpFac,this.LineOffset(1));
                yData = this.Data.Position_Y(isVisible);
                yData = transform_orig_to_mag(yData,this.LineExpFac,this.LineOffset(2));
                set(this.hLine,'XData',xData,'YData',yData,'Visible','on')
            else
                set(this.hLine(isVisible(2:end)),'Visible','on')
                set(this.hLine(~isVisible(2:end)),'Visible','off')
            end %if
        end %fun
        function adjust_traj_exp(this,newExpFac,newOffset)
            for idxLine = 1:numel(this.hLine)
                if ishandle(this.hLine(idxLine))
                    %correct for expansion and offset
                    xData = get(this.hLine(idxLine),'XData');
                    xData = transform_mag_to_orig(xData,this.LineExpFac,this.LineOffset(1));
                    xData = transform_orig_to_mag(xData,newExpFac,newOffset(1));
                    yData = get(this.hLine(idxLine),'YData');
                    yData = transform_mag_to_orig(yData,this.LineExpFac,this.LineOffset(2));
                    yData = transform_orig_to_mag(yData,newExpFac,newOffset(2));
                    set(this.hLine(idxLine),'XData',xData,'YData',yData)
                end %if
            end %for
            this.LineExpFac = newExpFac;
            this.LineOffset = newOffset;
        end %fun
        function close_individual_map_object(this)
            this.IsPlotted = 0;
            
            if ishandle(this.hLine)
                delete(this.hLine)
            end %if
        end %fun
        function update_individual_selection_on_map(this)
            switch get(this.Parent.hImageFig,'SelectionType')
                case 'normal'
                    if this.IsSelected
                        %unselect trajectory
                        unselect_individual_on_map(this)
                    else
                        %select trajectory
                        this.IsSelected = 1;
                        set(this.hLine,...
                            'Marker','s')
                        
                        %construct associated context menu
                        hContextmenu = uicontextmenu;
                        uimenu(hContextmenu,...
                            'Label', 'Set User Color',...
                            'Callback', @(src,evnt)change_single_individual_color(this.Parent));
                        uimenu(hContextmenu,...
                            'Label', 'Split Trajectory',...
                            'Callback', @(src,evnt)initialize_traj_splitter(this.Parent,this));
                        uimenu(hContextmenu,...
                            'Label', 'Show Details',...
                            'Callback', @(src,evnt)initialize_individual_details(this.Parent,this))
                        switch this.IsActive
                            case 1
                                this.hLineContextmenu = ...
                                    uimenu(hContextmenu,...
                                    'Label', 'Deactivate Trajectory',...
                                    'Separator','on',...
                                    'Callback', @(src,evnt)change_single_individual_state(this.Parent,src));
                            case 0
                                this.hLineContextmenu = ...
                                    uimenu(hContextmenu,...
                                    'Label', 'Activate Trajectory',...
                                    'Separator','on',...
                                    'Callback', @(src,evnt)change_single_individual_state(this.Parent,src));
                        end %switch
                        set(this.hLine,...
                            'UIContextMenu', hContextmenu)
                    end %if
                case 'alt'
            end %switch
        end %fun
        function unselect_individual_on_map(this)
            this.IsSelected = 0;
            set(this.hLine,...
                'Marker','none')
            
            set(this.hLine,...
                'UIContextMenu', [])
        end %fun
        
        function update_individual_state(this)
            if strcmp(this.Parent.MapColorType,'State')
                if this.IsActive
                    set(this.hLine,'Color',this.Parent.MapColor(1,:))
                    set(this.hLineContextmenu,'Label', 'Deactivate Trajectory');
                else
                    set(this.hLine,'Color',this.Parent.MapColor(2,:))
                    set(this.hLineContextmenu,'Label', 'Activate Trajectory');
                end %if
            end %if
            switch this.Parent.SubsetType
                case 'Complete Set'
                    %always visible
                case 'Active Subset'
                    %only visible when active
                    if ~this.IsActive
                        unselect_individual_on_map(this)
                        set(this.hLine,'Visible','off')
                    end %if
                case 'Inactive Subset'
                    %only visible when inactive
                    if this.IsActive
                        unselect_individual_on_map(this)
                        set(this.hLine,'Visible','off')
                    end %if
            end %switch
        end %fun
        
        function change_individual_color(this,newColor)
            this.UserSetColor = newColor;
            if this.IsPlotted
                if strcmp(this.Parent.MapColorType,'User')
                    set(this.hLine,'Color',newColor)
                end %if
            end %if
        end %fun
        function update_individual_color_coding(this)
            switch this.Parent.MapColorType
                case 'User'
                    set(this.hLine,'Color', this.UserSetColor)
                case 'Random'
                    set(this.hLine,'Color', rand(1,3))
                case 'State'
                    switch this.IsActive
                        case 1
                            set(this.hLine,'Color',this.Parent.MapColor(1,:))
                        case 0
                            set(this.hLine,'Color',this.Parent.MapColor(2,:))
                    end %switch
                case 'Time'
                    for point = 1:this.NumPoints-1
                        set(this.hLine(point),'Color',...
                            this.Parent.MapColor(this.Data.Time(point),:))
                    end %for
                case 'Lifetime'
                    set(this.hLine,'Color',...
                        this.Parent.MapColor(find(this.TotalObsTime<= ...
                        this.Parent.MapColorValue,1,'first'),:))
                case 'Jumpsize'
                    for point = 1:this.NumPoints-1
                        if isnan(this.StepSize(this.Hit(point)))
                            set(this.hLine(this.HitIdx(point)),'Color', [1 1 1])
                        else
                           isMatch = find(log10(this.StepSize(this.Hit(point)))<= ...
                                this.Parent.MapColorValue,1,'first');
                            if isempty(isMatch)
                                isMatch = size(this.Parent.MapColor,1); %set to last color (clipped at the top)
                            end
                            set(this.hLine(this.HitIdx(point)),'Color',...
                                this.Parent.MapColor(isMatch,:))
                        end %if
                    end %fun
                case 'Diff. Coeff.'
                    isMatch = find(log10(this.DiffCoeff)<= ...
                        this.Parent.MapColorValue,1,'first');
                    if isempty(isMatch)
                        isMatch = size(this.Parent.MapColor,1); %set to last color (clipped at the top)
                    end %if
                    set(this.hLine,'Color',...
                        this.Parent.MapColor(isMatch,:))
                case 'Confinement'
            end %switch
        end %fun
        
        function change_individual_linewidth(this,linewidth)
            if this.IsPlotted
                set(this.hLine,'LineWidth',linewidth)
            end %if
        end %fun
        function change_individual_linestyle(this,linestyle)
            if this.IsPlotted
                set(this.hLine,'LineStyle',linestyle)
            end %if
        end %fun
        
        function select_individual_segment(this,targetSegIdx)
            switch get(this.TrajSplitTool.hFig,'SelectionType')
                case 'normal'
                    if this.IsSegmentSelected
                        %delete actual selected segment index
                        this.TrajSplitTool.SegIdx = nan;
                        
                        %unselect trajectory
                        this.IsSegmentSelected = 0;
                        set(this.TrajSplitTool.hLine(targetSegIdx),...
                            'Color', [0 0 0],...
                            'Marker','none')
                    else
                        %store actual selected segment index
                        this.TrajSplitTool.SegIdx = targetSegIdx;
                        
                        %deselect all other segments are actually selected
                        this.IsSegmentSelected = 1;
                        set(this.TrajSplitTool.hLine,...
                            'Color', [0 0 0],...
                            'Marker','none')
                        set(this.TrajSplitTool.hLine(targetSegIdx),...
                            'Color', [1 0 0],...
                            'Marker','s')
                        %update slider
                        set(this.TrajSplitTool.hSlider,'Value',targetSegIdx)
                        %update frame position edit box
                        set(this.TrajSplitTool.hFramePosEdit,'String',targetSegIdx)
                    end %if
                case 'alt'
            end %switch
        end %fun
        function goto_individual_segment(this,src)
            switch get(src,'Style')
                case 'edit'
                    targetSegIdx = max(1,min(this.NumPoints-1,str2double(get(src,'String'))));
                    %update slider
                    set(this.TrajSplitTool.hSlider,'Value',targetSegIdx)
                case 'slider'
                    targetSegIdx = round(get(src,'Value'));
            end %switch
            %update frame position edit box
            set(this.TrajSplitTool.hFramePosEdit,'String',targetSegIdx)
            
            set(this.TrajSplitTool.hLine,...
                'Color', [0 0 0],...
                'Marker','none')
            set(this.TrajSplitTool.hLine(targetSegIdx),...
                'Color', [1 0 0],...
                'Marker','s')
            
            %store actual selected segment index
            this.TrajSplitTool.SegIdx = targetSegIdx;
        end %fun
        
        %%
        function asymVal = calculate_diffusion_asymmetry_index(eigVal)
            %written by
            %C.P.Richter
            %Division of Biophysics / Group J.Piehler
            %University of Osnabrueck
            
            %Based on:
            %Rudnick and Gaspari (1987). The shapes of random walks.
            %DOI:10.1126/science.237.4813.384
            
            %asymVal = 0 -> circular
            %asymVal = 1 -> linear
            
            %radius of gyration
            rGyr = (eigVal(:,1).^2+eigVal(:,2).^2).^2;
            asymVal = (eigVal(:,1).^2-eigVal(:,2).^2).^2./rGyr;
        end %fun
        %         function update_individual_color_coding(this,IsSingleLine)
        %             if this.IsSingleLine && IsSingleLine
        %             elseif this.IsSingleLine
        %             end %if
        %         end %fun
        %%
        function S = saveobj(this)
            S = class2struct(this);
            S.Parent = [];
        end %fun
        function this = reload(this,S)
            this = struct2class(S,this);
        end %fun
        function delete_object(this)
            if this.IsPlotted
                close_individual_map_object(this)
            end %if
            delete(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@matlab.mixin.Copyable(this);
            
            cpObj.Identifier = now;
            cpObj.Parent = [];
            
            %             cpObj.IsActive = 1;
            cpObj.IsPlotted = 0;
            cpObj.IsSelected = 0;
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ClassSingleTrajectory;
            
            if isobject(S) %backwards-compatibility
                S = saveobj(S);
            end %if
            
            this = reload(this,S);
        end %fun
    end %methods
end %classdef