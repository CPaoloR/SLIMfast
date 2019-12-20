function pntNN = DBSCAN_hard_thresh(SML,pntNN,timeWin,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%modified 16.04.2015
%modified 19.05.2015: fixed a bug potentially leading to a false time-coordinate for the query point

ip = inputParser;
ip.KeepUnmatched = true;
addRequired(ip,'SML',@iscolumn)
addRequired(ip,'pntNN',@iscell)
addRequired(ip,'timeWin')
addParamValue(ip,'OnlyNN',true)
% addParamValue(ip,'NN',[],@iscell)

parse(ip,SML,pntNN,timeWin,varargin{:});

onlyNN = ip.Results.OnlyNN;

%%
for pntIdx = numel(pntNN):-1:1
    take = ismembc(SML.t(pntNN{pntIdx}),SML.t(pntIdx)+timeWin);
    %     take = (SML.t(pntNN{pntIdx}) > SML.t(pntIdx)) & (SML.t(pntNN{pntIdx}) < SML.t(pntIdx)+1000);
    
    pntNN{pntIdx} = pntNN{pntIdx}(take);
    %     if not(isempty(NN))
    %         NN{pntIdx} = NN{pntIdx}(take);
    %     end %if
    
    if onlyNN
        if numel(pntNN{pntIdx}) > 1
            %check if there are multiple observations within 1 frame
            numObsT = accumarray(SML.t(pntNN{pntIdx}),1);
            obsT = find(numObsT);
            simultanObsT = (nonzeros(numObsT) > 1);
            if any(simultanObsT)
                %discard all multiple observation (only the NN remains)
                for idxSimultanObsT = reshape(find(simultanObsT),1,[])
                    isSimultanObsT = find(SML.t(pntNN{pntIdx}) == obsT(idxSimultanObsT));
                    
                    pntDist = sqrt((SML.i(pntNN{pntIdx}(isSimultanObsT))-SML.i(pntIdx)).^2 + ...
                        (SML.j(pntNN{pntIdx}(isSimultanObsT))-SML.j(pntIdx)).^2);
                    [~,idxNN] = min(pntDist);
                    isSimultanObsT(idxNN) = []; %remove the nearest-neighbor from the list
                    pntNN{pntIdx}(isSimultanObsT) = []; %remove all other oberservations from the neighborhood list
                end %for
            end %if
        end %if
    end %if
end %for
end %fun