function xOrig = transform_mag_to_orig(xMag,magFac,offset)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

xOrig = (0.5*magFac-offset+xMag)/magFac;
end %fun