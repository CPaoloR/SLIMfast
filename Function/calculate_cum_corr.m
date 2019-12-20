function Ccum = calculate_cum_corr(A,B,r)
distMat = pdist2(A,B); %euclidean distances between localizations of [A] and [B]
Ccum = sum(cumsum(histc(distMat,[0 rowvec(r)]+eps,1),1),2)/size(B,1); % [AB]/[B] & [A]
Ccum(end) = [];
end %fun