function output = roi_orig_to_mag(input,actExp,shape)
fun = @(x)(x-0.5)*actExp+0.5;

switch shape
    case {'Rectangle', 'Ellipse'}
        output = [fun(input(1:2)) input(3:4)*actExp];
    case 'Polygon'
        output = fun(input);
end %switch
end %fun