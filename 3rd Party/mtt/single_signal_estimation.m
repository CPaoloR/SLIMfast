function estimate = single_signal_estimation(im,settings,listGuess)
% EN/ sub-pixel estimate of the peak position by Gauss Newton regression
% liste_info_param is a line of the matrix liste_detect
% wn odd

%%% version 11 07 05

%crop particle surroundings
Pi = listGuess(2) ;
Pj = listGuess(3) ;
di = (1:settings.winY)+Pi-floor(settings.winY/2) ;
dj = (1:settings.winX)+Pj-floor(settings.winX/2) ;
im_part = im(di, dj) ;

%choose detection algorithm
switch settings.locModel
    case 'Fixed'
        estimate = fixedGaussMLE;
    case 'Fitted'
        options = optimset(...
            'Algorithm', 'interior-point',...
            'MaxIter', settings.maxIter,...
            'TolX', 10^settings.termTol,...
            'Display', 'off',...
            'UseParallel', 'always');
        
        %[i j psfstd]
        guess = [0,0,settings.radiusPSF];
        estimate = gaussMLE;
    case 'Astigmatic'
        options = optimset(...
            'Algorithm', 'interior-point',...
            'MaxIter', settings.maxIter,...
            'TolX', 10^settings.termTol,...
            'Display', 'off',...
            'UseParallel', 'never');
        
        %[i j psfstd_i psfstd_j psfcov]
        guess = [0,0,settings.radiusPSF,settings.radiusPSF,0];
        estimate = ellipticGaussMLE;
end %switch

