function [m] = insertzero(in, n)
%Insert zeros into in, with indices defined in n
n = sort(n);
m = zeros(length(in)+length(n), 1);
a = 1;
b = 1;
    for i=1:1:length(m)
        if(a < length(n) || a == length(n))
            if(i == n(a))
                m(i) = 0;
                a = a + 1;
            else
                m(i) = in(b);
                b = b + 1;
            end
        else
            m(i) = in(b);
            b = b + 1;
        end
    end
end

