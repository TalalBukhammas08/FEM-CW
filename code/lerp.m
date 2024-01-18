function [output] = lerp(x, c)
%Linear interpolation
%   Linearly interpolate vector c at value x
    a = floor(x);
    b = ceil(x);

    dy = c(b, :) - c(a, :);
    dx = x - a;

    output = c(a, :) + dy/1 * dx;
end

