function s = logsum(array, dim)
% s = logsum(array, dim)
%
% returns log(sum(exp(array), dim)) minimizing possibility of over/underflow


if nargin < 2
  amax = max(array(:));
  s = log(sum(exp(array - amax))) + amax;
else
  amax = max(array,[],dim);
  rep = ones(1, length(size(array)));
  rep(dim) = size(array,dim);
  s = log(sum(exp(array - repmat(amax, rep)), dim)) + amax;
end
