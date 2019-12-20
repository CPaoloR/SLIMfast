function pntScore = DBSCAN_point_score(pntNN,varargin)
ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip,'pntNN')
addParamValue(ip,'weightFun',[], @(x)isa(x,'function_handle'))
addParamValue(ip,'verbose', false, @(x)islogical(x))
parse(ip,pntNN,varargin{:});

weightFun = ip.Results.weightFun;
verbose = ip.Results.verbose;

%%
if isempty(weightFun)
    pntScore = cellfun('size',pntNN,2);
else
    for pntIdx = numPnts:-1:1
        dx = abs(bsxfun(@minus,X(pntNN{pntIdx},:),X(pntNN{pntIdx}(1),:)));
        dx = bsxfun(@times,dx,searchRad); %undo the normalization (r = 1)
        pntScore(pntIdx) = sum(weightFun(dx)) - 1;
    end %for
end

%%
if verbose
    if all(rem(pntScore,1)==0)
        [f,xbin] = hist(pntScore,unique(pntScore));
        figure; hold on
        bar(xbin,f,'hist')
    else
        [f,xbin] = hist_fd(pntScore);
        figure; hold on
        plot(xbin,f,'k.')
    end
    xlabel('Score')
    axis tight
    box on
end %if
end %fun

% % scoring test (no weights)
% clear all
% N = 10000;
% V = 10000;
% rho = N/V;
% X = rand(N,3)*V^(1/3);
%
% r = 1;
% searchRad = [1 1 1]*r;
% critScore = 1;
% pntNN = DBSCAN_pot_link(X,searchRad);
% pntScore = DBSCAN_point_score(pntNN);
% expScore = (4/3*pi*r^3)/V*N;
% obsScore = median(pntScore);