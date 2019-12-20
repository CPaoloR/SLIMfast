function y = sum_log(x,dim)
d = size(x);
if dim == 1
    y = x(1,:);
    if d(1) > 1
        for idx = 2:d(1);
            y = arrayfun(@bin_sum_log,x(idx,:),y);
        end %for
    end %if
elseif dim == 2
    x = x';
    y = x(1,:);
    if d(2) > 1
        for idx = 2:d(2);
            y = arrayfun(@bin_sum_log,x(idx,:),y);
        end %for
    end %if
    y = y';
else
end %if
end %fun

function y = bin_sum_log(x1,x2)
if isnan(x1) || isnan(x2)
    if isnan(x1)
        y = x2;
    else
        y = x1;
    end %if
else
    if x1 > x2
        y = x1 + log_wrapper(1+exp(x2-x1));
    else
        y = x2 + log_wrapper(1+exp(x1-x2));
    end %if
end %if
end %fun