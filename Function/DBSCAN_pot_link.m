function [pntNN,pntDist] = DBSCAN_pot_link(X,searchRad,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

% X -> N x D matrix; encoding the position of each observation in space
% searchRad -> scalar; defines the max. distance between observations to be considered as potential links

%modified 08.05.2015: added conversion to uint32 to save 50%

%%
ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip,'X')
addRequired(ip,'searchRad')
addParamValue(ip,'algorithm','intern', @(x)ischar(x))
addParamValue(ip,'verbose', false, @(x)islogical(x))
parse(ip,X,searchRad,varargin{:});

algorithm = ip.Results.algorithm;
verbose = ip.Results.verbose;

%% calculate the nearest-neighbor relationship
switch algorithm
    case 'intern'
        if all(searchRad == searchRad(1))
            objKdTree = KDTreeSearcher(X);
            if nargout == 1
                pntNN = rangesearch(objKdTree,X,searchRad(1));
            else
                [pntNN,pntDist] = rangesearch(objKdTree,X,searchRad(1));
            end %if
        else %normalize each dimension so a distance 1 is equal that search radius (ball/ellipsoid search)
            X = bsxfun(@times,X,1./searchRad);
            objKdTree = KDTreeSearcher(X);
            if nargout == 1
                pntNN = rangesearch(objKdTree,X,1);
            else
                [pntNN,pntDist] = rangesearch(objKdTree,X,1);
            end %if
        end
    case 'extern'
        % References:
        % [1] M. De Berg, O. Cheong, and M. van Kreveld.
        %     Computational Geometry: Algorithms and
        %     Applications. Springer, 2008.
        %
        % Copyright (c) 2008 Andrea Tagliasacchi
        % All Rights Reserved
        % email: ata2@cs.sfu.ca
        % $Revision: 1.0$  Created on: 2008/09/15
        
        X = bsxfun(@times,X,1./searchRad);
        objKdTree = kdtree_build(X);
        %hack for stability, for some unknown reason only those pointer
        %beginning with 13... seem to work well
        pntrStr = num2str(objKdTree);
        fprintf('New kdTree pointer created: %s\n',pntrStr)
        cnt = 0;
        while not(strcmp(pntrStr(1:2),'13'))
            objKdTree = kdtree_build(X);
            pntrStr = num2str(objKdTree);
            fprintf('New kdTree pointer created: %s\n',pntrStr)
            cnt = cnt + 1;
            if cnt == 10
                fprintf('kdTree generation failed\n')
                return
            end %if
        end
        
        for pntIdx = numPnts:-1:1
            pntNN{pntIdx,1}(1,:) = kdtree_ball_query(objKdTree, X(pntIdx,:), 1);
        end
        
        %         for pntIdx = numPnts:-1:1
        %             pntNN_ = kdtree_range_query(objKdTree, ...
        %                 transpose(vertcat(X(pntIdx,:) - searchRad,X(pntIdx,:) + searchRad)));
        %
        %             X_ = bsxfun(@times,X(pntNN_,:),1./searchRad);
        %             dx = sqrt(sum(bsxfun(@minus,X_,X(pntIdx,:)./searchRad).^2,2));
        %             take = dx <= 1;
        %             pntNN{pntIdx,1}(1,:) = pntNN_(take);
        %         end %for
        
        kdtree_delete(objKdTree)
end %switch
pntNN = cellfun(@uint32,pntNN,'un',0); %saves 50% RAM compared to double precision

%%
if verbose
    %%
    numPotLink = cellfun('size',pntNN,2);
    if not(isempty(numPotLink))
        [f,x] = ecdf(numPotLink);
        
        hFig = figure('Color','w'); hold on
        plot(x,f,'linewidth',2,'color','k')
        xlabel('# pot. links','FontSize',20)
        ylabel('CDF','FontSize',20)
        axis tight
        box on
        set(gca(hFig),'FontSize',20)
    end %if
end %if
end %fun