function gmm = traingmmhtk(trdata, nmix, niter, verb, CVPRIOR, mu0);
% gmmparams = traingmmhtk(trdata, nmix, niter, verb, cvprior, mu0);
%
% Train a GMM with diagonal covariance using HTK.
%
% Inputs:
% trdata - training data (cell array of training sequences, each
%                         column of the sequences arrays contains ana
%                         observation)
% nmix   - number of mixture components
% niter  - number of EM iterations to perform
% verb   - set to 1 to output loglik at each iteration
%
% Outputs:
% gmmparams - structure containing hmm parameters learned from training
%             data (gmm.mix, gmm.mu(:,1:nmix), gmm.covar(:,1:nmix))
%
% 2006-12-06 ronw@ee.columbia.edu


% based on trainhmmhtk.m

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

nseq = length(trdata);
[ndim, nobs(1)] = size(trdata{1});

% initial HMM parameters
hmm.transmat = 0;
hmm.priors = 0;
obsmean = mean(trdata{1},2);
% uniform prior
gmm.mix = ones(1, nmix)/nmix;
gmm.nmix = nmix;

if nargin < 6 | numel(mu0) == 1 & mu0 == 1
  % init using k-means:
  kmeansiter = round(.1*niter)+1;
  rp = randperm(nobs(1));
  % in case there aren't enough observations...
  rp = repmat(rp,1,ceil(nmix/nobs(1)));
  gmm.mu = trdata{1}(:,rp(1:nmix));
  for i = 1:kmeansiter
    % ||x-y || = x^Tx -2x^Ty + y^Ty
    % x^Tx = repmat(sum(x.^2),xc,1);
    % y^Ty = repmat(sum(y.^2),yc,1);
    D = repmat(sum(trdata{1}.^2,1)',1,nmix) - 2*trdata{1}'*gmm.mu ...
        + repmat(sum(gmm.mu.^2,1),nobs(1),1);
    
    %assign each data point to one of the clusters
    [tmp idx] = min(D,[],2);
    
    for k = 1:nmix
      if sum(idx == k) > 0
        gmm.mu(:,k) = mean(trdata{1}(:,idx == k),2);
      end
    end
  end
  
  % keep similar states close together
  x = ordercols(gmm.mu);
  gmm.mu = gmm.mu(:,x);
else
  if size(mu0, 2) == nmix
    gmm.mu = mu0;
  end
end

gmm.covar = ones(ndim, nmix);
hmm.gmm = {gmm};

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
use_hinit = 0;
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
hmm = readhtkhmm(hmmfilename);
gmm = hmm.gmm{1};

% clean up:
system(['rm ' hmmfilename]);
system(['rm ' sprintf('%s ', datafilename{:})]);

% done.
