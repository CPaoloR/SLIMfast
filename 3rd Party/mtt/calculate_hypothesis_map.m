function [loglikeMap, listGuess, binaryMap] = ...
    calculate_hypothesis_map(im,settings)
% EN/ hypothesis map: no particle /
% presence of a particle in the centre of the
% research window, under the hypotheses of
% Gaussian iid background noise with
% the signal of the particle being a Gaussian.
% The amplitude of the signal (particle)
% is unknown, as well as the power of
% the noise. By hypothesis, the background is
% supposed constant, it is thus preferable
% to limit the size of the window (<12)
%
% im: input image
% rayon = width of the Gaussian
% wn_x: width of the detection window
% wn_y: width in y, squared if absent
% s_pfa: threshold for the detection pfa

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EN/ detection at given false alarm rate
% chi2 law with degree of liberty = 1 (3-2)
%
%     s_pfa      1-pfa
%    3.77060   0.94784
%    6.63106   0.98998
%   10.79172   0.99898
%   15.00000   0.999892488823270
%   20.00000   0.999992255783569
%   24.00000   0.999999036642991  (1E-6)
%   25.00000   0.999999426696856
%   28.00000   0.999999878684549  (1E-7)
%   30.00000   0.999999956795369
%   33.00000   0.999999990784113  (1E-8)
%   37.50000   0.999999999085870  (1E-9)
%   40.00000   0.999999999746037
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

T = settings.winX*settings.winY ; % nombre de pixel dans la fenetre

%% Hypothese H0
%% pas de particule dans la fenetre
m = ones(settings.winY,settings.winX) ;
hm = expand_w(m, settings.height, settings.width) ;
tfhm = fft2(hm) ;
tfim = fft2(im) ;
m0 = real(fftshift(ifft2(tfhm .* tfim))) /T ;

im2 = im .* im ;
tfim2 = fft2(im2) ;
Sim2 = real(fftshift(ifft2(tfhm .* tfim2)));

%% H0 = T/2*log(2*pi*sig0^2)-T/2 ;
T_sig0_2 = Sim2 - T*m0.^2 ;

%% Hypothèse H1
%% une particule est au centre de la fenetre
%% amplitude inconnue, rayon fixe

%% generation masque gaussien de largeur (sigma)
%% egal a rayon

g = gausswin2(settings.radiusPSF, ...
    settings.winY, settings.winX) ;
gc = g - sum(g(:))/T ;
Sgc2 = sum(gc(:).^2) ;
hgc = expand_w(gc, settings.height, settings.width) ;
tfhgc = fft2(hgc) ;

alpha = real(fftshift(ifft2(tfhgc .* tfim))) / Sgc2 ;

%% H1 = T/2*log(2*pi*sig1^2)-T/2 ;
%%sig1_2 = sig0_2 - alpha.^2 * Sgc2 / T ;

%% pour test
%sig1_2 = T_sig0_2/T - alpha.^2 * Sgc2 / T ;
%%imagesc(T_sig0_2/T);
%imagesc(sig1_2);
%%imagesc(sig1_2 ./ (T_sig0_2/T));

%%  loglikeMap = -0.5*(H0 - H1) ;
% loglikeMap = - T * log(1 - (Sgc2 * alpha.^2) ./ T_sig0_2) ;
test = 1 - (Sgc2 * alpha.^2) ./ T_sig0_2 ;
test = (test > 0) .* test + (test <= 0) ;
loglikeMap = - T * log(test) ;
loglikeMap(isnan(loglikeMap)) = 0; %CPR (bug when saturated spot)
loglikeMap(isinf(loglikeMap)) = 0;

%% detection et recherche des maximas
%% s_pfa = 28 ;
detect_masque = loglikeMap > ...
    chi2inv(1-10^settings.errRate,1);
if sum(detect_masque(:))==0
    listGuess = zeros(1,6) ;
    binaryMap = zeros(size(detect_masque)) ; % ajout AS 4/12/7
else
    binaryMap = all_max_2d(loglikeMap,...
        settings.height, settings.width) &...
        detect_masque & settings.mask; %CPR (detection mask added)
    
    [di, dj] = find(binaryMap) ;
    n_detect = size(di, 1) ;
    vind = settings.height*(dj-1)+di ;
    valpha = alpha(:) ;
    alpha_detect = valpha(vind) ;
    
    sig1_2 = ( T_sig0_2 - alpha.^2 * Sgc2 ) / T ;
    vsig1_2 = sig1_2(:) ;
    sig2_detect = vsig1_2(vind) ;
    
    %% g de puissance unitaire
    %%RSBdB_detect = 10*log10(alpha_detect.^2  ./ sig2_detect) ;
    
    listGuess = [(1:n_detect)', di, dj, alpha_detect, sig2_detect] ;
    
end%if

    function out = expand_w(in, N, M)
        
        out = zeros(N,M) ;
        nc = floor(N/2 - settings.winY/2) ;
        mc = floor(M/2 - settings.winX/2) ;
        out((nc+1):(nc+settings.winY) ,...
            (mc+1):(mc+settings.winX)) = in ;
        
    end %function
    function carte_max = all_max_2d(input, N, M)
        
        ref = input(2:N-1, 2:M-1) ;
        
        pos_max_h = input(1:N-2, 2:M-1) < ref & ...
            input(3:N  , 2:M-1) < ref;
        pos_max_v = input(2:N-1, 1:M-2) < ref & ...
            input(2:N-1, 3:M  ) < ref;
        pos_max_135 = input(1:N-2, 1:M-2) < ref & ...
            input(3:N  , 3:M  ) < ref;
        pos_max_45  = input(3:N  , 1:M-2) < ref & ...
            input(1:N-2, 3:M  ) < ref;
        
        carte_max = zeros(N,M) ;
        carte_max(2:N-1, 2:M-1) = ...
            pos_max_h & pos_max_v & pos_max_135 & pos_max_45 ;
        carte_max = carte_max .* input ;
        
    end %function
    function g = gausswin2(sig, N, M)
        
        i = 0.5 + (0:(N-1)) - settings.winY/2 ;
        j = 0.5 + (0:(M-1)) - settings.winX/2 ;
        ii = i' * ones(1,M) ;
        jj = ones(N,1) * j ;
        
        %%% puissance unitaire
        g = (1/(sqrt(pi)*sig))*...
            exp(-(1/(2*sig^2))*(ii.*ii + jj.*jj)) ;
    end %function

end %fun