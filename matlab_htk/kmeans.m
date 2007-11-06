function codebook = kmeans(trdata, nclust, niter)
% codebook = kmeans(data, nclust, niter)
%
% Learns a k-means codebook from data with nclust codewords.
%
% 2006-12-07 ronw@ee.columbia.edu

if nargin < 2
  nclust = 10;
end
if nargin < 3
  niter = 5;
end

[ndim, nobs] = size(trdata);

% init using k-means:
rp = randperm(nobs);
% in case there aren't enough observations...
rp = repmat(rp,1,ceil(nclust/nobs));
codebook = trdata(:,rp(1:nclust));
for i = 1:niter
  % ||x-y || = x^Tx -2x^Ty + y^Ty
  % x^Tx = repmat(sum(x.^2),xc,1);
  % y^Ty = repmat(sum(y.^2),yc,1);
  D = repmat(sum(trdata.^2,1)',1,nclust) - 2*trdata'*codebook ...
      + repmat(sum(codebook.^2,1),nobs,1);
  
  %assign each data point to one of the clusters
  [tmp idx] = min(D,[],2);
  
  for k = 1:nclust
    if sum(idx == k) > 0
      codebook(:,k) = mean(trdata(:,idx == k),2);
    end
  end
end
