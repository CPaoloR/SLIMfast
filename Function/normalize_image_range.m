function imgOut = normalize_image_range(img,range)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 22.04.2014

if nargin == 1
    imageMin = min(min(img));
    imageMax = max(max(img));
else
    imageMin = range(1);
    imageMax = range(2);
end %if

imgOut = min(1,max(0,(img-imageMin)/(imageMax-imageMin)));
end %fun