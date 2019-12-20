function y = prod_log(x1,x2)
if isnan(x1) || isnan(x2)
    y = nan;
else
    y = x1+x2;
end %if