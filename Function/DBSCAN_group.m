function [clusterID,pntType,numCluster,clusterSize] = DBSCAN_group(pntNN,pntScore,critScore,varargin)
%DBSCAN (Density-Based Spatial Clustering of Applications with Noise)
%is a data clustering algorithm proposed by Martin Ester, Hans-Peter Kriegel,
%Jörg Sander and Xiaowei Xu in 1996.

%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 29.06.2014
%modified 02.03.2015: unified all DBSCAN flavours
%modified 16.04.2015: decoupled for modality reasons
%modified 18.05.2015: fixed a bug that allowed the clusters to propagate through border points

ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip,'pntNN')
addRequired(ip,'pntScore')
addRequired(ip,'critScore',@(x)isscalar(x) && x > 0)
addParamValue(ip,'pntOrder', 'ascend', @(x)ischar(x))
addParamValue(ip,'verbose', false, @(x)islogical(x))
parse(ip,pntNN,pntScore,critScore,varargin{:});

pntOrder = ip.Results.pntOrder;   
verbose = ip.Results.verbose;

%%
numPnts = numel(pntScore);
switch pntOrder
    case 'ascend'
        pntList = 1:numPnts;
    case 'descend'
        pntList = numPnts:-1:1;
end %switch

pntType = (pntScore >= critScore); %is core point

% reverseStr = '';
clusterID = nan(numPnts,1); %unclassified
clusterIdx = 0;
for pntIdx = pntList
    if pntType(pntIdx) == 1 && isnan(clusterID(pntIdx))
        %initialize new cluster
        clusterIdx = clusterIdx+1;
        
        %point is put into respective cluster
        clusterID(pntIdx) = clusterIdx;
        
        isConn = pntNN{pntIdx};
        take = isnan(clusterID(isConn)); %only use those points not already classified
        while any(take)
            clusterID(isConn(take)) = clusterIdx;
            
            isConn_ = unique(horzcat(pntNN{isConn(take)}));
            isConn = isConn_(not(ismembc(isConn_,isConn(take))));
            %                         isConn = setdiff(horzcat(pntNN{isConn(take)}),isConn(take));
            take = isnan(clusterID(isConn)) & (pntType(isConn) == 1); %make sure clusters propagate only through core points
        end %while
    end %
    %     msg = sprintf('Processed %d/%d', pntIdx, numPnts);
    %     fprintf([reverseStr, msg]);
    %     reverseStr = repmat(sprintf('\b'), 1, length(msg));
end %for
clusterID = clusterID + 1;
isNoise = isnan(clusterID);
clusterID(isNoise) = 1; %assign noise points to the same cluster

pntType = double(pntType);
pntType(isNoise) = -1; %is noise point

numCluster = clusterIdx; %(= #, noise cluster excluded)
clusterSize = accumarray(clusterID,1);

%%
if verbose
    %%
    [f,xbin] = hist_fd(clusterSize(2:end));
    figure; hold on
    plot(xbin,f,'k.')
    xlabel('Clustersize')
    axis tight
    box on
    
    %%
    [f,xbin] = hist(pntType,[-1 0 1]);
    figure; hold on
    bar(xbin,f,'hist')
    xlabel('Pointtype')
    axis tight
    box on
end %if
end %fun

% TESTING
%% scoring test (no weights)
% clear all
% N = 100000;
% V = 100000;
% rho = N/V;
% X = rand(N,3)*V^(1/3);
%
% r = 1;
% searchRad = [1 1 1]*r;
% critScore = 1;
% [~,pntScore,~] = DBSCAN(X,critScore,searchRad,'algorithm','intern','verbose',false);
% expScore = (4/3*pi*r^3)/V*N;
% obsScore = median(pntScore);

%%

%         searchFun = @(refPnt)transpose(cell2mat(rangesearch(objKdTree,refPnt,1)));
%         if strcmp(input.weightFun,'none')
%             scoreFun = @(refPnt,inRangeX)size(inRangeX,1) - 1;
%         else
%             distFun = @(refPnt,inRangeX);
%             scoreFun = @(refPnt,inRangeX)sum(prod(input.weightFun(distFun(refPnt,inRangeX)),2),1) - 1;
%         end %if


% X = rand(10000,3)*10;
% searchRad = [1 1 5];
%
% normFac = 1./searchRad;
% normX = bsxfun(@times,X,normFac);
% objKdTree = KDTreeSearcher(normX);
%
% searchFun = @(refPnt)cell2mat(rangesearch(objKdTree,refPnt,1));
%
% idxQuery = 1;
% isIn = searchFun(normX(idxQuery,:));
%
% figure; hold on
% plot3(X(:,1),X(:,2),X(:,3),'k.')
% plot3(X(isIn,1),X(isIn,2),X(isIn,3),'ro')
% plot3(X(idxQuery,1),X(idxQuery,2),X(idxQuery,3),'gx')
%
% distFun = @(refPnt,inRangeX)bsxfun(@times,abs(bsxfun(@minus,inRangeX,refPnt)),1./normFac);
% % distFun(normX(idxQuery,:),normX(isIn,:))
%
% %% gaussian weights in all dimensions
% sig = [1 1 1];
% weightFun = @(dx)exp(bsxfun(@times,dx.^2,-0.5./sig./sig));
%
% % weightFun(distFun(normX(idxQuery,:),normX(isIn,:)))
% scoreFun = @(refPnt,inRangeX)sum(prod(weightFun(distFun(refPnt,inRangeX)),2),1) - 1;
% scoreFun(normX(idxQuery,:),normX(isIn,:))

% X = rand(30000,3)*10;
% searchRad = [5 5 5];
% critScore = 510;
%
% profile on
% [clusterID,pntScore,pntType,numCluster] = DBSCAN(X,critScore,searchRad);
% profile viewer


% sig = [1 1 1];
% weightFun = @(dx)prod(exp(bsxfun(@times,dx.^2,-0.5./sig.^2)),2);
%
% sig = [1 1];
% weightFun = @(dx)horzcat(exp(bsxfun(@times,dx(:,1:2).^2,-0.5./sig.^2)),double(dx(:,3)==0));

