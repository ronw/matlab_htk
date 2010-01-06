function hmm = compose_hmms(hmms, meta_hmm)
% hmm = compose_hmms(hmms, meta_hmm)
%
% Takes an array of HMM structures and a meta_hmm explaining how the
% HMMs in the list are stiched together and create one big FSM HMM
% from it.
%
% meta_hmm should have length(hmms) states.  Each state in meta_hmm
% should have a label corresponding to the name of one HMM in hmms.
% The state emissions of meta_hmm are ignored.  By default meta_hmm
% is fully connected.
%
%
% 2006-12-01 ronw@ee.columbia.edu

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

% shutup with the logOfZero warnings when in this function
w = warning('query', 'MATLAB:log:logOfZero');
if strcmp(w.state, 'on')
  warning('off', 'MATLAB:log:logOfZero');
end


if nargin < 2
  nhmms = length(hmms);
  meta_hmm.nstates = length(hmms);
  meta_hmm.labels = cellstr(strvcat(hmms.name));
  meta_hmm.transmat = log(ones(nhmms)/(nhmms+1));
  meta_hmm.start_prob = log(ones(1, nhmms)/nhmms);
  meta_hmm.end_prob = log(ones(1, nhmms)/(nhmms+1));
  meta_hmm.name = 'FST';
end

nhmms = meta_hmm.nstates;

% make sure the labels of the grammar match those of the hmms
hmms_names = cellstr(strvcat(hmms.name));
map = zeros(1, meta_hmm.nstates);
for i = 1:meta_hmm.nstates
  map(i) = strmatch(meta_hmm.labels{i}, hmms_names, 'exact');
end

hmms = hmms(map);
hmms_names = cellstr(strvcat(hmms.name));


hmms_nstates = cat(2, hmms.nstates);
hmms_indices = cumsum([1 hmms_nstates(1:end-1)]);

nstates = sum(hmms_nstates);
hmm = struct('name', meta_hmm.name, ...
    'nstates', nstates, ...
    'start_prob', zeros(1, nstates) - Inf, ...
    'end_prob', zeros(1, nstates) - Inf, ...
    'transmat', zeros(nstates) - Inf);

curr_state = 1;
for n = 1:nhmms
  [hmm.labels{curr_state:curr_state+hmms(n).nstates}] = ...
      deal(hmms(n).name);
  curr_state = curr_state + hmms(n).nstates;
end

hmm.emission_type = hmms(1).emission_type;
if strcmp(hmm.emission_type, 'gaussian')
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

  % probability of transitioning from one hmm to another
  for y = 1:nhmms
    dest_idx = hmms_indices(y)+[0:hmms_nstates(y)-1];

    source_prob = exp(hmms(x).end_prob);
    dest_prob = exp(hmms(y).start_prob);

    % make sure we have column vectors
    source_prob = source_prob(:);
    dest_prob = dest_prob(:);

    hmm.transmat(source_idx, dest_idx) = ...
        log(source_prob * dest_prob') ...
        + meta_hmm.transmat(x,y);
  end

  % probability of remaining in the same hmm (including some
  % probability that we will loop back (given by the self loop
  % probability in meta_hmm))
  hmm.transmat(source_idx,source_idx) = log(exp(hmms(x).transmat) ...
      + exp(meta_hmm.transmat(x,x))*exp(hmms(x).end_prob(:))*exp(hmms(x).start_prob(:))');
end

% normalize transmat and end_prob properly
if size(hmm.end_prob, 2) == 1
  hmm.end_prob = hmm.end_prob';
end
norm = log(exp(logsum(hmm.transmat, 2)) + exp(hmm.end_prob'));
hmm.transmat = hmm.transmat - repmat(norm, 1, nstates);
hmm.end_prob = hmm.end_prob - norm';

% turn warnings back on 
warning(w.state, w.identifier);
