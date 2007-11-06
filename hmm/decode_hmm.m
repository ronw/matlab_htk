function [loglik, stateseq, recon, lattice, tb, mllattice] = decode_hmm(hmm, seq, maxRank, beamLogProb, normalize_lattice, verb)
% [loglik, stateseq, recon, lattice, tb] = decode_hmm(hmm, seq, rank, beam)
%
% Performs Viterbi decode of seq.  Does rank and beam pruning.
% Assumes all hmm params are logprobs.
%
% 2007-02-26 ronw@ee.columbia.edu

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
  normalize_lattice = 0;
end

if nargin < 6
  verb = 0;
end

% make sure the hmms have gaussian emissions
%hmm1 = convert_hmm_to_gaussian_emissions(hmm1);
%hmm2 = convert_hmm_to_gaussian_emissions(hmm2);


% how big should our rank pruning histogram be?
histSize = 1000;

[ndim, nobs] = size(seq);

% I am not going to do this in a graph since its slow as hell...
% hopefully the sequences aren't so long so the state/obs lattice
% isn't too big
stateseq = zeros(1, nobs);
tb = zeros(hmm.nstates, nobs);

if nargout > 3
  lattice = repmat(zeroLogProb, [hmm.nstates, nobs]);
end
prevLatticeFrame = hmm.start_prob(:);
tb = zeros(hmm.nstates, nobs);

% fill in the lattice...
avg_nactive = 0;
prevFrameMaxLogProb = 0;
for obs = 1:nobs
  if verb >= 2
    tic
  end
  
  % beam pruning
  threshLogProb = prevFrameMaxLogProb + beamLogProb;
  
  % rank pruning               
  if maxRank > 0
    tmp = prevLatticeFrame(:);
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
  s_idx = find(prevLatticeFrame >= threshLogProb);
  nactive = numel(s_idx);
  avg_nactive = avg_nactive + nactive/nobs;

  vitPr = hmm.transmat(s_idx, :)' + repmat(prevLatticeFrame(s_idx), [1, hmm.nstates])';
  
  v_idx = find(max(vitPr,[], 2) > zeroLogProb);
  nv = length(v_idx);
  currllik = repmat(zeroLogProb, [hmm.nstates, 1]);
  if strcmp(hmm.emission_type, 'gaussian')
    currllik(v_idx) = lmvnpdf(seq(:,obs), hmm.means(:, v_idx), ...
        hmm.covars(:, v_idx));
  else
    for s = 1:nv
      currllik(v_idx(s)) = eval_gmm(hmm.gmms(v_idx(s)), seq(:,obs));
    end
  end
  
  [prevLatticeFrame tb_tmp] = max(vitPr + repmat(currllik, [1, nactive]), [], 2);
  tb(:,obs) = s_idx(tb_tmp);
  
  if nargout > 3
    lattice(:,obs) = prevLatticeFrame;
  end

  prevFrameMaxLogProb = max(prevLatticeFrame);
  
  if verb >= 2
    T = toc;
    disp(['frame ' num2str(obs), ' (' num2str(T) ' sec)' ...
          ': total active states: ' num2str(nactive)]);
  end
end

% include end_prob in lattice:
ptmp = prevLatticeFrame;
prevLatticeFrame = prevLatticeFrame + hmm.end_prob(:);

%%%
% do the traceback:
[loglik s] = max(prevLatticeFrame(:));

% we might have pruned too much, don't want to give up if end_prob
% restrictions are too strong - so just ignore them in this case
if loglik <= zeroLogProb
  warning(['decode_hmm: overpruned during decode,' ...
        ' ignoring probabilities that the hmms end in a' ...
        ' particular state']);
  prevLatticeFrame = ptmp;
  [loglik s] = max(prevLatticeFrame);
end

if nargout > 3
  lattice(:,end) = prevLatticeFrame;
end

for obs = nobs:-1:1
  stateseq(obs) = s;
  s = tb(s, obs);
end


% need to keep track of which gmm component was used in the
% traceback for reconstruction - since this code doesn't do that,
% can only guess as to the right reconstruction for GMM emissions -
% should use convert_hmm_to_gaussian_emissions before calling this
% function to get the full traceback
if strcmp(hmm.emission_type, 'gaussian')
  recon = hmm.means(:,stateseq);
else
  for s = 1:hmm.nstates
    means(:,s) = hmm.gmms(s).means * exp(hmm.gmms(s).priors)';
  end

  recon = means(:,stateseq);
end

if nargout > 3 & normalize_lattice
  nrm = logsum(lattice, 1);
  lattice = exp(lattice - repmat(nrm, [hmm.nstates, 1]));
  lattice(lattice < 1e-5) = 0;
end

if nargout > 4
  mllattice = sparse(hmm.nstates, nobs);
  for o = 1:nobs
    mllattice(stateseq(o),o) = 1;
  end
end


if verb
  disp(['decode_hmm: log likelihood: ' num2str(loglik) ...
        ', average number of active states per frame: ' ...
        num2str(avg_nactive)]);
end
