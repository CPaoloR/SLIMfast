function image = imread_BigTIFF(file,Index,Header,Region)
%written by
%C.P.Richter
%Division of Biophysics / AG Piehler
%University of Osnabrueck

%load file pointer
fid = fopen(file);

%check byte format
switch fread(fid, 2, '*char')'
    case 'II'%little-endian
        format = 'l';
    case 'MM'%big-endian
        format = 'b';
end %switch

%check if filetype is bigTIFF
if ~isequal(fread(fid, 3, 'uint16', format),...
        [43;8;0])% = bigTIFF
    return
end %if

%jump to frame data
nStrips = numel(Header{Index}.('StripOffsets'));
nPixels = Header{Index}.('Height')*Header{Index}.('Width')/nStrips;
image = zeros(nPixels,nStrips,'uint16');
for strip = 1:nStrips
    fseek(fid, Header{Index}.('StripOffsets')(strip), 'bof');
    image(:,strip) = fread(fid, nPixels, 'uint16', format);
end %for
image = reshape(image,Header{Index}.('Width'),Header{Index}.('Height'))';

if not(isempty(Region))
image = image(Region{1}(1):Region{1}(2),...
    Region{2}(1):Region{2}(2));
end %if

fclose(fid);
end %fun
