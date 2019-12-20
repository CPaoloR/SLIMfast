function [X, flag] = filter_sparse_events(X,minLength)
% Filters events within a logical vector 
% smaller given a minimum event length.
%
%
% INPUT:
%       X
%
% OUTPUT:
%       X
%
% written by
% C.P.Richter
% Division of Biophysics / Group J.Piehler
% University of Osnabrueck

% Version:
% 1.0 (14/02/05)

if ~isvector(X)
    flag = 0;
    X = [];
    
    fprintf('ERROR in function *filter_sparse_spikes*: Does not support multi-dimensional input.\n')
    return
end %if
if ~islogical(X)
    flag = 0;
    X = [];
    
    fprintf('ERROR in function *filter_sparse_spikes*: Input must be logical.\n')
    return
end %if

N = numel(X);
X = X(:);

if minLength == 1
    ddX = diff(X,2);
    idxSparseSpike = find(ddX == -2) + 1;
    X(idxSparseSpike) = false;
    
    %evaluate vector bounds
    if X(1) == 1
        if X(2) == 0
            X(1) = false;
        end %if
    end %if
    if X(N) == 1
        if X(N-1) == 0
            X(N) = false;
        end %if
    end %if
else
    idxEvent = get_event_index(X);
    lengthEvent = diff(idxEvent,1,2) + 1;
    hasLength = reshape(find(lengthEvent >= minLength),1,[]);
    
    X = false(N,1);
    for idxGood = hasLength
        X(idxEvent(idxGood,1):idxEvent(idxGood,2)) = true;
    end %for
end %if
end %fun