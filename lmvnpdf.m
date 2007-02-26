function lpr = lmvnpdf(obs, mu, cv, SPEEDTEST);
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

if nargin < 4
  SPEEDTEST = 0;
end

[ndim, nobs] = size(obs);
[ndim_mu, nmu] = size(mu);
[ndim_cv, ncv] = size(cv);

% make sure all the arguments are in agreement
if ndim ~= ndim_mu
  error('obs and mu must have the same number of dimensions.');
end
if nmu ~= ncv 
  if ncv == 1
    % use the same diagonal covariance for each distribution
    cv = repmat(cv, 1, nmu);
  else
    error('mu and cv must have the same number of components.');
  end
end 

% are covariances scalar?
if ndim_cv == 1
  cv = repmat(cv, ndim, 1);
end

ngauss = nmu;

lpr = zeros(ngauss, nobs);
%if nobs > ngauss
% informal tests have shown that it is almost always faster to loop
% over the gaussians:
if 1
  for g = 1:ngauss
    gcv = cv(:,g)';
    dzm = obs - repmat(mu(:,g), 1, nobs);
    lpr(g,:) = -0.5*((1./gcv)*dzm.^2 + sum(log(gcv)))';
  end
else
  slcv = sum(log(cv));
  icv = 1./cv;
  for o = 1:nobs
    dzm = repmat(obs(:,o), 1, size(mu,2)) - mu;
    lpr(:,o) = -0.5*(diag(icv'*(dzm).^2)' + slcv);
  end
end

lpr = lpr - 0.5*ndim*log(2*pi);

if SPEEDTEST 
  ntest = 100; tlg = 0; tlo = 0; max_error = 0;
  for test = 1:ntest
    tic
    lprlg = zeros(ngauss, nobs);
    for g = 1:ngauss
      gcv = cv(:,g)';
      dzm = obs - repmat(mu(:,g), 1, nobs);
      lprlg(g,:) = -0.5*((1./gcv)*dzm.^2 + sum(log(gcv)))';
    end
    T = toc;
    tlg = tlg + T/ntest;
    
    lprlo = zeros(ngauss, nobs);
    slcv = sum(log(cv));
    icv = 1./cv;
    for o = 1:nobs
      dzm = repmat(obs(:,o), 1, size(mu,2)) - mu;
      lprlo(:,o) = -0.5*(diag(icv'*(dzm).^2)' + slcv);
    end
    T = toc;
    tlo = tlo + T/ntest;

    max_error = max(max_error, max(max(abs(lprlo-lprlg))));
  end
  
  disp(['Time to loop over gaussians = ' num2str(tlg)]);
  disp(['Time to loop over observations = ' num2str(tlo)]);
  disp(['Maximum error = ' num2str(max_error)]);
end
