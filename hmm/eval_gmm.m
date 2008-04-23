function [ll, post, mlg, mmserecon] = eval_gmm(gmm, data, norm)
% [loglik, posteriors, mlseq, recon] = eval_gmm(gmm, data)
%
% Evaluate the log probability of each column of data given GMM gmm.
%
% Outputs:
% loglik     - log likelihood of each colimn of data
% posteriors - posterior probability of each GMM component for each
%              column of data
% mlseq      - index of the most likely GMM component for each
%              column of data
% recon      - MMSE reconstruction of data given the GMM
%
% 2005-11-20 ronw@ee.columbia.edu

% Copyright (C) 2005-2007 Ron J. Weiss
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

if nargin < 3,  norm = 1;  end

[ndim, ndat] = size(data);

post = lmvnpdf(data, gmm.means, gmm.covars) + repmat(gmm.priors(:), [1, ndat]);
ll = logsum(post, 1);

if nargout > 1 && norm
  post = exp(post - repmat(logsum(post,1), gmm.nmix, 1));
end

if nargout > 2
  [mlg tmp] = ind2sub(size(post), find(post == repmat(max(post),gmm.nmix,1)));
end

if nargout > 3
  if norm
    mmserecon = gmm.means*post;
  else
    postnorm = exp(post - repmat(logsum(post,1), gmm.nmix, 1));
    mmserecon = gmm.means*postnorm;
  end
end

