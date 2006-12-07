function hmm = train_hmm_htk(trdata, hmm, niter, verb, CVPRIOR);
% hmmparams = train_hmm_htk(trdata, hmm_template, niter, verb, cvprior);
%
%  Train a Hidden Markov Model using HTK.  hmm_template defines the
%  initial HMM parameters (number of states, emission type, initial
%  transition matrix...).  
%
%  Note that as of 2006-12-07 GMM support is completely untested
%
% Inputs:
% trdata  - training data (cell array of training sequences, each
%                          column of the sequences arrays contains a
%                          data point in the time series)
% hmm_template - structure defining the initial HMM parameters:
%        .nstates       -  number of states.  Defaults to 2
%        .emission_type - 'gaussian' or 'GMM'.  Defaults to
%                         'gaussian'
%        .transmat      - initial transition matrix (log
%                          probabilities).  Defaults to fully
%                          connected 
% niter   - number of EM iterations to perform.  Defaults to 10
% verb    - set to 1 to output loglik at each iteration
%
% Outputs:
% hmmparams - structure containing hmm parameters learned from the training
%             data 
%
% 2006-06-16 ronw@ee.columbia.edu

HRest_path = '~drspeech/opt/htk/bin.linux/HRest';

DEFAULT_NMIX = 2;

if nargin < 2
  hmm.nstates = 2;
end

if nargin < 3
  niter = 10;
end

if nargin < 4
  verb = 0;
end

% prior on observation covariances to avoid overfitting:
if nargin < 5
  CVPRIOR = 1;
end


if ~iscell(trdata)
  trdata = {trdata};
end
nseq = length(trdata);
[ndim, nobs(1)] = size(trdata{1});

% HInit support is currently broken
use_hinit = 0;


% default hmm parameters
nstates = hmm_template.nstates;
if ~isfield(hmm, 'emission_type')
  hmm.emission_type = 'gaussian';
end
if ~isfield(hmm, 'transmat')
  hmm.transmat = log(ones(nstates)/nstates);
end
if ~isfield(hmm, 'start_prob')
  hmm.start_prob = log(ones(1, nstates)/nstates);
end
if ~isfield(hmm, 'end_prob')
  hmm.end_prob = log(ones(1, nstates)/nstates);
end
if strcmp(hmm.emission_type, 'gaussian') & ~isfield(hmm, 'means')
  % init using k-means:
  kmeansiter = round(.1*niter)+1;
  rp = randperm(nobs(1));
  % in case there aren't enough observations...
  rp = repmat(rp,1,ceil(nstates/nobs(1)));
  hmm.means = trdata{1}(:,rp(1:nstates));
  for i = 1:kmeansiter
    % ||x-y || = x^Tx -2x^Ty + y^Ty
    % x^Tx = repmat(sum(x.^2),xc,1);
    % y^Ty = repmat(sum(y.^2),yc,1);
    D = repmat(sum(trdata{1}.^2,1)',1,nstates) - 2*trdata{1}'*hmm.means ...
        + repmat(sum(hmm.means.^2,1),nobs(1),1);
    
    %assign each data point to one of the clusters
    [tmp idx] = min(D,[],2);
    
    for k = 1:nstates
      if sum(idx == k) > 0
        hmm.means(:,k) = mean(trdata{1}(:,idx == k),2);
      end
    end
  end
end
if strcmp(hmm.emission_type, 'gaussian') & ~isfield(hmm, 'covars')
  hmm.covars = ones(ndim, nstates);
end
if strcmp(hmm.emission_type, 'GMM') & ~isfield(hmm, 'gmms')
  [hmm.gmms{1:nstates}] = deal(default_gmm);
end


% write temp files for each sequence

% Temporary file to use
rnd = num2str(round(1000*rand(1)));
for n = 1:length(trdata)
  datafilename{n} = ['/tmp/matlabtmp_htkdat_' rnd '_' num2str(n) ...
        '.dat']; 

  % custom data format:
  htkcode = 9;  % USER
  %htkcode = 6;  % MFCC
  htkwrite(trdata{n}', datafilename{n}, htkcode);
end

% initial HTK HMM: HInit/HCompV? 
hmmfilename = ['/tmp/matlabtmp_htkhmm_' rnd];
write_htk_hmm(hmmfilename, hmm); 

if use_hinit
  args = ['-i ' num2str(niter) ' -v ' num2str(CVPRIOR)];
  args = [args ' -T 1'];
  if verb > 1
    args = [args ' -A -V -D'];
  end
  disp('running HInit...');
  datestr(now)
  system(['HInit ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);
  datestr(now)
  disp('done.');
end 

% run HRest to train:
%system(['HRest -A -D -T 1777 -t ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);
args = ['-t -M /tmp -i ' num2str(niter) ' -v ' num2str(CVPRIOR)];
if verb
  args = [args ' -T 3'];
  if verb > 1
    args = [args ' -A -V -D'];
  end
end

system([HRest_path ' ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);

if verb
  disp(['******** DONE ********'])
end

% read in hmm:
hmm = read_htk_hmm(hmmfilename, 1);

% clean up:
system(['rm ' hmmfilename]);
system(['rm ' sprintf('%s ', datafilename{:})]);

% done.
