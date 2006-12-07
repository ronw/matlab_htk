function [pr, mlg, p, mmserecon]= eval_gmm(gmm, data)
% function [logprob, mlgauss, mixprob, recon] = eval_gmm(gmm, data)
%
% Evaluate the log probability of each column of data given GMM gmm.
% mlgauss contains the index of the most likely gaussian in the GMM
% for each data point.  mixprob contains the log probs of each
% gaussian in the GMM for each data point.  recon contains the MMSE
% reconstruction of data given the GMM.
%
% 2005-11-20 ronw@ee.columbia.edu

[ndim, ndat] = size(data);

p = zeros(gmm.nmix, ndat);
pr = zeros(1,ndat)-Inf;
for k = 1:gmm.nmix
  cv = gmm.covars(:,k);
  dzm = data - repmat(gmm.means(:,k),1,ndat);
  p(k,:) = log(gmm.priors(k)) - .5*((1./cv')*dzm.^2 + ndim*log(2*pi) ...
                                 + sum(log(cv')));
  pr = logsum([pr; p(k,:)], 1);
end

[mlg tmp] = ind2sub(size(p), find(p == repmat(max(p),gmm.nmix,1)));

if nargout >= 4
  % normalize p
  p = p-repmat(logsum(p,1), gmm.nmix, 1);

  mmserecon = gmm.means*exp(p);
end

