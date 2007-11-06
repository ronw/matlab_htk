function hmms = apply_mllr_transform(hmms, W, b)
% recognizer = apply_mllr_transform(recognizer, W, b)
%
% Applies the global MLLR mean transform [W,b] to the recognizer
% parameters.
%
% 2007-02-20 ronw@ee.columbia.edu

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

if isfield(hmms, 'hmms')
  % we got a recognizer structure, not a list of hmms
  hmms.hmms = apply_mllr_transform(hmms.hmms, W, b);
elseif isfield(hmms, 'emission_type')
  for h = 1:length(hmms)
    if strcmp(hmms(h).emission_type, 'gaussian')
      hmms(h).means = W*hmms(h).means + repmat(b, [1, hmms(h).nstates]);
    elseif strcmp(hmms(h).emission_type, 'GMM')
      for s = 1:hmms(h).nstates
        hmms(h).gmms(s).means = W*hmms(h).gmms(s).means ...
            + repmat(b, [1, hmms(h).gmms(s).nmix]);
      end
    end
  end
else
  % hmms is just a matrix
  hmms = W*hmms + repmat(b, [1, size(hmms, 2)]);
end
