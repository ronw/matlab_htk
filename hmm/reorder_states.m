function new_hmm = reorder_states(hmm, idx)
% new_hmm = reorder_states(hmm, idx)
%
% Rearrange the states of hmm using the given indices.
%
% 2008-09-12 ronw@ee.columbia.edu

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

if is_valid_gmm(hmm)
  new_hmm = reorder_states_gmm(hmm, idx);
else
  new_hmm = reorder_states_hmm(hmm, idx);
end

function new_gmm = reorder_states_gmm(gmm, idx)
new_gmm = gmm;
new_gmm.nmix = length(idx);
new_gmm.means = gmm.means(:,idx);
new_gmm.covars = gmm.covars(:,idx);
% Ensure priors are normalized (if components are deleted and not
% just rearranged).
new_gmm.priors = gmm.priors(idx) - logsum(gmm.priors(idx));


function new_hmm = reorder_states_hmm(hmm, idx)
new_hmm = hmm;
new_hmm.nstates = length(idx);
if strcmp(hmm.emission_type, 'GMM')
  new_hmm.gmms = hmm.gmms(idx);
else
  new_hmm.means = hmm.means(:,idx);
  new_hmm.covars = hmm.covars(:,idx);
end
new_hmm.start_prob = hmm.start_prob(idx);
new_hmm.transmat = hmm.transmat(idx,idx);
new_hmm.end_prob = hmm.end_prob(idx);

% Make sure everything is normalized properly.
new_hmm.start_prob = new_hmm.start_prob - logsum(new_hmm.start_prob);
norm = logsum(cat(2, logsum(new_hmm.transmat, 2), new_hmm.end_prob'), 2);
new_hmm.transmat = new_hmm.transmat - repmat(norm, [1 new_hmm.nstates]);
new_hmm.end_prob = new_hmm.end_prob - norm';
