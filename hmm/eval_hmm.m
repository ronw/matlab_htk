function [loglik, lattice, alpha, beta, gamma] = eval_hmm(hmm, frameLogLike, maxRank, beamLogProb, do_backward, verb)
% [loglik, lattice] = eval_hmm(hmm, seq, rank, beam)
%
% Performs forward-backward inference on seq.  Does rank and beam
% pruning.  Assumes all hmm params are logprobs.
%
% 2008-08-11 ronw@ee.columbia.edu

% Copyright (C) 2006-2008 Ron J. Weiss
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


% no rank pruning by default
if nargin < 3
  maxRank = 0;
end

% No beam pruning by default.
if nargin < 4
  beamLogProb = -Inf;
end

if nargin < 5
  do_backward = true;
end

if nargin < 6
  verb = 0;
end

% Don't bother doing backward calculation if all we want is log
% likelihood.
if nargout < 2
  do_backward = false;
else
  do_backward = true;
end

zeroLogProb = -1e200;
hmm.transmat(hmm.transmat < zeroLogProb) = zeroLogProb;

% Verify type of observations.  Can be observed sequence or
% precomputed log likelihoods (i.e. for variational inference).
[nstates, nobs] = size(frameLogLike);
if nstates ~= hmm.nstates && nstates == size(hmm.means, 1)
  seq = frameLogLike;
  ndim = nstates;
  nstates = hmm.nstates;
  if strcmp(hmm.emission_type, 'gaussian')
    frameLogLike = lmvnpdf(seq, hmm.means, hmm.covars);
  elseif strcmp(hmm.emission_type, 'GMM')
    for s = 1:hmm.nstates
      frameLogLike(s,:) = eval_gmm(hmm.gmms(s), seq);
    end
  else
    error('Unknown HMM emission distribution.');
  end
end


%%%%%
% Forward
%%%%%
alpha = zeros(nstates, nobs) - Inf;
prevLatticeFrame = hmm.start_prob(:) + frameLogLike(:,1);
alpha(:,1) = prevLatticeFrame;
if verb >= 2
  fprintf('Starting forward pass...\n  frame 1: ll = %f\n', ...
      logsum(prevLatticeFrame))
end

for obs = 2:nobs
  if verb >= 2; tic; end

  idx = prune_states(prevLatticeFrame, maxRank, beamLogProb, verb);
  pr = hmm.transmat(idx,:)' + repmat(prevLatticeFrame(idx), [1, hmm.nstates])';
  prevLatticeFrame = logsum(pr, 2) + frameLogLike(:, obs);
  alpha(:,obs) = prevLatticeFrame;
  
  if verb >= 2
    T = toc;
    fprintf('  frame %d: ll = %f (%f sec, %d active states)\n', obs, ...
        logsum(prevLatticeFrame), T, length(idx));
  end
end
alpha(alpha <= zeroLogProb) = -Inf;

% Don't forget hmm.end_prob
% This double counts frameLogLike(:,end)!!
%nextLatticeFrame = hmm.end_prob(:) + frameLogLike(:,end);
nextLatticeFrame = hmm.end_prob(:);
loglik = logsum(prevLatticeFrame + nextLatticeFrame);
if isinf(loglik) || isnan(loglik)
  nextLatticeFrame = frameLogLike(:,end);
  loglik = logsum(prevLatticeFrame + nextLatticeFrame);
end

if verb
  fprintf('eval_hmm: log likelihood = %f\n', loglik)
end


if ~do_backward
  return
end

%%%%%
% Backward
%%%%%
beta = zeros(nstates, nobs) - Inf;
beta(:,nobs) = nextLatticeFrame;
if verb >= 2
  fprintf('Starting backward pass...\n  frame %d: ll = %f\n', nobs, ...
      logsum(nextLatticeFrame));
end

for obs = nobs-1:-1:1
  if verb >= 2; tic; end
     
  % Do HTK style pruning (p. 137 of HTK Book version 3.4).  Don't
  % bother computing backward probability if alpha*beta is more than a
  % certain distance from the total log likelihood.
  idx = prune_states(nextLatticeFrame + alpha(:,obs+1), 0, -20, verb);
  %idx = prune_states(nextLatticeFrame + alpha(:,obs+1), 10, -Inf, verb);  

  pr = hmm.transmat(:,idx) + repmat(nextLatticeFrame(idx) ...
      + frameLogLike(idx,obs+1), [1, hmm.nstates])';
  nextLatticeFrame = logsum(pr, 2);
  beta(:,obs) = nextLatticeFrame;
  
  if verb >= 2
    T = toc;
    fprintf('  frame %d: ll = %f (%f sec, %d active states)\n', obs, ...
        logsum(nextLatticeFrame), T, length(idx));
  end
end
beta(beta <= zeroLogProb) = -Inf;

gamma = alpha + beta;
lattice = exp(gamma - repmat(logsum(gamma, 1), [hmm.nstates 1]));



function [state_idx thresh] = prune_states(latticeFrame, ...
    maxRank, beamLogProb, verb)
zeroLogProb = -1e200;
frameLogProb = logsum(latticeFrame);

% Beam pruning
threshLogProb = frameLogProb + beamLogProb;

% Rank pruning
if maxRank > 0
  % How big should our rank pruning histogram be?
  histSize = 3*length(latticeFrame);

  tmp = latticeFrame(:);
  min_tmp = min(tmp(tmp > zeroLogProb)) - 1;
  tmp(tmp <= zeroLogProb) = min_tmp;
  
  [hst cdf] = hist(tmp, histSize);
    
  % Want to look at the high ranks of the last frame.
  hst = hst(end:-1:1);
  cdf = cdf(end:-1:1);
    
  hst = cumsum(hst);
  idx = min(find(hst >= maxRank));
  rankThresh = cdf(idx);
      
  % Only change the threshold if it is stricter than the beam
  % threshold.
  threshLogProb = max(threshLogProb, rankThresh);
    
  if verb >= 3
    fprintf('beam thresh = %f, rank thresh = %f, final thresh = %f\n', ...
        frameLogProb+beamLogProb, rankThresh, threshLogProb);
  end
end
    
% Which states are active?
state_idx = find(latticeFrame >= threshLogProb);

