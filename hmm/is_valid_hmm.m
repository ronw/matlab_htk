function out = is_valid_hmm(hmm, verb)
% y = is_valid_hmm(hmm)
%
% Returns 1 if and only if hmm is a valid HMM structure
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
if ~isstruct(hmm)
  out = false;
  if verb; fprintf('is_valid_hmm: not a structure\n'); end
  return
end

if ~isfield(hmm, 'nstates') 
  out = false;
  if verb; fprintf('is_valid_hmm: missing nstates field\n'); end
  return
end
if ~isfield(hmm, 'emission_type') 
  out = false;
  if verb; fprintf('is_valid_hmm: missing emissionn type field\n'); end
end


if ~isfield(hmm, 'start_prob') 
  out = false;
  if verb; fprintf('is_valid_hmm: missing start_prob field\n'); end
else
  if length(hmm.start_prob) ~= hmm.nstates 
    out = false;
    if verb; fprintf('is_valid_hmm: start_prob field is wrong length\n'); end
  end
  if abs(logsum(hmm.start_prob)) > 1e-3 
    out = false;
    if verb; fprintf('is_valid_hmm: start_prob doesn''t sum to 1\n'); end
  end
end

if ~isfield(hmm, 'end_prob') 
  out = false;
  if verb; fprintf('is_valid_hmm: missing end_prob field\n'); end
else
  if length(hmm.end_prob) ~= hmm.nstates 
    out = false;
    if verb; fprintf('is_valid_hmm: end_prob field is wrong length\n'); end
  end
  if ~isfield(hmm, 'transmat') 
    out = false;
    if verb; fprintf('is_valid_hmm: missing transmat field\n'); end
  else
    if ~all(size(hmm.transmat) == [hmm.nstates hmm.nstates]) 
      out = false;
      if verb; fprintf('is_valid_hmm: transmat is wrong size\n'); end
    end
    if ~all(abs(sum(exp(hmm.transmat), 2) + exp(hmm.end_prob(:)) - 1) < 1e-3)
      out = false;
      if verb;
        fprintf('is_valid_hmm: transmat is not normalized properly\n');
      end
    end
  end
end


if strcmp(hmm.emission_type, 'GMM')
  if ~isfield(hmm, 'gmms')
    out = false;
    if verb; fprintf('is_valid_hmm: missing gmms field\n'); end
  else
    for s = 1:length(hmm.gmms)
      tmp = is_valid_gmm(hmm.gmms(s));
      if ~tmp
        out = false;
        if verb
          fprintf('is_valid_hmm: Error in state %d:\n  ', s);
          is_valid_gmm(hmm.gmms(s), verb);
        end
        break
      end
    end
  end
end
if strcmp(hmm.emission_type, 'gaussian') 
  if ~isfield(hmm, 'means')
    out = false;
    if verb; fprintf('is_valid_hmm: missing means field\n'); end
  else
    if size(hmm.means, 2) ~= hmm.nstates 
      out = false;
      if verb; fprintf('is_valid_hmm: means field is wrong length\n'); end
    end
  end
  
  if ~isfield(hmm, 'covars') 
    out = false;
    if verb; fprintf('is_valid_hmm: missing covars field\n'); end
  else
    if size(hmm.covars, 2) ~= hmm.nstates 
      out = false;
      if verb; fprintf('is_valid_hmm: covars field is wrong length\n'); end
    end
    if isfield(hmm, 'means') &&  size(hmm.means, 1) ~= size(hmm.covars,1) 
      out = false;
      if verb
        fprintf(['is_valid_hmm: means and covars have inconsistent ' ...
              'dimensions\n']);
      end
    end
    if ~all(all(hmm.covars > 0))
      out = false;
      if verb; fprintf('is_valid_hmm: 0 or negative covars\n'); end
    end
  end
end

