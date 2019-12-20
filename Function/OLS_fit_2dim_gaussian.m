function [thetaEst,resnorm,residual,exitflag,output,lambda,jacobian] = ...
    OLS_fit_2dim_gaussian(xdata,ydata,varargin)
%written by
%C.P.Richter
%Division of Biophysics / Group J.Piehler
%University of Osnabrueck

%input validation
objInputParser = inputParser;

%% theta = [volume std_i std_j angle_with_j_axis offset]
addParamValue(objInputParser,...
    'Theta0', [1 1 0], @(x)isvector(x));

%%
addParamValue(objInputParser,...
    'Lb', -[inf inf inf], @(x)isvector(x));

%%
addParamValue(objInputParser,...
    'Ub', [inf inf inf], @(x)isvector(x));

%%
addParamValue(objInputParser,...
    'Options', optimset(...
    'Display','off',...
    'Algorithm', 'levenberg-marquardt',...
    'MaxFunEvals',1000,...
    'TolFun', 10^-12,...
    'TolX', 10^-12,...
    'Diagnostics', 'off'), @(x)isstruct(x));

%%
parse(objInputParser,varargin{:});
inputs = objInputParser.Results;

[thetaEst,resnorm,residual,exitflag,output,lambda,jacobian] = ...
    lsqcurvefit(@model_2dim_gaussian,...
    inputs.Theta0,xdata,ydata,inputs.Lb,inputs.Ub,inputs.Options);

    function yhat = model_2dim_gaussian(theta,xdata)
        %model of 2dim symmetric gaussian
        %input:
        %theta = [volume std offset]
        %xdata = [pos_i pos_j]
        
        yhat = theta(1)/2/pi/theta(2)^2*...
            exp(-0.5*(xdata(:,1).^2+xdata(:,2).^2)/theta(2)^2)+theta(3);
    end %nested0
end %fun