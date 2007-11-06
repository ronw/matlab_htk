function [ll, ss, mask] = maxvq_bb(obs, gmms, verb);
% [logpr, seq, masks] = maxvq_bb(obs, gmms, verb);
%
% Evaluate MAP MAXVQ probabilities and create binary masks using
% Sam Roweis' efficient branch and bound algorithm.
%
% Inputs:
%   obs  - matrix of observations.  Each column is a frame of data.
%   gmms - array of GMM structures
%
% Outputs:
%   logpr - MAP probability of each frame of data given the models
%   seq   - cell array containing the MAP sequence of GMM components
%           for each model
%   masks - cell array of binary masks for each model that notate
%           the portions of obs that are explained by that model
%
% References:
% S. Roweis, "Factorial Models and Refiltering for Speech Separation and
% Denoising", in Proceedings of EuroSpeech 2003.
%
% 2007-04-16 ronw@ee.columbia.edu

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

if nargin < 4,  verb = 0;  end

[ndim nobs] = size(obs);
nmodels = length(gmms);
nmix = [gmms.nmix];
nmix = nmix(:);

% State sequences for each model
ss = cell(nmodels,1);
for m = 1:nmodels
  ss{m} = zeros(nobs,1);
end

% max likelihood state combination for each observation
z = zeros(nmodels, 1);

    
for o = 1:nobs
  if verb,  tic;  end
  data = obs(:,o);

  % compute bounds - try each model separately
  B = cell(nmodels, 1);
  for m = 1:nmodels
    B{m} = zeros(nmix(m), 1);  
    for s = 1:gmms(m).nmix
      dim = find(gmms(m).means(:,s) < data);
      B{m}(s) = lmvnpdf(obs(dim), gmms(m).means(dim,s), ...
          gmms(m).covars(dim,s)) + gmms(m).priors(s);
    end
    z(m) = argmin(B{m});
  end

  % worst case setting
  ll(o) = eval_gmm_max_approx(obs(:,o), gmms, z);

  pz = cell(nmodels, 1);
  for m = 1:nmodels
    pz{m} = zeros(nmix(m), 1);
  end
  
  % evaluate all remaining settings, updating threshold as necesary

  % current state combination
  n = ones(nmodels, 1);
  while all(n <= nmix)
    tmp = eval_gmm_max_approx(obs(:,o), gmms, n);
      
    if tmp < ll(o)
      for m = 1:nmodels
        pz{m}(n(m)) = 0;
      end

      n = n + 1;
    else
      % n contains the best setting so far.
      ll(o) = tmp;
      z = n;

      for m = 1:nmodels
        pz{m}(B{m} < ll(o)) = 0;
      end

      idx = cellfun(@(x) numel(find(x)), pz);
      if all(idx == 1)
        break;
      end

      % move on to the next state combination
      incr = 1;
      carry = 0;
      for m = nmodels:-1:1
        tmp = n(m) + incr + carry;
        if tmp < nmix(m)
          n(m) = tmp;
          break;
        else
          carry = tmp - (nmix(m) - n(m));
          n(m) = nmix(m);
        end
      end
    end
  end

  if verb
    T = toc;
    fprintf('Frame %d: ll = %f (%f sec)\n', o, ll(o), T)
  end

  if nargout > 1
    for m = 1:nmodels
      ss{m}(o) = z(m);
    end
  end
end

if nargout > 2
  nm1mask = zeros(ndim, nobs);
  for m = 1:nmodels-1
    mask{m} = ones(ndim, nobs);
    for n = 1:nmodels
      if n == m,  continue,  end
      mask{m} = mask{m} & (gmms(m).means(:,ss{m}) > gmms(n).means(:,ss{n}));
    end
    nm1mask = nm1mask | mask{m};
  end
  
  mask{nmodels} = ~nm1mask;
end


function ll = eval_gmm_max_approx(obs, gmms, z)

  prior = gmms(1).priors(z(1));
  mu = gmms(1).means(:, z(1));
  cv = gmms(1).covars(:, z(1));
  for m = 2:length(gmms)
    prior = prior + gmms(m).priors(z(m));

    idx = gmms(m).means(:, z(m)) > mu;
    mu(idx) = gmms(m).means(idx, z(m));
    cv(idx) = gmms(m).covars(idx, z(m));
  end

  ll = lmvnpdf(obs, mu, cv) + prior;

