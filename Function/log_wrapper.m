function y = log_wrapper(x)
if x == 0
    y = nan;
elseif x > 0
    y = log(x);
else
    y = [];
end %if