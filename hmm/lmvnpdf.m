function lpr = lmvnpdf(obs, mu, cv);
% lpr = lmvnpdf(obs, mu, cv)
%
% Return the log probability of obs under the Gaussian distribution
% parameterized by mu and cv.  
%
% obs is an array of column vectors (DxO).  mu and cv are also arrays
% of column vectors (this only supports diagonal covariance matrices,
% so mu and cv must both be DxC where C is the number of Gaussians).
% lpr will be a CxO matrix where each row contains the log probability
% of each observation given one of the C Gaussians.
%
% 2006-06-19 ronw@ee.columbia.edu

if nargin < 3
  cv = 1;
end

[ndim, nobs] = size(obs);
[ndim_mu, nmu] = size(mu);
[ndim_cv, ncv] = size(cv);

% make sure all the arguments are consistent
if ndim ~= ndim_mu
  error('lmvnpdf: obs and mu must have the same number of dimensions.');
end
if nmu ~= ncv 
  if ncv == 1
    % use the same diagonal covariance for each distribution
    cv = repmat(cv, 1, nmu);
  else
    error('lmvnpdf: mu and cv must have the same number of components.');
  end
end 
ngauss = nmu;

% are covariances scalar?
if ndim_cv == 1
  cv = repmat(cv, ndim, 1);
end


% vectorized like there is no tomorrow:
% ||x-y|| = x'x - 2*x'y + y'y
% x'x = repmat(sum(x.^2),xc,1);
% y'y = repmat(sum(y.^2),yc,1);
% 
% but here, its ||(x-y)/cv||:
%  where cv has the same size as x (mu), but not the same as y (obs)... 

lpr = -0.5*(repmat(sum((mu.^2)./cv, 1)' + sum(log(cv))', [1 nobs]) ...
    - 2*(mu./cv)'*obs + (1./cv)'*(obs.^2) + ndim*log(2*pi));
