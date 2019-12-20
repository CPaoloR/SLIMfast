function imgCorr = calculate_normalized_image_auto_correlation(img)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

imgSum = sum(sum(img.*img));
imgFFT = fft2(img);
imgCorr = fftshift(real(ifft2(imgFFT.*conj(imgFFT))))/imgSum;
end %fun