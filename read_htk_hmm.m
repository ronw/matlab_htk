function hmms = read_htk_hmm(filename)
% hmm = read_htk_hmm(filename)
%
% Reads in an HTK HMM definition file.  Only works on text files.
% At the moment this only works for Gaussian emissions with
% diagonal covariance.
%
% 2006-06-09 ronw@ee.columbia.edu

% Copyright (C) 2006-2007 Ron J. Weiss
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

% Read the M-file into a cell array of strings: 
[fid, message] = fopen(filename, 'rt');
warning(message)
file = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '', 'bufSize', 16000);
fclose(fid);

file = file{1};
% Remove any empty lines
file = file(cellfun('length', file) > 0);

nhmms = 1;
lastlinewashmm = 0;
for x = 1:length(file)

  % header stuff:
  %tok = regexpi(file{x}, '<VECSIZE> %d', 'tokens');
  %if ~isempty(tok)
  %  vecsize = tok{1}
  %end

  % is this a new HMM?
  if ~lastlinewashmm 
    if length(file{x}) >= 2 
      if file{x}(1:2) == '~h' | ~isempty(strmatch(upper(file{x}), '<BEGINHMM>'))
        hmms(nhmms) = readNextHMM(file, x);
        nhmms = nhmms+1;
        lastlinewashmm = 1;
      end
    end
  else
    lastlinewashmm = 0;
  end
end


%%%%%%%%%%
function hmm = readNextHMM(file, linenum)

x = linenum;
if ~isempty(findstr(file{x}, '~h'))
  c = strread(file{linenum}, '~h %q');
  hmm.name = c{1};
  x = x + 1;
else
  hmm.name = 'matlabhmm';
end

x = x + 1;
% first and last state in 
hmm.nstates = strread(upper(file{x}), '<NUMSTATES> %d')-2;

x = x + 1;
while isempty(findstr(upper(file{x}),'<TRANSP>'))
  state = strread(upper(file{x}), '<STATE> %d') - 1;
  x = x+1;

  if ~isempty(findstr(upper(file{x}), '<NUMMIXES>'))
    nmix = strread(upper(file{x}), '<NUMMIXES> %d');
    x = x+1;

    hmm.gmms(state).nmix = nmix;
    hmm.gmms(state).priors(1:nmix) = -Inf;
  else
    nmix = 1;
  end 

  for n = 1:nmix
    if ~isempty(findstr(file{x}, '~s "'))
      x = x+1;
      break
    end

    if nmix > 1
      if isempty(findstr(upper(file{x}), '<MIXTURE>'))
        % sometimes HTK skips mixture components.  If we make sure
        % that is a prior of -Inf, then it won't be a problem.
        % Luckilly this is take care of in the initialization above.
        continue
      end

      [currmix, prior] = strread(upper(file{x}), '<MIXTURE> %d %f');
      x = x+1;
    end

    ndim = strread(upper(file{x}), '<MEAN> %d');
    x = x+1;

    if n == 1 & nmix > 1
      hmm.gmms(state).means(1:ndim,1:nmix) = 0;
      hmm.gmms(state).covars(1:ndim,1:nmix) = 1;
    end

    mu = strread(file{x}, '%f', ndim);
    x = x+1;

    ndim = strread(upper(file{x}), '<VARIANCE> %d');
    x = x+1;
    covar = strread(file{x}, '%f', ndim);
    x = x+1;
    
    if ~isempty(findstr(upper(file{x}), '<GCONST>'))
      gconst = strread(upper(file{x}), '<GCONST> %f');
      x = x+1;
    end

    if nmix == 1
      % Gaussian emissions
      hmm.emission_type = 'gaussian';
      hmm.means(:, state) = mu;
      hmm.covars(:, state) = covar;
    else 
      % GMM emissions
      hmm.emission_type = 'GMM';
      hmm.gmms(state).priors(currmix) = log(prior);
      hmm.gmms(state).nmix = nmix;
      hmm.gmms(state).means(:, currmix) = mu;
      hmm.gmms(state).covars(:, currmix) = covar;
    end
  end
end  

nstates = strread(upper(file{x}), '<TRANSP> %d'); 
x = x+1;

transmat = zeros(nstates);
for n = 1:nstates
  transmat(n,:) = strread(file{x}, '%f', nstates);
  x = x+1;
end

w = warning('query', 'MATLAB:log:logOfZero');
if strcmp(w.state, 'on')
  warning('off', 'MATLAB:log:logOfZero');
end
hmm.start_prob = log(transmat(1,2:end-1));
hmm.transmat = log(transmat(2:end-1,2:end-1));
hmm.end_prob = log(transmat(2:end-1,end));
warning(w.state, w.identifier);
