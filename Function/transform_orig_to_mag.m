function xMag = transform_orig_to_mag(xOrig,magFac,offset)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

xMag = magFac*xOrig-magFac*offset+0.5;
end %fun