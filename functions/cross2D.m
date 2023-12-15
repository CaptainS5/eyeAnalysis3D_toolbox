function crossP = cross2D(m1, m2)
% Input: matrices of the same size, each row is a 2D vector
% Output: vector having the cross products for each row in m1 and m2

crossP = [];
for ii = 1:size(m1, 1)
    crossP(ii, 1) = m1(ii, 1)*m2(ii, 2)-m1(ii, 2)*m2(ii, 1);
end

end