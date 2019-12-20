function [imgStack,objMeta,objImgReader] = FILE_MOV_import(fileImg,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 07.10.2014
%modified 24.11.2014
%modified 20.05.2015: adds support for loadROI
%modified 31.07.2015: fieldname "frameRange" to "loadTOI"
%modified 02.11.2015: Metadata

bfCheckJavaPath;

if nargin == 0
    [fileName,filePath] = uigetfile(bfGetFileExtensions);
    fileImg = fullfile(filePath,fileName);
    
    objImgReader = [];
    objMeta = [];
    loadROI = [];
    loadTOI = [];
    
    verbose = true;
else
    ip = inputParser;
    ip.KeepUnmatched = true;
    addRequired(ip,'fileImg',@(x)exist(x,'file'))
    addParamValue(ip,'ObjImgReader', [])
    addParamValue(ip,'ObjMeta', [])
    addParamValue(ip,'LoadROI', [], @(x) (isvector(x) & numel(x) == 4) | isempty(x)) %region of interest [x0 y0 width height]
    addParamValue(ip,'LoadTOI', []) %time of interest
    addParamValue(ip,'verbose', false, @(x) isscalar(x) & (islogical(x) | (x == 0 | x == 1)))
    parse(ip,fileImg,varargin{:});
    
    objImgReader = ip.Results.ObjImgReader;
    objMeta = ip.Results.ObjMeta;
    loadROI = ip.Results.LoadROI;
    loadTOI = ip.Results.LoadTOI;
    verbose = ip.Results.verbose;
end %if

if verbose
    fprintf('\nPrepare Input: %s:\n',fileImg)
    reverseStr = '';
end %if

%%
if isempty(objImgReader)
    objImgReader = bfGetReader(fileImg);
end %if

%%
if isempty(objMeta)
    objMeta = classMetaStore;
end %if
set_image_bit_depth(objMeta,getBitsPerPixel(objImgReader))

%%
if isempty(loadROI) %if no ROI is specified -> take the whole x-y-plane
    set_image_height(objMeta,getSizeY(objImgReader))
    set_image_width(objMeta,getSizeX(objImgReader))
    
    loadROI = get_full_frame(objMeta);
else
    set_image_height(objMeta,loadROI(4))
    set_image_width(objMeta,loadROI(3))
end %if

%%
if isempty(loadTOI) %if no TOI is specified -> take the whole time-series
    set_frame_number(objMeta,getImageCount(objImgReader))
    numFrame = get_frame_number(objMeta);
    loadTOI = get_full_time_series(objMeta);
else
    set_frame_number(objMeta,numel(loadTOI))
    numFrame = get_frame_number(objMeta);
    lastFrame = getImageCount(objImgReader); %last frame in the movie
    if min(loadTOI) < 1 || max(loadTOI) > lastFrame %error
        fprintf('Error: Framerange not available.\n')
        imgStack = [];
        return
    end %if
end %if

%% allocate space to hold image
switch get_image_bit_depth(objMeta)
    case 8
        imgType = 'uint8';
    case 16
        imgType = 'uint16';
    case 32
        imgType = 'uint32';
    case 64
        imgType = 'uint64';
end %switch
imgStack = zeros(loadROI(4),loadROI(3),numFrame,imgType);

%% image reading
for idxFrame = 1:numFrame
    %load from file
    imgStack(:,:,idxFrame) = bfGetPlane(objImgReader,...
        loadTOI(idxFrame),loadROI(1),loadROI(2),loadROI(3),loadROI(4));
    
    if verbose
        msg = sprintf('Processed %d/%d',idxFrame, numFrame);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end %if
end
if verbose
    fprintf('\n')
end %if
end