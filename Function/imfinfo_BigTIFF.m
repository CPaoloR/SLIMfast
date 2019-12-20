function header = imfinfo_BigTIFF(file,targetCnt)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

if nargin < 2
    targetCnt = inf;
end %if

header = struct([]);

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

%jump to first IFD
cnt = 0;
ifd = fread(fid, 1, 'uint64', format);
fseek(fid, ifd, 'bof');

while ifd ~= 0 && cnt ~= targetCnt
    cnt = cnt +1;
    nTags = fread(fid, 1, 'uint64', format);
    for tag = 1:nTags
        pos = ftell(fid);
        
        % read tag entry
        tagID = fread(fid, 1, 'uint16', format);
        tagDatatype = fread(fid, 1, 'uint16', format);
        tagCount = fread(fid, 1, 'uint64', format);
        
        create_tiff_tag(tagID, tagDatatype, tagCount)
        
        %jump to next tag entry
        fseek(fid, pos+20, 'bof');
    end %for
    ifd = fread(fid, 1, 'uint64', format);
    %jump to next IFD
    fseek(fid, ifd, 'bof');
end %while
fclose(fid);

    function create_tiff_tag(tagID, tagDatatype, tagCount)
        switch tagDatatype
            case 1
                tagDatatype = 'uint8';
                nBytes = 1;
            case 2
                tagDatatype = 'uint8=>char';
                nBytes = 1;
            case 3
                tagDatatype = 'uint16';
                nBytes = 2;
            case 4
                tagDatatype = 'uint32';
                nBytes = 4;
            case 5
                tagDatatype = 'uint32';
                nBytes = 8;
            case 6
            case 7
            case 8
            case 9
            case 10
            case 11
            case 12
            case 13
            case 16
                tagDatatype = 'uint64';
                nBytes = 8;
            case 17
                tagDatatype = 'int64';
                nBytes = 8;
            case 18
        end %switch
        
        if 8*nBytes*tagCount <= 64
            tagValue = fread(fid, [1 tagCount], tagDatatype, format);
        else
            fseek(fid, fread(fid, 1, 'uint64', format), 'bof');
            tagValue = fread(fid, [1 tagCount], tagDatatype, format);
        end %if
        
        switch tagID
            case 256
                header{cnt}.('Width') = ...
                    tagValue;
            case 257
                header{cnt}.('Height') = ...
                    tagValue;
            case 258
                header{cnt}.('BitsPerSample') = ...
                    tagValue;
            case 259
                header{cnt}.('Compression') = ...
                    tagValue;
            case 262
                header{cnt}.('PhotometricInterpretation') = ...
                    tagValue;
            case 273
                header{cnt}.('StripOffsets') = ...
                    tagValue;
            case 277
                header{cnt}.('SamplesPerPixel') = ...
                    tagValue;
            case 278
                header{cnt}.('RowsPerStrip') = ...
                    tagValue;
            case 279
                header{cnt}.('StripByteCounts') = ...
                    tagValue;
            case 284
                header{cnt}.('PlanarConfiguration') = ...
                    tagValue;
            case 296
                header{cnt}.('ResolutionUnit') = ...
                    tagValue;
            case 297
                header{cnt}.('PageNumber') = ...
                    tagValue;
            case 306
                header{cnt}.('DateTime') = ...
                    tagValue;
        end %switch
    end %nested
end %fun