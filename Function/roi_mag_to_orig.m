function output = roi_mag_to_orig(input,actExp,shape)
fun = @(x)(x+0.5*actExp-0.5)/actExp;

switch shape
    case {'Rectangle', 'Ellipse'}
        output = [fun(input(1:2)) input(3:4)/actExp];
    case 'Polygon'
        output = fun(input);
end %switch
end %fun