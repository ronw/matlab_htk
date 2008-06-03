function new_hmms = convert_hmm_to_gaussian_emissions(hmms)
% new_hmms = convert_hmm_to_gaussian_emissions(hmms)
%
% Convert HMMs with GMM emissions in hmms to new_hmms with gaussian
% emissions.  hmms can be an array of hmm structures.
%
% 2007-01-18 ronw@ee.columbia.edu

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

for n = 1:length(hmms)
  if strcmp(hmms(n).emission_type, 'gaussian')
    new_hmms(n) = hmms(n);
    continue;
  end
  
  new_hmms(n).name = hmms(n).name;
  new_hmms(n).emission_type = 'gaussian';

  nmix = [hmms(n).gmms(:).nmix];
  state_offset = cumsum([0, nmix(1:end-1)]);

  new_hmms(n).nstates = sum(nmix);
  new_hmms(n).transmat = repmat(-Inf, [new_hmms(n).nstates, new_hmms(n).nstates]);

  curr_state = 0;
  for s = 1:hmms(n).nstates
    ns = state_offset(s) + [1:nmix(s)];

    new_hmms(n).start_prob(ns) = hmms(n).start_prob(s);
    new_hmms(n).end_prob(ns) = hmms(n).end_prob(s);

    if(isfield(hmms(n), 'labels'))
      new_hmms(n).labels(ns) = hmms(n).labels(s);
    end

    new_hmms(n).means(:,ns) = hmms(n).gmms(s).means;
    new_hmms(n).covars(:,ns) = hmms(n).gmms(s).covars;

    for ss = 1:hmms(n).nstates
      nss = state_offset(ss) + [1:nmix(ss)];
      new_hmms(n).transmat(ns, nss) = hmms(n).transmat(s,ss);
    end
  end

  priors = [hmms(n).gmms(:).priors];
  % make sure priors is a column vector
  priors = priors(:);
  for r = 1:new_hmms(n).nstates
    new_hmms(n).transmat(r,:) = new_hmms(n).transmat(r,:) + priors';
  end

  new_hmms(n).start_prob = new_hmms(n).start_prob + priors';
end
