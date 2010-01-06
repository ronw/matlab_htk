function gmm = train_gmm_htk(trdata, nmix, niter, verb, CVPRIOR, gmm0);
% gmmparams = train_gmm_htk(trdata, nmix, niter, verb, cvprior, gmm0);
%
% Train a GMM with diagonal covariance using HTK.
%
% Inputs:
% trdata - training data (cell array of training sequences, each
%                         column of the sequences arrays contains an
%                         observation)
% nmix   - number of mixture components.  Defaults to 3.
% niter  - number of EM iterations to perform.  Defaults to 10.
% verb   - set to 1 to output loglik at each iteration
%
% Outputs:
% gmmparams - structure containing hmm parameters learned from training
%             data (gmm.priors, gmm.means(:,1:nmix), gmm.covars(:,1:nmix))
%
% 2006-12-06 ronw@ee.columbia.edu

% Copyright (C) 2006-2007 Ron J. Weiss
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

% HRest complains bitterly if there are fewer than 3 training
% sequence, but since we are training a gmm we can cheat and steal
% the last two columns of trdata{1} and treat them as separate
% training sequences.
nseq = length(trdata);
if nseq < 3
  tmp = trdata{1};
  trdata{1} = tmp(:,1:end-2);
  trdata{nseq+1} = tmp(:,end-1);
  trdata{nseq+2} = tmp(:,end);
  nseq = nseq + 2;
end
[ndim, nobs(1)] = size(trdata{1});

% initial HMM parameters - only 1 state since we're learning a GMM.
hmm.emission_type = 'GMM';
hmm.nstates = 1;
hmm.transmat = log(0.9);
hmm.start_prob = 0;
hmm.end_prob = log(0.1);

% uniform prior
gmm.priors = log(ones(1, nmix)/nmix);
gmm.nmix = nmix;
gmm.covars = ones(ndim, nmix);

if nargin < 6 % | numel(gmm0) == 1 & gmm0 == 1
  gmm.means = kmeans(cat(2, trdata{:}), nmix, niter/2);
elseif exist('gmm0')
  if isstruct(gmm0) && gmm0.nmix == nmix
    gmm = gmm0;
  elseif size(gmm0, 2) == nmix
    gmm.means = gmm0;
  end
end

hmm.gmms = gmm;

hmm = train_hmm_htk(trdata, hmm, niter, verb, CVPRIOR);
gmm = hmm.gmms;

