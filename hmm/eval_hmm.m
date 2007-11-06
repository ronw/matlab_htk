function [loglik, lattice] = eval_hmm(hmm, seq, maxRank, beamLogProb, do_backward, verb)
% [loglik, lattice] = eval_hmm(hmm, seq, rank, beam)
%
% Performs forward-backward inference on seq.  Does rank and beam
% pruning.  Assumes all hmm params are logprobs.
%
% 2007-02-26 ronw@ee.columbia.edu

% Copyright (C) 2007 Ron J. Weiss
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

zeroLogProb = -1e200;

% no rank pruning by default
if nargin < 3
  maxRank = 0;
end

% no beam pruning by default
if nargin < 4
  beamLogProb = -Inf;
end

if nargin < 5
  do_backward = 1;
end

if nargin < 6
  verb = 0;
end

% don't bother doing backward calculation if all we want is log
% likelihood
if nargout < 2
  do_backward = 0;
end


% how big should our rank pruning histogram be?
histSize = 1000;

[ndim, nobs] = size(seq);


%%%
% fill in the lattice...

% Do it HTK style - backward, then forward

if do_backward 

  nextLatticeFrame = hmm.end_prob(:);
  nextFrameLogProb = logsum(nextLatticeFrame(nextLatticeFrame > zeroLogProb));

  if nargout > 1
    lattice = repmat(zeroLogProb, [hmm.nstates, nobs]);
    lattice(:, end) = nextLatticeFrame;
  end

  if verb >= 2
    disp('Starting backward pass...');
  end
  
  avg_nactive = 0;
  for obs = nobs-1:-1:1
    if verb >= 2
      tic
    end
    
    % beam pruning
    threshLogProb = nextFrameLogProb + beamLogProb;
    
    % rank pruning               
    if maxRank > 0
      tmp = nextLatticeFrame(:);
      min_tmp = 2*min(tmp(tmp > zeroLogProb));
      tmp(tmp < zeroLogProb) = min_tmp;
      
      [hst cdf] = hist(tmp, histSize);
    
      % want to look at the high ranks of the last frame
      hst = hst(end:-1:1);
      cdf = cdf(end:-1:1);
    
      hst = cumsum(hst);
      idx = min(find(hst >= maxRank));
      rankThresh = cdf(idx);
      
      % only change the threshold if it is stricter than the beam
      % threshold
      threshLogProb = max(threshLogProb, rankThresh);
    
      if verb >= 3
        %imgsc(prevLatticeFrame), colorbar, title(num2str(obs)), drawnow
        
        disp(['beam thresh = ' num2str(prevFrameMaxLogProb+beamLogProb) ...
              ', rank thresh = ' num2str(rankThresh) ...
              ', final thresh = ' num2str(threshLogProb)]);
      end
    end
    
    % which states are active?
    s_idx = find(nextLatticeFrame >= threshLogProb);
    nactive = numel(s_idx);
    avg_nactive = avg_nactive + nactive/nobs;

    
    pr = hmm.transmat(:, s_idx) + repmat(nextLatticeFrame(s_idx), [1, hmm.nstates])';
    pr(pr <= zeroLogProb) = zeroLogProb;
  
    p_idx = find(logsum(pr, 2) > zeroLogProb);
    np = length(p_idx);
    currllik = repmat(zeroLogProb, [hmm.nstates, 1]);
    if strcmp(hmm.emission_type, 'gaussian')
      currllik(p_idx) = lmvnpdf(seq(:,obs+1), hmm.means(:, p_idx), ...
          hmm.covars(:, p_idx));
    else
      for s = 1:np
        currllik(p_idx(s)) = eval_gmm(hmm.gmms(p_idx(s)), seq(:,obs+1));
      end
    end
    
    nextLatticeFrame = logsum(pr + repmat(currllik, [1, nactive]), 2);
    
    nextFrameLogProb = logsum(nextLatticeFrame(nextLatticeFrame > zeroLogProb));
    
    if nargout > 1
      lattice(:, obs) = nextLatticeFrame;
    end
  
    if verb >= 2
      T = toc;
      disp(['  frame ' num2str(obs), ' (' num2str(T) ' sec)' ...
            ': total active states: ' num2str(nactive)]);
    end
  end

  loglik = nextFrameLogProb;
else
  nextLatticeFrame = 0;
end




if verb >= 2
  disp('Starting forward pass...');
end

prevLatticeFrame = hmm.start_prob(:);

% new threshold

tmp = prevLatticeFrame + nextLatticeFrame;
%ntmp = logsum(tmp);%(tmp > zeroLogProb));
%s_idx = find(tmp > threshLogProb + ntmp);

if do_backward
  threshLogProb = -100;
else
  loglik = zeroLogProb;
  threshLogProb = zeroLogProb;
end

s_idx = find(tmp > loglik + threshLogProb);
%s_idx = find(tmp > zeroLogProb);

%avg_nactive = 0;
prevFrameMaxLogProb = 0;
for obs = 1:nobs
  if verb >= 2
    tic
  end

  nactive = numel(s_idx);

  % which states are active?
  pr = hmm.transmat(s_idx, :)' + repmat(prevLatticeFrame(s_idx), [1, hmm.nstates])';
  pr(pr <= zeroLogProb) = zeroLogProb;
  
  p_idx = find(logsum(pr, 2) > zeroLogProb);
  np = length(p_idx);
  currllik = repmat(zeroLogProb, [hmm.nstates, 1]);
  if strcmp(hmm.emission_type, 'gaussian')
    currllik(p_idx) = lmvnpdf(seq(:,obs), hmm.means(:, p_idx), ...
        hmm.covars(:, p_idx));
  else
    for s = 1:np
      currllik(p_idx(s)) = eval_gmm(hmm.gmms(p_idx(s)), seq(:,obs));
    end
  end
  
  prevLatticeFrame = logsum(pr, 2) + currllik;

  if nargout > 1
    % compute gamma = P(in state combination s1,s2 at time obs 
    %                       | all observations)
    
    tmp = prevLatticeFrame;
    if do_backward
      tmp = tmp + lattice(:,obs);
    end
    nntmp = logsum(tmp);
    etmp = exp(tmp - nntmp);
    etmp(etmp < 1e-5) = 0;
    lattice(:,obs) = etmp;  
  
    loglik = nntmp;
  end
  
  %[loglik  max(tmp), loglik-max(tmp)]

  % Use HTK style pruning (p. 137 of HTK Book version 3.4) - don't
  % bother computing backward probability if alpha*beta is more than
  % a certain distance from loglik
  %s_idx = find(tmp > threshLogProb + ntmp);
  %s_idx = find(tmp > zeroLogProb);
  
  s_idx = find(tmp > loglik + threshLogProb);
    
  if verb >= 2
    T = toc;
    disp(['  frame ' num2str(obs), ' (' num2str(T) ' sec)' ...
          ': total active states: ' num2str(nactive)]);
  end
end

tmp(tmp < zeroLogProb) = zeroLogProb;
%loglik = logsum(tmp);

if verb
  disp(['eval_hmm: log likelihood: ' num2str(loglik) ...
        ', average number of active states per frame: ' ...
        num2str(avg_nactive)]);
end
