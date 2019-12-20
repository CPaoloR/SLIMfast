function [idxEvent, flag] = get_event_index(X)
% Extracts indices of events in logical vector.
%
%
% INPUT:
%       X
%
% OUTPUT:
%       idxEvent
%
% written by
% C.P.Richter
% Division of Biophysics / Group J.Piehler
% University of Osnabrueck

% Version:
% 1.0 (13/02/05)

if ~isvector(X)
    flag = 0;
    idxEvent = [];
    
    fprintf('ERROR in function *get_transition_indices*: Does not support multi-dimensional input.\n')
    return
end %if
if ~islogical(X)
    flag = 0;
    idxEvent = [];
    
    fprintf('ERROR in function *get_transition_indices*: Input must be logical.\n')
    return
end %if

N = numel(X);
X = X(:); % -> [Nx1]vector
dX = diff(X);

beginEvent = find(dX == 1) + 1; %transition 0 -> 1
endEvent = find(dX == -1); %transition 1 -> 0

%evaluate vector bounds
if X(1) == 1
    beginEvent = [1; beginEvent];
end %if
if X(N) == 1
    endEvent = [endEvent; N];
end %if

%catenate output
idxEvent = [beginEvent endEvent];
end %fun