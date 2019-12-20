function [estimate, loglikeMap, binaryMap, N] = ...
    detection_and_estimation_cycle(im,settings)%%, pas_ijr)

% detection for fixed psfsdt
[loglikeMap,listGuess,binaryMap] =...
    calculate_hypothesis_map(im,settings);

N = 0 ;
if size(listGuess, 1) == 0 %no pixel meets glrt threshold
    estimate = [];
    return ;
end%if

for n=1:size(listGuess, 1)
    isInside = listGuess(n,2) > settings.winY/2 &&...
        listGuess(n,2) < settings.height-settings.winY/2 &&...
        listGuess(n,3) > settings.winX/2 &&...
        listGuess(n,3) < settings.width-settings.winX/2 ;
    if listGuess(n,4) > 0 && isInside
        N = N + 1 ;
        estimate(N,:) =...
            single_signal_estimation(im,settings,listGuess(n,:));
    end%if
end%for

if N == 0
    estimate = [];
end %if
end%fun