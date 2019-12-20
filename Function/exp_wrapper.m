function y = exp_wrapper(x)
if isnan(x)
    y = 0;
else
    y = exp(x);
end %if