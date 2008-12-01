function new_hmm = merge_states(hmm, idx)
% new_hmm = merge_states(hmm, idx)
%
% Merge states of the given HMM.  idx is a list of state indices to
% merge.  If idx is a matrix, the indices in each column will be
% merged into a single state.  Also works on GMM structures.
%
% Examples:
%  - Merge states 1, 3, and 5:    merge_states(hmm, [1 3 5]) 
%  - Merge states 1:5 and 10:20:  merge_states(hmm, [1:5; 10:20]')
%  - Merge succesive pairs of states:
%    merge_states(hmm, reshape(1:hmm.nstates, [2, hmm.nstates/2])) 
%
% Note that the merging isn't at all correct - it just dumbly takes
%  the weighted average of the given states.
%
% 2008-06-03 ronw@ee.columbia.edu

% Copyright (C) 2008 Ron J. Weiss
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

[nr nc] = size(idx);
if nr == 1 || nc == 1
  % Turn into a column vector
  idx = idx(:);
end

if is_valid_gmm(hmm)
  new_hmm = merge_states_gmm(hmm, idx);
else
  new_hmm = merge_states_hmm(hmm, idx);
end



function new_gmm = merge_states_gmm(gmm, idx)
[nr nc] = size(idx);
new_gmm = gmm;
states_to_delete = zeros(gmm.nmix, 1);
for c = 1:nc
  i = idx(:,c);
  states_to_delete(i(2:end)) = 1;

  lp = gmm.priors(i);
  new_gmm.priors(i(1)) = logsum(lp);

  p = exp(lp(:) - logsum(lp));
  new_gmm.means(:,i(1)) = gmm.means(:,i) * p;
  new_gmm.covars(:,i(1)) = gmm.covars(:,i) * p;
end

i = find(~states_to_delete);
new_gmm.nmix = length(i);
new_gmm.priors = new_gmm.priors(i);
new_gmm.means = new_gmm.means(:,i);
new_gmm.covars = new_gmm.covars(:,i);



function new_hmm = merge_states_hmm(hmm, idx)
if strcmp(hmm.emission_type, 'GMM')
  error('HMMs with GMM emissions are not supported.');
end
[nr nc] = size(idx);
new_hmm = hmm;
states_to_delete = zeros(hmm.nstates, 1);
for c = 1:nc
  i = idx(:,c);
  states_to_delete(i(2:end)) = 1;

  lp = logsum(hmm.transmat(:,i), 1);
  p = exp(lp(:) - logsum(lp));

  new_hmm.start_prob(i(1)) = logsum(hmm.start_prob(i));
  new_hmm.transmat(i(1),i(1)) = logsum(logsum(hmm.transmat(i,i), 2) + p);
  for s = 1:hmm.nstates
    new_hmm.transmat(s,i(1)) = logsum(hmm.transmat(s,i));
  end
  new_hmm.end_prob(i(1)) = logsum(hmm.end_prob(i));

  new_hmm.means(:,i(1)) = hmm.means(:,i) * p;
  new_hmm.covars(:,i(1)) = hmm.covars(:,i) * p;
end

i = find(~states_to_delete);
new_hmm.nstates = length(i);
new_hmm.start_prob = new_hmm.start_prob(i);
new_hmm.transmat = new_hmm.transmat(i,i);
new_hmm.end_prob = new_hmm.end_prob(i);
new_hmm.means = new_hmm.means(:,i);
new_hmm.covars = new_hmm.covars(:,i);

% Get rid of NaNs introduced by logsum(-Inf)
new_hmm.start_prob(isnan(new_hmm.start_prob)) = -Inf;
new_hmm.end_prob(isnan(new_hmm.end_prob)) = -Inf;
new_hmm.transmat(isnan(new_hmm.transmat)) = -Inf;

% make sure transmat and end_prob are normalized properly
norm = logsum(cat(2, logsum(new_hmm.transmat, 2), new_hmm.end_prob'), 2);
new_hmm.transmat = new_hmm.transmat - repmat(norm, [1 new_hmm.nstates]);
new_hmm.end_prob = new_hmm.end_prob - norm';
