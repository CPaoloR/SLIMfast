classdef ManagerImageFile < SuperclassManager
    %written by
    %C.P.Richter
    %Division of Biophysics / Group J.Piehler
    %University of Osnabrueck
    
    %15.05.2017: Fix with using Bioformats in combination with ROI
    
    properties
        % Image Information
        NumStacks %number of catenated imagestacks
        
        ImagePaths %folder of imagestack
        ImageNames %name of imagestack
        ImageFormats %format of imagestack
        
        ImageMembershipList %defines to which file a frame belongs
        ImageFrameList %defines the frameindex with respect to each imagestack
        ImageHeaderList %stores the ImageHeaderList of each file
        NumImageFrames %number of frames inside each imagestack
        
        ImageHeight
        ImageWidth
        
        objChannelConfig
        ChannelRegionPx %[x0 y0 xEnd yEnd ImageWidth ImageHeight] pixel region of aquisition channel
        ChannelHeight %pixel ImageHeight of aquisition channel
        ChannelWidth %pixel ImageWidth of aquisition channel
    end %properties
    properties(Transient)
        ImageHeader
        ImagePath %path to actual file
        ImageName %name of actual file
        ImageFormat %format of actual file
        ImreadFrame %defines read-in region for imread ('Index' within actual file)
        ImreadRegion %[x0 y0 xEnd yEnd ImageWidth ImageHeight] defines read-in region for imread ('PixelRegion')
    end %properties
    
    methods
        %constructor
        function this = ManagerImageFile(...
                parent,file,objChannelConfig,hProgressbar)
            if nargin == 0
                parent = [];
            end %if
            this = this@SuperclassManager(parent);
            
            if nargin > 0
                this.objChannelConfig = objChannelConfig;
                
                %check if single or multiple file sources (superstack)
                this.NumStacks = numel(file);
                
                %preallocate
                this.ImagePaths = cell(this.NumStacks,1);
                this.ImageNames = cell(this.NumStacks,1);
                this.ImageFormats = cell(this.NumStacks,1);
                this.ImageHeaderList = cell(this.NumStacks,1);
                
                if ~isempty(hProgressbar)
                    update_progressbar(hProgressbar,{[],[],0})
                end %if
                
                for fileIdx = 1:this.NumStacks
                    [this.ImagePaths{fileIdx}, ...
                        this.ImageNames{fileIdx}, ...
                        this.ImageFormats{fileIdx}] = ...
                        fileparts(file{fileIdx});
                    
                    %get image header
                    switch this.ImageFormats{fileIdx}
                        case {'.tif','.TIF'}
                            this.ImageHeaderList{fileIdx} = ...
                                imfinfo(file{fileIdx});
                            
                            this.ImageHeight(fileIdx,1) = ...
                                this.ImageHeaderList{fileIdx}(1).Height;
                            this.ImageWidth(fileIdx,1) = ...
                                this.ImageHeaderList{fileIdx}(1).Width;
                            
                            %count frames for each image stack
                            this.NumImageFrames(fileIdx) = ...
                                numel(this.ImageHeaderList{fileIdx});
                        otherwise
                            this.ImageHeaderList{fileIdx} = ...
                                bfGetReader(file{fileIdx});
                            
                            this.ImageHeight(fileIdx,1) = ...
                                getSizeY(this.ImageHeaderList{fileIdx});
                            this.ImageWidth(fileIdx,1) = ...
                                getSizeX(this.ImageHeaderList{fileIdx});
                            
                            %count frames for each image stack
                            this.NumImageFrames(fileIdx) = ...
                                getImageCount(this.ImageHeaderList{fileIdx});
                    end %switch
                    this.ImageFrameList = [this.ImageFrameList
                        (1:this.NumImageFrames(fileIdx))'];
                    this.ImageMembershipList = [this.ImageMembershipList;
                        repmat(fileIdx,this.NumImageFrames(fileIdx),1)];
                    
                    if ~isempty(hProgressbar)
                        update_progressbar(hProgressbar,{[],[],fileIdx/this.NumStacks})
                    end %if
                end %for
                
                this.ImageHeight = unique(this.ImageHeight);
                this.ImageWidth = unique(this.ImageWidth);
                
                calculate_pixel_channel_position(this)
            end %if
        end %fun
        function calculate_pixel_channel_position(this)
            this.ChannelRegionPx = ...
                bsxfun(@times,this.objChannelConfig.ChannelRegionNorm,...
                [this.ImageWidth this.ImageHeight ...
                this.ImageWidth this.ImageHeight ...
                this.ImageWidth this.ImageHeight]);
            
            this.ChannelWidth = unique(this.ChannelRegionPx(:,5));
            this.ChannelHeight = unique(this.ChannelRegionPx(:,6));
        end %fun
        
        function isOK = goto_image_frame(this,imgFrame)
            if imgFrame < 1 || imgFrame > sum(this.NumImageFrames)
                return
            end %if
            
            %correct for alternating acquisition mode
            if this.objChannelConfig.NumAlternatingChannels > 1
                imgFrame = this.objChannelConfig.NumAlternatingChannels*imgFrame-...
                    this.objChannelConfig.NumAlternatingChannels+this.Parent.Channel;
            end %if
            this.ImreadFrame = this.ImageFrameList(imgFrame);
            
            this.objChannelConfig.NumParallelChannels
            
            if this.objChannelConfig.NumParallelChannels > 1 && ...
                    ~isempty(this.Parent.Channel)
                this.ChannelRegionPx(this.Parent.Channel,[2 4])
                this.ChannelRegionPx(this.Parent.Channel,[1 3])
                this.ImreadRegion = ...
                    {this.ChannelRegionPx(this.Parent.Channel,[2 4])+[1 0],...
                    this.ChannelRegionPx(this.Parent.Channel,[1 3])+[1 0]};
            else
                this.ImreadRegion = ...
                    {[1 this.ImageHeight] [1 this.ImageWidth]};
            end %if
            
            filemembership = this.ImageMembershipList(imgFrame);
            this.ImageHeader = this.ImageHeaderList{filemembership};
            this.ImagePath = this.ImagePaths{filemembership};
            this.ImageName = this.ImageNames{filemembership};
            this.ImageFormat  = this.ImageFormats{filemembership};
            
            %check if image file exists (in case it was renamed or
            %moved to a different directory)
            if exist(fullfile(this.ImagePath,...
                    [this.ImageName this.ImageFormat]),'file')
                isOK = 1;
            else
                answer = questdlg(sprintf('%s not found',fullfile(this.ImagePath,...
                    [this.ImageName this.ImageFormat])),'ERROR',...
                    'Set new Filename','Set new Path','Abort','Set new Filename');
                switch answer
                    case 'Set new Filename'
                        bfCheckJavaPath;
                        [filename,filepath,isOK] = uigetfile(bfGetFileExtensions,...
                            'Select Imagestack', getappdata(0,'searchPath'));
                        
                        %                         [filename, filepath,isOK] = uigetfile({...
                        %                             '*.tif;*.btf', 'Supported Imageformats TIFF or BigTIFF (.tif, .btf)'},...
                        %                             'Select Imagestack', getappdata(0,'searchPath'));
                        if isOK
                            this.ImagePaths{filemembership} = filepath;
                            this.ImagePath = filepath;
                            [~,filename,fileformat] =  fileparts(filename);
                            this.ImageNames{filemembership} = filename;
                            this.ImageName = filename;
                            this.ImageFormats{filemembership} = fileformat;
                            this.ImageFormat = fileformat;
                        end %if
                    case 'Set new Path'
                        filepath = uigetdir(getappdata(0,'searchPath'));
                        if filepath == 0
                            isOK = 0;
                        else
                            isOK = 1;
                            for fileIdx = 1:this.NumStacks
                                this.ImagePaths{fileIdx} = filepath;
                            end %for
                            this.ImagePath = filepath;
                        end %if
                    case 'Abort'
                        isOK = 0;
                end %switch
            end %if
        end %fun
        function goto_previous_image_frame(this,loop)
            if nargin < 2
                loop = false;
            end %if
            
            if this.ImageFrame > 1
                imgFrame = this.ImageFrame - 1;
            else
                if loop
                    imgFrame = this.NumImageFrames;
                end %if
            end %if
            
            goto_image_frame(this,imgFrame)
        end %fun
        function goto_next_image_frame(this,loop)
            if nargin < 2
                loop = false;
            end %if
            
            if this.ImageFrame < this.NumImageFrames
                imgFrame = this.ImageFrame + 1;
            else
                if loop
                    imgFrame = 1;
                end %if
            end %if
            
            goto_image_frame(this,imgFrame)
        end %fun
        
        function rawimreaddata = read_raw_image(this)
            %loads imagedata from disk
            switch this.ImageFormat
                case {'.tif','.TIF'}
                    try
                        rawimreaddata = imread(...
                            fullfile(this.ImagePath,...
                            [this.ImageName this.ImageFormat]),...
                            'Index', this.ImreadFrame,...
                            'Info',this.ImageHeader,...
                            'PixelRegion', this.ImreadRegion);
                    catch %CPR 22.04.2015: problems with the header from Olis Setup
                        rawimreaddata = imread(...
                            fullfile(this.ImagePath,...
                            [this.ImageName this.ImageFormat]),...
                            'Index', this.ImreadFrame,...
                            'PixelRegion', this.ImreadRegion);
                    end %try
                otherwise
                    pixelRegion = this.ImreadRegion;
                    [rawimreaddata,~,this.ImageHeaderList{1}] = FILE_MOV_import(...
                        fullfile(this.ImagePath,...
                        [this.ImageName this.ImageFormat]),...
                        'ObjImgReader',this.ImageHeader,...
                        'LoadTOI',this.ImreadFrame,...
                        'LoadROI',[pixelRegion{2}(1) pixelRegion{1}(1) ...
                        pixelRegion{2}(2)-pixelRegion{2}(1)+1 pixelRegion{1}(2)-pixelRegion{1}(1)+1]); %CPR 15.05.2017
            end %switch
            %transform to double precision
            rawimreaddata = double(rawimreaddata);
        end %fun
        
        %%
        function saveObj = saveobj(this)
            saveObj = saveobj@SuperclassManager(this);
        end %fun
        function close_object(this)
        end %fun
        function delete_object(this)
            delete_object@SuperclassManager(this)
        end %fun
    end %methods
    
    methods (Access = protected)
        function cpObj = copyElement(this)
            cpObj = copyElement@SuperclassManager(this);
        end %fun
    end %methods
    methods (Static)
        function this = loadobj(S)
            this = ManagerImageFile;
            this = loadobj@SuperclassManager(this,S);
        end %fun
    end %methods
end %classdef