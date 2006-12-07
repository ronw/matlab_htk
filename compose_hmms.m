function hmm = compose_hmms(hmms, meta_hmm)
% hmm = compose_hmms(hmms, meta_hmm)
%
% Take a list of HMMs and a meta_hmm explaining how the HMMs in
% the list are stiched together and create one big FSM HMM from it.
%
% meta_hmm should have length(hmms) states.  Each state in meta_hmm
% should have a label corresponding to the name of one HMM in hmms.
% The state emissions of meta_hmm are ignored.  By default meta_hmm
% is fully connected.
%
%
% 2006-12-01 ronw@ee.columbia.edu

% shutup with the logOfZero warnings when in this function
w = warning('query', 'MATLAB:log:logOfZero');
if strcmp(w.state, 'on')
  warning('off', 'MATLAB:log:logOfZero');
end

nhmms = length(hmms);

if nargin < 2
  meta_hmm.labels = cellstr(strvcat(hmms.name));
  meta_hmm.transmat = log(ones(nhmms)/(nhmms+1));
  meta_hmm.start_prob = log(ones(1, nhmms)/nhmms);
  meta_hmm.end_prob = log(ones(1, nhmms)/(nhmms+1));
  meta_hmm.name = 'FST';
end

hmms_names = cellstr(strvcat(hmms.name));
hmms_nstates = cat(2, hmms.nstates);
hmms_indices = cumsum([1 hmms_nstates(1:end-1)]);

nstates = sum(hmms_nstates);
hmm = struct('name', meta_hmm.name, ...
    'nstates', nstates, ...
    'start_prob', zeros(1, nstates) - Inf, ...
    'end_prob', zeros(1, nstates) - Inf, ...
    'transmat', zeros(nstates) - Inf);
if isfield(hmms(1), 'labels')
  hmm.labels = cat(2, hmms.labels);
end
if strcmp(hmms(1).emission_type, 'gaussian')
  hmm.means = cat(2, hmms.means);
  hmm.covars = cat(2, hmms.covars);
else
  hmm.gmms = cat(2, hmms.gmms);
end

for x = 1:nhmms
  source_idx = hmms_indices(x)+[0:hmms_nstates(x)-1];
  hmm.start_prob(source_idx) = meta_hmm.start_prob(x) ...
      + hmms(x).start_prob;
  hmm.end_prob(source_idx) = meta_hmm.end_prob(x) ...
      + hmms(x).end_prob;

  for y = 1:nhmms
    dest_idx = hmms_indices(y)+[0:hmms_nstates(y)-1];

    source_prob = exp(hmms(x).end_prob);
    dest_prob = exp(hmms(x).start_prob);
    % make sure we have column vectors
    if size(source_prob, 1) == 1
      source_prob = source_prob';
    end
    if size(dest_prob, 1) == 1
      dest_prob = dest_prob';
    end

    hmm.transmat(source_idx, dest_idx) = ...
        log(source_prob * dest_prob') ...
        + meta_hmm.transmat(x,y);
  end

  % fix the diagonal
  hmm.transmat(source_idx,source_idx) = meta_hmm.transmat(x,x) ...
      + hmms(x).transmat;
end

% normalize transmat and end_prob properly
if size(hmm.end_prob, 2) == 1
  hmm.end_prob = hmm.end_prob';
end
norm = log(exp(logsum(hmm.transmat, 2)) + exp(hmm.end_prob'));
hmm.transmat = hmm.transmat - repmat(norm, 1, nstates);
hmm.end_prob = hmm.end_prob - norm';

warning(w.state, w.identifier);
