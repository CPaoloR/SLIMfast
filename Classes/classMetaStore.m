classdef classMetaStore < handle
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    %modified 30.10.2015
    
    properties
        Parent
        
        Meta
    end %properties
    
    methods
        %constructor
        function this = classMetaStore(meta)
            if nargin == 0
                this.Meta = [];
            else
                this.Meta = meta;
            end %if
        end %fun
        
        function set_parent(this,parent)
            this.Parent = parent;
        end %fun
        
        %% getter
        function meta = get_meta(this)
            meta = this.Meta;
        end %fun
        
        %% setter / IMAGE
        function set_image_height(this,imgHeight)
            this.Meta.Raw.Height = imgHeight;
        end %fun
        function set_image_width(this,imgWidth)
            this.Meta.Raw.Width = imgWidth;
        end %fun
        function set_frame_number(this,numFrame)
            this.Meta.Raw.NumFrame = numFrame;
        end %fun
        function set_image_bit_depth(this,bitDepth)
            this.Meta.Raw.BitDepth = bitDepth;
        end %fun
        
        %% getter / IMAGE
        function imgHeight = get_image_height(this)
            imgHeight = this.Meta.Raw.Height;
        end %fun
        function imgWidth = get_image_width(this)
            imgWidth = this.Meta.Raw.Width;
        end %fun
        function numFrame = get_frame_number(this)
            numFrame = this.Meta.Raw.NumFrame;
        end %fun
        function bitDepth = get_image_bit_depth(this)
            bitDepth = this.Meta.Raw.BitDepth;
        end %fun
        
        function fullFrame = get_full_frame(this)
            fullFrame = [1 1 get_image_width(this) get_image_height(this)];
        end %fun
        function idxFrame = get_full_time_series(this)
            idxFrame = 1:get_frame_number(this);
        end %fun
        
        %%
        function set_channel_number(this,numChannel)
            this.Meta.Experiment.NumChannel = numChannel;
        end %fun
        function set_channel_height(this,relHeight)
            for idxChannel = 1:get_channel_number(this)
                this.Meta.Experiment.Channel(idxChannel).Height = relHeight * get_image_height(this);
            end %for
        end %fun
        function set_channel_width(this,relWidth)
            for idxChannel = 1:get_channel_number(this)
                this.Meta.Experiment.Channel(idxChannel).Width = relWidth * get_image_width(this);
            end %for
        end %fun
        function set_channel_acq_mode(this,acqMode)
            this.Meta.Experiment.ChannelAcqMode = acqMode;
            switch acqMode
                case 'sequential'
                    numFrame = get_frame_number(this);
                case 'alternating'
                    numFrame = get_frame_number(this) / get_channel_number(this);
                case 'parallel'
                    numFrame = get_frame_number(this);
            end %switch
            
            for idxChannel = 1:get_channel_number(this)
                this.Meta.Experiment.Channel(idxChannel).NumFrame = numFrame;
            end %for
        end %fun
        function set_channel_origin(this,relOrigin,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Origin = ...
                relOrigin .* [get_image_width(this) get_image_height(this)] + 1; %[x0 y0]
        end %fun
                
        function set_channel_transformation_matrix(this,tform,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Tform = tform;
        end %fun    
        function tform = get_channel_transformation_matrix(this,idxChannel)
            tform = this.Meta.Experiment.Channel(idxChannel).Tform.tdata.T;
        end %fun 
        
        %% getter / IMAGE / channel
        function numChannel = get_channel_number(this)
            numChannel = this.Meta.Experiment.NumChannel;
        end %fun
        function channelHeight = get_channel_height(this)
            channelHeight = unique([this.Meta.Experiment.Channel(:).Height]);
        end %fun
        function channelWidth = get_channel_width(this)
            channelWidth = unique([this.Meta.Experiment.Channel(:).Width]);
        end %fun
        function numFrame = get_channel_frame_number(this)
            numFrame = unique([this.Meta.Experiment.Channel(:).NumFrame]);
        end %fun
        function acqMode = get_channel_acq_mode(this)
            acqMode = this.Meta.Experiment.ChannelAcqMode;
        end %fun
        function channelOrigin = get_channel_origin(this,idxChannel)
            channelOrigin = this.Meta.Experiment.Channel(idxChannel).Origin; %[x0 y0]
        end %fun
        
        %% setter / ACQ / channel
        function set_channel_name(this,channelName,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Name = channelName;
        end %fun
        function set_fluoro_name(this,fluoroName,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Fluorophore.Name = fluoroName;
        end %fun
        function set_fluoro_conc(this,fluoroConc,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Fluorophore.Concentration = fluoroConc;
        end %fun
        function set_ex_wvlnth(this,exWvlnth,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Fluorophore.ExcitationWavelength = exWvlnth;
        end %fun
        function set_fluoro_em_max(this,emWvlnth,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Fluorophore.EmissionWavelength = emWvlnth;
        end %fun
        function set_exposure_time(this,exposureTime,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).ExposureTime = exposureTime;
        end %fun
        function set_lag_time(this,lagTime,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).LagTime = lagTime;
        end %fun
        
        function set_comment(this,comment,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Comment = comment;
        end %fun
        
        %% getter / ACQ / channel
        function channelName = get_channel_name(this,idxChannel)
            channelName = this.Meta.Experiment.Channel(idxChannel).Name;
        end %fun
        function fluoroName = get_fluoro_name(this,idxChannel)
            fluoroName = this.Meta.Experiment.Channel(idxChannel).Fluorophore.Name;
        end %fun
        function emWvlnth = get_fluoro_em_max(this,idxChannel)
            emWvlnth = this.Meta.Experiment.Channel(idxChannel).Fluorophore.EmissionWavelength;
        end %fun
        function exposureTime = get_exposure_time(this,idxChannel)
            exposureTime = this.Meta.Experiment.Channel(idxChannel).ExposureTime;
        end %fun
        function lagTime = get_lag_time(this,idxChannel)
            lagTime = this.Meta.Experiment.Channel(idxChannel).LagTime;
        end %fun
        function psfRadius = get_expected_PSF_radius(this,idxChannel)
            psfRadius = this.Meta.Experiment.Channel(idxChannel).PSF.Median;
        end %fun
        
        function absChannelOrigin = get_channel_abs_origin(this,idxChannel)
            absChannelOrigin = this.Meta.Experiment.Channel(idxChannel).AbsOrigin; %[x0 y0]
        end %fun
        
        function tform = get_align_matrix(this,idxChannel)
            tform = this.Meta.Experiment.Channel(idxChannel).Alignment.Matrix;
        end %fun
        
        %% setter / ROI
        function set_eval_ROI_pos(this,vert)
            this.Meta.Evaluation.ROI.Position = vert;
        end %fun
        function set_eval_ROI_rect_hull(this,rectHull)
            this.Meta.Evaluation.ROI.RectHull = rectHull;
        end %fun
        function set_eval_ROI_area(this,area)
            this.Meta.Evaluation.ROI.Area = area;
        end %fun
        function set_eval_ROI_mask(this,mask)
            this.Meta.Evaluation.ROI.Mask = mask;
        end %fun
        
        %% getter / ROI
        function vert = get_eval_ROI_pos(this)
            vert = this.Meta.Evaluation.ROI.Position;
        end %fun
        function rectHull = get_eval_ROI_rect_hull(this)
            rectHull = this.Meta.Evaluation.ROI.RectHull;
        end %fun
        function area = get_eval_ROI_area(this)
            area = this.Meta.Evaluation.ROI.Area;
        end %fun
        function mask = get_eval_ROI_mask(this)
            mask = this.Meta.Evaluation.ROI.Mask;
        end %fun
        
        %% getter /DBSCAN
        function get_cluster(this,idxChannel)
            
        end %fun
        
        function SML = get_immobile_loc(this)
            SML = get_raw_localization(this.Parent,idxChannel);
            clusterID = get_cluster_id(this.Parent,idxChannel);
            take = (clusterID ~= 1);
            
            SML = get_cross_field_value(SML,take);
        end %fun
        function SML = get_mobile_loc(this,idxChannel)
            SML = get_raw_localization(this.Parent,idxChannel);
            clusterID = get_cluster_id(this.Parent,idxChannel);
            take = (clusterID == 1);
            
            SML = get_cross_field_value(SML,take);
        end %fun
        
        %%
        function set_cell_line(this,cellLine)
            this.Meta.Experiment.CellLine = cellLine;
        end %fun
        function set_temperature(this,temperature)
            this.Meta.Experiment.Temperature = temperature;
        end %fun
        
        function set_numerical_aperture(this,NA)
            this.Meta.Instrument.Objective.LensNA = NA;
        end %fun
        function set_magnification(this,magnification)
            this.Meta.Instrument.Objective.NominalMagnification = magnification;
        end %fun
        function set_phys_pixel_size(this,physPxSize)
            this.Meta.Instrument.Detector.PixelSize = physPxSize;
        end %fun
        function set_pixel_binning(this,binning)
            this.Meta.Instrument.Detector.Binning = binning;
        end %fun
        
        function set_expected_PSF_radius(this,psfRadius,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).PSF.Median = psfRadius;
        end %fun
        
                function NA = get_numerical_aperture(this)
            NA = this.Meta.Instrument.Objective.LensNA;
        end %fun
        function magnification = get_magnification(this)
            magnification = this.Meta.Instrument.Objective.NominalMagnification;
        end %fun
        function physPxSize = get_phys_pixel_size(this)
            physPxSize = this.Meta.Instrument.Detector.PixelSize;
        end %fun
        function binning = get_pixel_binning(this)
            binning = this.Meta.Instrument.Detector.Binning;
        end %fun
        function pxSize = get_pixel_size(this)
            physPxSize = get_phys_pixel_size(this); %[µm]
            magnification = get_magnification(this);
            binning = get_pixel_binning(this);
            
            pxSize = physPxSize/magnification*binning*1000; %[nm]
        end %fun

        %%
        function set_channel_abs_origin(this,absChannelOrigin,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).AbsOrigin = absChannelOrigin; %[x0 y0]
        end %fun
        
        function set_channel_align_matrix(this,tform,idxChannel)
            this.Meta.Experiment.Channel(idxChannel).Alignment.Matrix = tform;
        end %fun       
    end %methods
end %class