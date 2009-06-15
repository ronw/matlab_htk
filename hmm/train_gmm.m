function gmm = train_gmm(trdata, nmix, niter, verb, CVPRIOR, mu0);
% gmmparams = train_gmm(trdata, nmix, niter, verb, cvprior, mu0);
%
% Train a GMM with diagonal covariance.
%
% Inputs:
% trdata - training data (cell array of training sequences, each
%                         column of the sequences arrays contains an
%                         observation)
% nmix    - number of mixture components.  Defaults to 3.
% niter   - number of EM iterations to perform.  Defaults to 10.
% verb    - set to 1 to output loglik at each iteration
% cvprior - 
%
% Outputs:
% gmmparams - structure containing hmm parameters learned from training
%             data (gmm.priors, gmm.means(:,1:nmix), gmm.covars(:,1:nmix))
%
% 2007-11-06 ronw@ee.columbia.edu

if nargin < 2
  nmix = 3;
end
if nargin < 3
  niter = 10;
end

if nargin < 4
  verb = 0;
end

% prior on observation covariances to avoid overfitting:
if nargin < 5
  CVPRIOR = 1;
end

if ~iscell(trdata)
  trdata = {trdata};
end

ndata = length(trdata);


% Initialization
gmm.priors = log(ones(1, nmix)/nmix);
gmm.nmix = nmix;

if nargin < 6 | numel(mu0) == 1 & mu0 == 1
  gmm.means = kmeans(cat(2, trdata{:}), nmix, niter/2);
else
  if size(mu0, 2) == nmix
    gmm.means = mu0;
  end
end

ndim = size(trdata{1}, 1);
%gmm.covars = ones(ndim, nmix);
gmm.covars(:,1:nmix) = repmat(var(trdata{1}')', [1 nmix]);


% sufficient statistics
norm = zeros(size(gmm.priors));
means = zeros(size(gmm.means));
covars = zeros(size(gmm.covars));

last_loglik = 0;
for iter = 1:niter
  % E-step
  loglik = 0;
  norm(:) = 0;
  means(:) = 0;
  covars(:) = 0;
  for n = 1:ndata
    curr_data = trdata{n};
    [ll, posteriors] = eval_gmm(gmm, curr_data);

    loglik = loglik + sum(ll);
    
    norm = norm + sum(posteriors, 2)';
    means = means + curr_data * posteriors';
    covars = covars + curr_data.^2 * posteriors';
  end

  if verb,
    fprintf('Iteration %d: log likelihood = %f\n', iter, loglik);
  end

  % Check for convergence
  if abs(loglik - last_loglik) < 1e-5
    break
  end
  last_loglik = loglik;
  
  % M-step
  gmm.priors = log(norm/sum(norm));

  nrm = repmat(1./norm, [ndim 1]);
  gmm.means = means .* nrm;
  gmm.covars = (covars - 2*gmm.means.*means) .* nrm + gmm.means.^2;
  gmm.covars(gmm.covars < CVPRIOR) = CVPRIOR;
end
