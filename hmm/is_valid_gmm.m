function out = is_valid_gmm(gmm, verb)
% y = is_valid_gmm(gmm)
%
% Returns 1 if and only if gmm is a valid GMM structure
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

if nargin < 2; verb = 0; end

out = true;
if ~isstruct(gmm)
  out = false;
  if verb; fprintf('is_valid_gmm: not a structure\n'); end
  return
end

if ~isfield(gmm, 'nmix')
  out = false;
  if verb; fprintf('is_valid_gmm: missing nmix field\n'); end
  return
end

if ~isfield(gmm, 'priors')
  out = false;
  if verb; fprintf('is_valid_gmm: missing priors field\n'); end
else
  if length(gmm.priors) ~= gmm.nmix
    out = false;
    if verb; fprintf('is_valid_gmm: priors field is wrong length\n'); end
  end
  if abs(logsum(gmm.priors)) > 1e-3
    out = false;
    if verb; fprintf('is_valid_gmm: priors don''t sum to 1\n'); end
  end
end

if ~isfield(gmm, 'means')
  out = false;
  if verb; fprintf('is_valid_gmm: missing means field\n'); end
else
  if size(gmm.means, 2) ~= gmm.nmix
    out = false;
    if verb; fprintf('is_valid_gmm: means field is wrong length\n'); end
  end
end

if ~isfield(gmm, 'covars')
  out = false;
  if verb; fprintf('is_valid_gmm: missing covars field\n'); end
else
  if size(gmm.covars, 2) ~= gmm.nmix
    out = false;
    if verb; fprintf('is_valid_gmm: covars field is wrong length\n'); end
  end
  if isfield(gmm, 'means') && size(gmm.means, 1) ~= size(gmm.covars,1)
    out = false;
    if verb
      fprintf('is_valid_gmm: means and covars have inconsistent dimensions\n');
    end
  end
  if ~all(all(gmm.covars > 0))
    out = false;
    if verb; fprintf('is_valid_gmm: 0 or negative covars\n'); end
  end
end


