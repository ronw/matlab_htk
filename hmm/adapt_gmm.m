function gmm = adapt_gmm(pgmm, trdata, niter, adapt_weight, verb, MINCV)
% gmmparams = adapt_gmm(prior_gmm, trdata, nmix, niter,
%                       adapt_weight, verb, min_cv)
%
% Adapt the given prior_gmm to the given training data using MAP
% adaptation.
%
% Inputs:
% prior_gmm    - initial GMM parameters to adapt.
% trdata       - training data (cell array of training sequences, each
%                column of the sequences arrays contains an observation)
% niter        - number of EM iterations to perform.  Defaults to 10.
% adapt_weight - weight of initial GMM in update equations (see HTK
%                book section 9.3).  If adapt_weight is a vector, the
%                first element corresponds to the adaptation weight
%                for the Gaussian means (tau), and the second
%                correponse to the weight for the covariances (alpha).
%                Defaults to 10 (i.e. do not update covar parameters).
% verb         - set to 1 to output loglik at each iteration
% min_cv       - minimum covariance to avoid overfitting.  Defaults to 1.
%
% Outputs:
% gmmparams    - structure containing hmm parameters learned from training
%                data (gmm.priors, gmm.means(:,1:nmix), gmm.covars(:,1:nmix))
%
% 2009-06-15 ronw@ee.columbia.edu

DEBUG = false;

if nargin < 3
  niter = 10;
end
if nargin < 4
  adapt_weight = 10;
end
if nargin < 5
  verb = 0;
end
if nargin < 6
  MINCV = 1;
end

if ~iscell(trdata)
  trdata = {trdata};
end

ndata = length(trdata);

T = adapt_weight(1);
adapt_covars = false;
if length(adapt_weight) == 2
  adapt_covars = true;
  A = adapt_weight(2);
end

% Initialization
gmm = pgmm;
ppriors = exp(pgmm.priors);
nmix = pgmm.nmix;

if size(trdata{1}, 1) ~= size(gmm.means, 1)
  error(['Dimensionality of initial GMM not compatible with given ' ...
        'training data']);
end
ndim = size(trdata{1}, 1);

% sufficient statistics
norm = zeros(size(gmm.priors));
means = zeros(size(gmm.means));
covars = zeros(size(gmm.covars));

last_loglik = -Inf;
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
    fprintf('Iteration %d: log likelihood = %f\n', iter, loglik)
    
    if DEBUG
      figure(1)
      plot_on_same_axes(pgmm.priors, gmm.priors)
      figure(2)
      cax = [-80 -10];
      subplot(211); imagesc(pgmm.means); axis xy; colorbar; caxis(cax);
      subplot(212); imagesc(gmm.means);  axis xy; colorbar; caxis(cax);
      figure(3)
      cax = [0 100];
      subplot(211); imagesc(pgmm.covars); axis xy; colorbar; caxis(cax);
      subplot(212); imagesc(gmm.covars);  axis xy; colorbar; caxis(cax);
      drawnow
    end
  end

  % Check for convergence
  if abs(loglik - last_loglik) < 1e-5
    fprintf('Converged at iteration %d\n', iter)
    break
  end
  last_loglik = loglik;
  
  % M-step
  % based on Huang, Acero, Hon, "Spoken Language Processing", p. 453 - 454
  npriors = (ppriors - 1 + norm) ./ sum(ppriors - 1 + norm);
  npriors(npriors < 0) = 0;
  gmm.priors = log(npriors);
  nrm = repmat(norm, [ndim 1]);
  gmm.means = (T * pgmm.means + means) ./ (T + nrm);
  if adapt_covars
    gmm.covars = ((A - 1) * pgmm.covars ...
        + T * (gmm.means - pgmm.means).^2 ...
        + (covars - 2*gmm.means.*means) .* nrm + gmm.means.^2) ...
        ./ (A - 1 + nrm);
    gmm.covars(gmm.covars < MINCV) = MINCV;
  end
end
