function [listEstimated, nParticles, ...
    deflationMap, binaryMap, loglikeMap] =...
    image_signal_detection(im,settings)
%listEstimated =...
%[MuX MuY MuZ VarX VarY VarZ CovXY CovXZ CovYZ IntVol MuBckgrnd VarBckgrnd Flag]

%initial loop
[listEstimated,loglikeMap, binaryMap,N] = ...
    detection_and_estimation_cycle(im,settings) ;
deflationMap = deflat_part_est(im, listEstimated);
if settings.nDeflate == 0 || N == 0 %do no deflations
    if N > 0
        good = listEstimated(:,1) &...
            listEstimated(:,2) > settings.winY/2 & ...
            listEstimated(:,2) < settings.height-settings.winY/2 & ...
            listEstimated(:,3) > settings.winX/2 & ...
            listEstimated(:,3) < settings.width-settings.winX/2;
        
        listEstimated = listEstimated(good,:);
        nParticles = sum(good);
    else
        nParticles = 0;
    end %if
    return
end %if

% deflation loops
for n=1:settings.nDeflate
    [estimates,loglike,binary,N] = ...
        detection_and_estimation_cycle(deflationMap,settings) ;
    loglikeMap = max(loglikeMap,loglike);
    listEstimated = [listEstimated;  estimates] ;
    
    binaryMap = binaryMap | binary ;
    deflationMap = deflat_part_est(deflationMap, estimates);
    
    if n == settings.nDeflate || N == 0
        good = listEstimated(:,1) &...
            listEstimated(:,2) > settings.winY/2 & ...
            listEstimated(:,2) < settings.height-settings.winY/2 & ...
            listEstimated(:,3) > settings.winX/2 & ...
            listEstimated(:,3) < settings.width-settings.winX/2;
        
        listEstimated = listEstimated(good,:);
        nParticles = sum(good);
        return
    end %if
end%for

    function output = deflat_part_est(input, estimates)
        % EN/ function deflation of particles
        % already estimated & validated (result_ok)
        
        nb_part = size(estimates,1) ;
        
        output = input ;
        
        for part=1:nb_part
            if estimates(part,1) == 1
                i0 = estimates(part,2) ;
                j0 = estimates(part,3);
                alpha = estimates(part,5) ;
                
                pos_i = round(i0) ;
                dep_i = i0 - pos_i ;
                pos_j = round(j0) ;
                dep_j = j0 - pos_j ;
                
                switch settings.locModel %CPR
                    case {'Fixed','Fitted'}
                        r0 = estimates(part,8);
                        
                        wini = ceil(6*r0); %CPR includs 99% of signal
                        if ~mod(wini,2) %CPR make sure win is uneven
                            wini = wini + 1;
                        end %if
                        winj = wini;
                        
                        refi = 0.5 + (0:(wini-1)) - wini/2 ;
                        i = refi - dep_i ;
                        refj = 0.5 + (0:(winj-1)) - winj/2 ;
                        j = refj - dep_j ;
                        ii = i' * ones(1,winj) ; %'
                        jj = ones(wini,1) * j ;
                        
                        alpha_g = (alpha/(sqrt(pi)*r0)) * exp(-(1/(2*r0^2))*(ii.*ii + jj.*jj)) ;
                    case 'Astigmatic'
                        r0_i = estimates(part,8);
                        r0_j = estimates(part,9);
                        
                        wini = ceil(6*r0_i); %CPR includs 99% of signal
                        if ~mod(wini,2) %CPR make sure win is uneven
                            wini = wini + 1;
                        end %if
                        winj = ceil(6*r0_j);
                        if ~mod(winj,2) %CPR make sure win is uneven
                            winj = winj + 1;
                        end %if
                        
                        refi = 0.5 + (0:(wini-1)) - wini/2 ;
                        i = refi - dep_i ;
                        refj = 0.5 + (0:(winj-1)) - winj/2 ;
                        j = refj - dep_j ;
                        ii = i' * ones(1,winj) ; %'
                        jj = ones(wini,1) * j ;
                                    
                        invSigI = 1/r0_i;
                        invSigJ = 1/r0_j;
                        z = invSigI*invSigI*ii.*ii + invSigJ*invSigJ*jj.*jj;
                        alpha_g = alpha*sqrt(invSigI*invSigJ)/sqrt(pi)*exp(-0.5*z);
                end %switch
                
                ddi = (1:wini) - floor(wini/2) ; %CPR
                di = ddi + pos_i ;
                iin = di > 0 & di < settings.height+1; % by CPR
                ddj = (1:winj) - floor(winj/2) ; %CPR
                dj = ddj + pos_j ;
                jin = dj > 0 & dj < settings.width+1; % by CPR
                
                output(di(iin), dj(jin)) = ...
                    output(di(iin), dj(jin)) - alpha_g(iin,jin) ;
            end%if
        end%for
        
    end%nested0
end%fun