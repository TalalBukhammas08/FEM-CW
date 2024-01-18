function [m] = removerowcolumn(in, n, flag)
%Remove rows, columns or both from in. (n is vector of indices).
%This is to apply boundary conditions
%   0 = Rows, 1 = Columns, 2 = Both
    n = sort(n);
    m = in;
    if(flag==0 || flag==2)
        for i=1:length(n)
           m(n(i)-i+1, :) = [];
        end
    end
    in = m;
    if(flag==1 || flag==2)
        m = in;
        for i=1:length(n)
           m(:, n(i)-i+1) = [];
        end
    end
end