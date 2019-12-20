function precision =...
    model_localization_precision(psfStd, pxSize, photons, noise)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 22.04.2014

%calculates the localization uncertainty based on
%   psfStd, pxSize, photons, noise. (Thompson and Webb)

psfStd = psfStd*pxSize; % px -> nm
precision = sqrt((psfStd.^2+pxSize^2/12)./photons+...
    8*pi.*psfStd.^4.*noise.^2/pxSize^2./photons.^2); %[nm]
end
