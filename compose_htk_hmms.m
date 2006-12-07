function hmm = compose_htk_hmms(hmms, name, adjmat)
% hmm = compose_htk_hmms(hmms, name, adjmat)
%
% Take a list of HMMs and an HTK grammar explaining how the HMMs in
% the list are stiched together and create one big FSM HMM from it.
% name is the (optional) name of the new hmm.  adjmat is the adjacency
% matrix explaining how the individual hmms in hmms should be
% connected (ala an HTK grammar)
%
% This function assumes that the first and last state in each HMM
% are non-emitting states (i.e. the first state acts as the prior
% over the emitting states and the last state is an exit state).
% ( you can get this by calling readhtkhmm(filename, 1, 1);
%
% As of 2006-12-05 this only supports HMMs with gaussian emissions.
%
% 2006-12-01 ronw@ee.columbia.edu

if nargin < 2
  name = 'FSM';
end
if nargin < 3
  adjmat = ones(length(hmms));
end

% make sure adjmat is symmetric
adjmat = (adjmat + adjmat') > 0;

hmm_names = cellstr(strvcat(hmms.name));
hmm_nestates = cat(2, hmms.num_emitting_states);
% total number of states (including start state and exit state)
hmm_nstates = cat(2, hmms.nstates);
% we want start states to overlap with exit states of other HMMs
% when composing, so indexing should ignore non-emitting states
hmm_indices = cumsum([1 hmm_nestates(1:end-1)]);

% % reorder hmms so it agrees with the ordering of names
% old_hmms = hmms;
% for x = 1:length(hmms)
%   idx = strmatch(names{x}, strvcat(hmms.name));
%   hmms(x) = old_hmms(idx);
% end

% all of my hmm crap needs to be reworked since it can't deal with
% non-emitting states

nstates = sum(hmm_nestates);
hmm = struct('name', name, ...
    'priors', zeros(1, nstates) - Inf, ...
    'transmat', zeros(nstates) - Inf, ...
    'mu', cat(2, hmms.mu), ...
    'covar', cat(2, hmms.covar), ...
    'nstates', nstates);

% need to fill in hmm.priors and (more importantly) hmm.transmat
% iterate over each row of adjmat and 
for x = 1:length(hmms)
  % index into priors/columns of mu and covar correspoding to this
  % gmm
  pidx = hmm_indices(x)+[0:hmm_nstates(x)-1];

  % as this stands now, the first hmm can never move into a
  % different one...  need to add transition/exit states somehow
  % fixed...
  idx = find(adjmat(:,1) == 1)
  % why in gods name is this necessary?
  if length(idx) == 0
    idx = [];
  end
  for y = idx
    yidx = hmm_indices(y)+[0:hmm_nstates(x)-1];
    hmm.transmat(pidx,yidx) = hmms(x).transmat;
  end

  % is this a start hmm?
  if adjmat(1,x) > 0
    hmm.priors(hmm_indices(x)+[0:hmm_nestates(x)-1]) = adjmat(x,1)*hmms(x).priors(1:hmm_nestates(x));
  end
end

% normalize the new transmat and priors
% priors should sum to 1, 

% each row of transmat should sum to one
