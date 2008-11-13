function [samples state_seq] = sample_hmm(hmm)
% [samples state_seq] = sample_hmm(hmm)
%
% Generate a random sample from the given HMM.
%
% 2008-06-04 ronw@ee.columbia.edu

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

sp_pdf = exp(hmm.start_prob);
sp_cdf = cumsum(sp_pdf);
trans_pdf = exp([hmm.transmat hmm.end_prob']);
trans_cdf = cumsum(trans_pdf, 2);

% Initial state
p = rand(1);
s = min(find(sp_cdf >= p));
state_seq = s;
samples = sample_from_state(hmm, s);

i = 1;
while true
  % Select next component or exit.
  p = rand(1);
  os = s;
  s = min(find(trans_cdf(os,:) >= p));
  if isempty(s)
    s = length(trans_cdf(os,:));
  end

  if s > hmm.nstates
    break
  else
    i = i + 1;
    samples(:,i) = sample_from_state(hmm, s);
    state_seq(i) = s;
  end
end


function y = sample_from_state(hmm, s)
if strcmp(hmm.emission_type, 'GMM')
  y = sample_gmm(hmm.gmms(s), 1);
elseif strcmp(hmm.emission_type, 'gaussian')
  y = sample_gaussian(hmm.means(:,s), hmm.covars(:,s));
else
  error(['Invalid HMM emission type: ' hmm.emission_type]);
end
