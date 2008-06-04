function samples = sample_gmm(gmm, nsamp)
% samples = sample_gmm(gmm, N)
%
% Generate N random samples from the given GMM.
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

prior_pdf = exp(gmm.priors);
prior_cdf = cumsum(prior_pdf);

ndim = size(gmm.means, 1);

samples = zeros(ndim, nsamp);
for n = 1:nsamp
  p = rand(1);
  c = min(find(prior_cdf >= p));
  mu = gmm.means(:,c);
  cv = gmm.covars(:,c);
  samples(:,n) = randn(ndim, 1).*sqrt(cv) + mu;
end

