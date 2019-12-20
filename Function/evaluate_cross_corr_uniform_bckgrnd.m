function [paramEst,paramSE] = evaluate_cross_corr_uniform_bckgrnd(Ccum,r,showResult)
r = rowvec(r);
Ccum = rowvec(Ccum);

%% define model
interactiveCorr = @(param,r)param(2)*(1-exp(-r.^2/(4*param(3)^2)));
nonInteractiveCorr = @(param,r)param(1)*pi*r.^2;
model = @(param,r)feval(interactiveCorr,param,r) + ...
    feval(nonInteractiveCorr,param,r);

%% initial guess
% win = 10;
% for N = 1:2
%     [theta{N},thetaSE{N},residual{N}] = piecewise_poly(r.^2,Ccum,N,win);
% 
% AIC(N,:) = 2*(N+1) + win*(log(2*pi*sum(residual{N}.^2)/win)+1) + 2*(N+1)*(N+2)/(win-N-2);
% end
% AIC = exp(bsxfun(@minus,min(AIC),AIC)/2);
% AIC = bsxfun(@rdivide,AIC,sum(AIC));
% 
% [h,p,ci] = vartest2(residual{1},residual{2},'Tail','right');

% for i = numel(r):-1:1
%     n(i) = polydeg(r(i:end).^2,Ccum(i:end));
% end
% n = [inf(1,floor(5/2)) running_1dim_median_filter(n,5) inf(1,floor(5/2))];
% take = (n == 1);
take = r > r(end-10);
x0 = polyfit(pi*r(take).^2,Ccum(take),1); %(=rho alpha)
x0 = [x0 0.01];
lb = [0 0 0.005];
ub = [inf 1 0.2];

%%
fitOptions = ...
    optimset(...
    'TolFun', 10^-12,...
    'TolX', 10^-12,...
    'MaxIter', 1000,...
    'MaxFunEvals', 3000);
[paramEst,~,resid,~,~,~,J] = ...
    lsqcurvefit(model,x0,r,Ccum,lb,ub,fitOptions);

paramSE = rowvec(diff(nlparci(paramEst,resid,'jacobian',J),[],2)/3.92);
SST = sum(bsxfun(@minus,Ccum,mean(Ccum)).^2);
SSR = sum((Ccum-model(paramEst,r)).^2);
rSquare = 1-SSR./SST;

if showResult
    figure('Color',[1 1 1]);
    ax(1) = axes(...
        'Position',[0.15 0.4 0.8 0.45],...
        'XTickLabel','',...
        'NextPlot','add');
    plot(ax(1),r.^2,Ccum,'ko')
    plot(ax(1),r.^2,feval(model,paramEst,r),'y-','Linewidth',3)
    plot(ax(1),r.^2,feval(interactiveCorr,paramEst,r),'r--','Linewidth',2);
    plot(ax(1),r.^2,feval(nonInteractiveCorr,paramEst,r),'b--','Linewidth',2);
    
    title(ax(1),sprintf('\\alpha = %.1e\\pm%.1e;\n\\rho[µm^{-2}] = %.1e\\pm%.1e (R^2 = %.2f)\n\\sigma[µm] = %.1e\\pm%.1e',...
        paramEst(2), paramSE(2), paramEst(1), paramSE(1), rSquare, paramEst(3), paramSE(3)))
    ylabel(ax(1),'Average Particle Count')
    
    %residuals
    ax(2) = axes(...
        'Position',[0.15 0.15 0.8 0.2],...
        'NextPlot','add');
    stem(ax(2),r.^2,resid,'k')
    ylabel(ax(2),'Residuals')
    xlabel(ax(2),'r^2 [µm^2]')
    
    axis(ax,'tight')
    linkaxes(ax,'x')
end %if
end %fun