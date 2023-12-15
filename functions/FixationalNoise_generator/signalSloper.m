function y = signalSloper(x,slope)
% expects row vector signals. To slope r multiple independent signals,
% provide an r x N input matrix.

% if column vector is provided, silently correct orientation for this
% functions (and ensure output is also a column vector)
qTrans = size(x,2)==1;
if qTrans
    x = x.';
end

[r,N] = size(x);
numUniquePts = ceil((N+1)/2);

idx = 1:numUniquePts;

X = fft(x,[],2);
X = X(:,idx).*[zeros(r,1) repmat(idx(1:end-1).^(-slope/2),r,1)];   % slope/2 as we're working with amplitude here, not power (so sqrt, which is /2 in the exponent)
if rem(N, 2)    % odd N excludes Nyquist point
    X = [X conj(X(:,end  :-1:2))];
else            % even N includes Nyquist point
    X = [X conj(X(:,end-1:-1:2))];
end
y = real(ifft(X,[],2));
y = bsxfun(@minus,y,mean(y,2));
y = bsxfun(@rdivide,y,std(y,[],2));

if qTrans
    y = y.';
end