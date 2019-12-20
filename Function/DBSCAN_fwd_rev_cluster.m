function [clusterID,pntType,numCluster,clusterSize,clusterTime,clusterPair,...
    forwardClusterID,forwardPntType,forwardNumCluster,forwardClusterSize,...
    revClusterID,revPntType,revNumCluster,revClusterSize] = ...
    DBSCAN_fwd_rev_cluster(SML,pntNN,T,critScore,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 05.05.2015
%modified 18.05.2015: fwd & rev cluster fusion via maximum overlap
%modified 01.06.2015: make sure only one borderpoint per frame is allocated

ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip,'SML',@isvector)
addRequired(ip,'pntNN')
addRequired(ip,'T',@isscalar)
addRequired(ip,'critScore',@isscalar)
addParamValue(ip,'verbose', false, @(x)islogical(x))
addParamValue(ip,'pntDist',[])
addParamValue(ip,'idOffset',0,@(x)isscalar(x) || isempty(x))
parse(ip,SML,pntNN,T,critScore,varargin{:});
input = ip.Results;

verbose = ip.Results.verbose;
idOffset = ip.Results.idOffset;

%% forward
forwardPntNN = DBSCAN_hard_thresh(SML,pntNN,1:T,varargin{:});
forwardPntScore = DBSCAN_point_score(forwardPntNN);
[forwardClusterID,forwardPntType,forwardNumCluster,forwardClusterSize] = ...
    DBSCAN_group(forwardPntNN,forwardPntScore,critScore,'pntOrder','ascend');

%% reverse
revPntNN = DBSCAN_hard_thresh(SML,pntNN,-T:-1,varargin{:});
revPntScore = DBSCAN_point_score(revPntNN);
[revClusterID,revPntType,revNumCluster,revClusterSize] = ...
    DBSCAN_group(revPntNN,revPntScore,critScore,'pntOrder','descend');

%% fusion of forward & reverse
take = ((forwardPntType == 0) & (revPntType == 1)) | ...
    ((forwardPntType == 1) & (revPntType == 0)) | ...
    ((forwardPntType == 1) & (revPntType == 1));
if not(any(take))
    clusterPair = [];
else
    clusterAsso = [forwardClusterID(take) revClusterID(take)];
    clusterAsso = accumarray(clusterAsso,1);
    [clusterPair(:,1),clusterPair(:,2)] = find(bsxfun(@eq,clusterAsso,max(clusterAsso,[],1)) & ...
        transpose(bsxfun(@eq,transpose(clusterAsso),max(transpose(clusterAsso),[],1))) & ...
        clusterAsso > 0);
end

numCluster = size(clusterPair,1);

pntType = -1*ones(size(forwardClusterID));
clusterID = ones(size(forwardClusterID));
clusterSize = [];
clusterTime = [];
for idxPair = numCluster:-1:1
    %fuse the core points of forward & reverse clustering
    isCluster = ((forwardClusterID == clusterPair(idxPair,1)) & (forwardPntType == 1)) | ...
        ((revClusterID == clusterPair(idxPair,2)) & (revPntType == 1));
    pntType(isCluster) = 1;
    clusterID(isCluster) = idxPair + idOffset + 1;
    
    %% identify all borderpoints between the corepoint caps
    maxForward = max(SML.t(forwardClusterID == clusterPair(idxPair,1) & (forwardPntType == 1)));
    minRev = min(SML.t(revClusterID == clusterPair(idxPair,2) & (revPntType == 1)));
    
    idxBorderForward = find(forwardClusterID == clusterPair(idxPair,1) & (forwardPntType == 0));
    isBetweenForward = (SML.t(idxBorderForward) > maxForward) & (SML.t(idxBorderForward) < minRev);
    
    idxBorderRev = find(revClusterID == clusterPair(idxPair,2) & (revPntType == 0));
    isBetweenRev = (SML.t(idxBorderRev) > maxForward) & (SML.t(idxBorderRev) < minRev);
    
    idxBorder = union(idxBorderForward(isBetweenForward),idxBorderRev(isBetweenRev)); %fuse fwd & rev
    numObsT = accumarray(SML.t(idxBorder),1);
    obsT = find(numObsT); 
    simultanObsT = (nonzeros(numObsT) > 1);
    if any(simultanObsT)
            %discard all multiple observation (only the NN remains)
            for idxSimultanObsT = reshape(find(simultanObsT),1,[])
                isSimultanObsT = find(SML.t(idxBorder) == obsT(idxSimultanObsT));
            
                %take the border point closest to the cluster center
                 pntDist = sqrt((SML.i(idxBorder(isSimultanObsT))-mean([SML.i(isCluster);SML.i(idxBorder)])).^2 + ...
                    (SML.j(idxBorder(isSimultanObsT))-mean([SML.j(isCluster);SML.j(idxBorder)])).^2); 
                [~,idxNN] = min(pntDist);
                isSimultanObsT(idxNN) = []; %remove the nearest-neighbor from the list
                idxBorder(isSimultanObsT) = []; %remove all other oberservations from the neighborhood list
            end %for
    end %if
    pntType(idxBorder) = 0;
    clusterID(idxBorder) = idxPair + idOffset + 1;
    
    %%
    clusterSize(idxPair,1) = sum(clusterID == idxPair + 1);
    clusterTime(idxPair,1) = max(SML.t(isCluster)) - min(SML.t(isCluster)) + 1;
end %for

if verbose
    show_me_my_cluster(SML,forwardClusterID,forwardPntType); title('Forward')
    show_me_my_cluster(SML,revClusterID,revPntType); title('Reverse')
    show_me_my_cluster(SML,clusterID,pntType); title('Forward + Reverse')
end %if
end %fun