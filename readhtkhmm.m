function hmms = readhtkhmm(filename, include_exit_state, priors_in_transmat);
% hmm = readhtkhmm(filename, include_exit_state, priors_in_transmat)
%
% Reads in an HTK HMM definition file.  Only works on text files.
% At the moment this only works for Gaussian emissions with
% diagonal covariance.
%
% This function makes a some assumptions about the HTK HMM its reading
% in.  It assumes that the last state in each HMM is a non-emitting
% exit state.
%
% If include_exit_state == 1, the transition matrix of the returned
% hmms will have an extra column at the end which includes the
% probability that the HMM transitions to a non-emitting exit state.
%
% 2006-06-09 ronw@ee.columbia.edu

if nargin < 2
  %include_exit_state = 1;
  include_exit_state = 0;
end
if nargin < 3
  priors_in_transmat = 0;
end

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
        hmms(nhmms) = readNextHMM(file, x, include_exit_state, priors_in_transmat);
        nhmms = nhmms+1;
        lastlinewashmm = 1;
      end
    end
  else
    lastlinewashmm = 0;
  end
end


%%%%%%%%%%
function hmm = readNextHMM(file, linenum, include_exit_state, priors_in_transmat)

x = linenum;
if ~isempty(findstr(file{x}, '~h'))
  c = strread(file{linenum}, '~h %s');
  hmm.name = c{1};
  x = x + 1;
else
  hmm.name = 'matlabhmm';
end

x = x + 1;
hmm.nstates = strread(upper(file{x}), '<NUMSTATES> %d');
hmm.num_emitting_states = hmm.nstates-include_exit_state-priors_in_transmat;

x = x + 1;
while isempty(findstr(upper(file{x}),'<TRANSP>'))
  state = strread(upper(file{x}), '<STATE> %d') - 1;
  x = x+1;

  if ~isempty(findstr(upper(file{x}), '<NUMMIXES>'))
    nmix = strread(upper(file{x}), '<NUMMIXES> %d');
    x = x+1;
  else
    nmix = 1;
  end 

  for n = 1:nmix
    if ~isempty(findstr(file{x}, '~s "'))
      x = x+1;
      break
    end

    if nmix > 1 
      [currmix, prior] = strread(upper(file{x}), '<MIXTURE> %d %f');
      x = x+1;
    end

    ndim = strread(upper(file{x}), '<MEAN> %d');
    x = x+1;
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
      %hmm.mix(state) = prior;
      %hmm.priors(state) = prior;
      hmm.mu(:, state) = mu;
      hmm.covar(:, state) = covar;
      %hmm.gconst(state) = gconst;
    else 
      % GMM emissions
      hmm.gmm{state}.mix(currmix) = prior;
      %hmm.gmm{state}.priors(currmix) = prior;
      hmm.gmm{state}.nmix = nmix;
      hmm.gmm{state}.mu(:, currmix) = mu;
      hmm.gmm{state}.covar(:, currmix) = covar;
      %hmm.gmm_gconst{state}(currmix) = gconst; 
    end
  end
end  

nstates = strread(upper(file{x}), '<TRANSP> %d'); 
x = x+1;

if ~include_exit_state
  nstates = nstates-1;
end

  tmp = strread(file{x}, '%f', nstates);
  hmm.priors = log(tmp(2:nstates)'+eps);
  hmm.mix = hmm.priors;

if ~priors_in_transmat
  x = x+1;
  start = 2;
else
  nstates = nstates + 1;
  start = 1;
end

for n = start:nstates
  tmp = strread(file{x}, '%f', nstates);
  if include_exit_state 
    transmat(n-1,:) = tmp(2:end);
  else
    transmat(n-1,:) = tmp(2:end-1);
  end
  x = x+1;
end
hmm.transmat = log(transmat+eps);

if include_exit_state
  hmm.last_state_is_exit_state = 1;
end
