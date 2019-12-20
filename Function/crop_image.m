function imageOut = crop_image(imageIn,range,magFac)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

if ~isempty(magFac)
    range = transform_orig_to_mag(range,magFac,0.5);
end %if

imageOut = imageIn(...
    range(2)+0.5:range(4)-0.5,...
    range(1)+0.5:range(3)-0.5);
end %fun