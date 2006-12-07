function hmm = trainhmmhtk(trdata, nstates, niter, verb, CVPRIOR, mu0, name);
% hmmparams = trainhmmhtk(trdata, nstates, niter, verb, cvprior);
%
%  Train a fully-connected (ergodic) Hidden Markov Model with Gaussian
%  emissions (diagonal covariance) using HTK.
%
% Inputs:
% trdata  - training data (cell array of training sequences, each
%                          column of the sequences arrays contains a
%                          data point in the time series)
% nstates - number of states
% niter   - number of EM iterations to perform
% verb    - set to 1 to output loglik at each iteration
%
% Outputs:
% hmmparams - structure containing hmm parameters learned from training
%             data (hmm.priors, hmm.transmat, hmm.mu(:,1:nstates), 
%             hmm.covar(:,1:nstates))
%
% 2006-06-16 ronw@ee.columbia.edu

if nargin < 3
  niter = 20;
end

if nargin < 4
  verb = 0;
end

if ~iscell(trdata)
  trdata = {trdata};
end

% prior on observation covariances to avoid overfitting:
if nargin < 5
  CVPRIOR = 1;
end

if nargin < 6
  mu0 = [];
end

if nargin >= 7
  hmm.name = name;
end

nseq = length(trdata);
[ndim, nobs(1)] = size(trdata{1});

% initial HMM parameters
hmm.transmat = log(ones(nstates)/nstates);
hmm.priors = log(ones(1, nstates)/nstates);
obsmean = mean(trdata{1},2);

% HInit support is currently broken
use_hinit = 0;

if nargin < 6 | numel(mu0) == 1 & mu0 == 1
  % init using k-means:
  kmeansiter = round(.1*niter)+1;
  rp = randperm(nobs(1));
  % in case there aren't enough observations...
  rp = repmat(rp,1,ceil(nstates/nobs(1)));
  hmm.mu = trdata{1}(:,rp(1:nstates));
  for i = 1:kmeansiter
    % ||x-y || = x^Tx -2x^Ty + y^Ty
    % x^Tx = repmat(sum(x.^2),xc,1);
    % y^Ty = repmat(sum(y.^2),yc,1);
    D = repmat(sum(trdata{1}.^2,1)',1,nstates) - 2*trdata{1}'*hmm.mu ...
        + repmat(sum(hmm.mu.^2,1),nobs(1),1);
    
    %assign each data point to one of the clusters
    [tmp idx] = min(D,[],2);
    
    for k = 1:nstates
      if sum(idx == k) > 0
        hmm.mu(:,k) = mean(trdata{1}(:,idx == k),2);
      end
    end
  end
  
  % keep similar states close together
  x = ordercols(hmm.mu);
  hmm.mu = hmm.mu(:,x);
else
  if size(mu0, 2) == nstates
    hmm.mu = mu0;
  end
end

if numel(mu0) == 1
    use_hinit = mu0;
end

hmm.covar = ones(ndim, nstates);

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
writehtkhmm(hmmfilename, hmm); 

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

system(['HRest ' args ' ' hmmfilename ' ' sprintf('%s ', datafilename{:})]);

if verb
  disp(['******** DONE ********'])
end

% read in hmm:
hmm = readhtkhmm(hmmfilename, 1);

%type(hmmfilename)


% make sure this can be used as GMM as well
gmm = traingmm(cat(2, trdata{:}), nstates, 1, CVPRIOR, 1, 1, hmm.mu, 0, ...
    hmm.covar, 0);
hmm.mix = gmm.mix;


% clean up:
system(['rm ' hmmfilename]);
system(['rm ' sprintf('%s ', datafilename{:})]);

% done.