%% Models
    function output = fixedGaussMLE
        
        %set initial random values
        i = 0.0 ;
        j = 0.0 ;
        di = 1 ;
        dj = 1 ;
        sig2 = inf ;
        
        iter = 0 ;
        refine = true;
        while refine
            [i, j, di, dj, alpha, sig2, m] = ...
                deplt_GN_estimation (i, j, im_part, sig2, di, dj) ;
            iter = iter + 1 ;
            
            refine = max([abs(di), abs(dj)]) > 10^settings.termTol ;
            if iter > settings.maxIter
                refine = false(1) ;
            end%if
            
            %% test if fit sadisfies constraints
            flag = ~((i < -1*settings.maxPosRef) ||...
                (i > settings.maxPosRef) || ...
                (j < -1*settings.maxPosRef) ||...
                (j > settings.maxPosRef)) ;
            refine = refine & flag ;
            
        end%while
        
        %[flag y x z signal background noise psfstd]
        output = [flag Pi+i Pj+j 0 alpha m sig2 settings.radiusPSF];
        
        function [n_i, n_j, di, dj, alpha, sig2, m] = ...
                deplt_GN_estimation(p_i, p_j, x, sig2init, p_di, p_dj)
            
            %%  p_di, p_dj les precedents deplacements
            %% qui ont conduit a p_r, p_i, p_j
            
            i0 = p_i ;
            j0 = p_j ;
            
            verif_crit = 1 ;
            pp_i = i0 - p_di ;
            pp_j = j0 - p_dj ;
            
            [wn_i, wn_j] = size(x) ;
            N = wn_i * wn_j ;
            refi = 0.5 + (0:(wn_i-1)) - wn_i/2 ;
            refj = 0.5 + (0:(wn_j-1)) - wn_j/2 ;
            
            %% on boucle, en diminuant les deplacements
            %% tand que le nouveau critere en plus grand
            again = true(1) ;
            while (again)
                
                i = refi - i0 ;
                j = refj - j0 ;
                ii = i' * ones(1,wn_j) ;
                jj = ones(wn_i,1) * j ;
                
                %% puissance unitaire
                iiii = ii.*ii ;
                jjjj = jj.*jj ;
                iiii_jjjj = iiii + jjjj ;
                g = (1/(sqrt(pi)*settings.radiusPSF))*...
                    exp(-(1/(2*settings.radiusPSF^2))*(iiii_jjjj)) ;
                gc = g - sum(g(:))/N ;
                Sgc2 = sum(gc(:).^2) ;
                %g_div_sq_r0 = inv(settings.radiusPSF^2) * g ;
                g_div_sq_r0 = settings.radiusPSF^2 \ g ; %CPR
                %% alpha estime MV
                if (Sgc2 ~= 0)
                    alpha = sum(sum(x .* gc)) / Sgc2 ;
                else
                    alpha = 0 ;
                end%if
                %% m estime MV
                x_alphag = x - alpha.*g ;
                m = sum(sum(x_alphag))/N ;
                
                err = x_alphag - m ;
                
                %% critere avant deplacement
                sig2 = sum(sum(err.^2)) / N ;
                
                if (verif_crit) && (sig2 > sig2init)
                    p_di = p_di / 10.0 ;
                    p_dj = p_dj / 10.0 ;
                    
                    i0 = pp_i + p_di ;
                    j0 = pp_j + p_dj ;
                    
                    if (max([abs(p_di), abs(p_dj)]) < 10^settings.termTol)
                        n_i = p_i ;
                        n_j = p_j ;
                        di = 0 ;
                        dj = 0 ;
                        return ;
                    end%if
                else
                    again = false(1) ;
                end%if
                
            end%while
            
            %% der_g
            der_g_i0 =  ii .* g_div_sq_r0 ;
            der_g_j0 =  jj .* g_div_sq_r0 ;
            
            %% derder_g
            %derder_g_i0 = (-1 + inv(settings.radiusPSF^2)*iiii) .* g_div_sq_r0 ;
            %derder_g_j0 = (-1 + inv(settings.radiusPSF^2)*jjjj) .* g_div_sq_r0 ;
            derder_g_i0 = (-1 + settings.radiusPSF^2\iiii) .* g_div_sq_r0 ; %CPR
            derder_g_j0 = (-1 + settings.radiusPSF^2\jjjj) .* g_div_sq_r0 ; %CPR
            
            %% der_J /2
            der_J_i0 = alpha * sum(sum(der_g_i0 .* err)) ;
            der_J_j0 = alpha * sum(sum(der_g_j0 .* err)) ;
            
            %% derder_J /2
            derder_J_i0 = alpha * sum(sum(derder_g_i0 .* err)) - alpha^2 * sum(sum(der_g_i0.^2)) ;
            derder_J_j0 = alpha * sum(sum(derder_g_j0 .* err)) - alpha^2 * sum(sum(der_g_j0.^2)) ;
            
            %% deplacement par Gauss-Newton
            di = - der_J_i0 / derder_J_i0 ;
            dj = - der_J_j0 / derder_J_j0 ;
            
            n_i = i0 + di ;
            n_j = j0 + dj ;
            
        end %function
        
    end
    function output = gaussMLE
        N = settings.winY * settings.winX ;
        refi = 0.5 + (0:(settings.winY-1)) - settings.winY/2 ;
        refj = 0.5 + (0:(settings.winX-1)) - settings.winX/2 ;
        
        alpha = [];
        m = [];
        
        [x,sig2,flag] = fmincon(...
            @modelfun,...
            guess,...
            [],[],[],[],...
            [-1*settings.maxPosRef -1*settings.maxPosRef ...
            settings.lowerBoundPSF*settings.radiusPSF],...
            [settings.maxPosRef settings.maxPosRef ...
            settings.upperBoundPSF*settings.radiusPSF],...
            [],...
            options);
        
        %[flag y x z signal background noise psfstd]
        output = [flag>0 Pi+x(1) Pj+x(2) 0 alpha m sig2 x(3)];
        
        function sig2 = modelfun(x)
            i = refi - x(1) ;
            j = refj - x(2) ;
            ii = i' * ones(1,settings.winX) ;
            jj = ones(settings.winY,1) * j ;
            
            %% model
            iiii = ii.*ii ;
            jjjj = jj.*jj ;
            iiii_jjjj = iiii + jjjj ;
            g = (1/(sqrt(pi)*x(3)))*...
                exp(-(1/(2*x(3)^2))*(iiii_jjjj)) ;
            gc = g - sum(g(:))/N ;
            Sgc2 = sum(gc(:).^2) ;
            
            %% mean amplitude
            alpha = sum(sum(im_part .* gc)) / Sgc2 ;
            
            %% offset
            x_alphag = im_part - alpha.*g ;
            m = sum(sum(x_alphag))/N ;
            
            %% residuals
            err = x_alphag - m ;
            
            %% noise power
            sig2 = sum(sum(err.^2)) / N ;
            
        end
    end
    function output = ellipticGaussMLE
        N = settings.winY * settings.winX ;
        refi = 0.5 + (0:(settings.winY-1)) - settings.winY/2 ;
        refj = 0.5 + (0:(settings.winX-1)) - settings.winX/2 ;
        
        alpha = [];
        m = [];
        [x,sig2,flag] = fmincon(@modelfun,guess,[],[],[],[],...
            [-1*settings.maxPosRef -1*settings.maxPosRef ...
            settings.lowerBoundPSF*settings.radiusPSF ...
            settings.lowerBoundPSF*settings.radiusPSF],...
            [settings.maxPosRef settings.maxPosRef ...
            settings.upperBoundPSF*settings.radiusPSF ...
            settings.upperBoundPSF*settings.radiusPSF],...
            [],options);
%         [x,sig2,flag] = fminunc(@modelfun,guess,options);
        
        %[flag i j z signal background noise psfstd_i psfstd_j]
        output = [flag>0 Pi+x(1) Pj+x(2) 0 alpha m sig2 x(3) x(4)];
        
        function sig2 = modelfun(x)
            i = refi - x(1) ;
            j = refj - x(2) ;
            ii = i' * ones(1,settings.winX) ;
            jj = ones(settings.winY,1) * j ;
                                   
            invSigI = 1/x(3);
            invSigJ = 1/x(4);
            z = invSigI*invSigI*ii.*ii + invSigJ*invSigJ*jj.*jj;            
            g = sqrt(invSigI*invSigJ)/sqrt(pi)*exp(-0.5*z);            
            gc = g - sum(g(:))/N ;
            Sgc2 = sum(gc(:).^2) ;
            
            %% mean amplitude
            alpha = sum(sum(im_part .* gc)) / Sgc2 ;
            
            %% offset
            x_alphag = im_part - alpha.*g ;
            m = sum(sum(x_alphag))/N ;
            
            %% residuals
            err = x_alphag - m ;
            
            %% noise power
            sig2 = sum(sum(err.^2)) / N ;
            
        end
    end
end %fun