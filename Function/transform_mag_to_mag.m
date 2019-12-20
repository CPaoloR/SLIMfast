function xMagNew = transform_mag_to_mag(xMagOld,magFacNew,magFacOld,offset)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

xMagNew = (magFacOld-2*magFacNew*offset+2*magFacNew*xMagOld)/(2*magFacOld);
end %fun