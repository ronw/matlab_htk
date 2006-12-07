function writehtkhmm(filename, hmm, desc)
% writehtkhmm(filename, hmm, feature_description)
%
% Write the HMM contained in hmm to an HTK formatted file.
%
% 2006-06-13 ronw@ee.columbia.edu

if nargin < 3
  desc = '<USER>';
  %desc = '<MFCC>';
end


nstates = length(hmm.transmat);
if isfield(hmm, 'mu')
  ndim = size(hmm.mu, 1);
else
  gmm = hmm.gmm{1};
  ndim = size(gmm.mu, 1);
end

if isfield(hmm, 'nstates')
  %assert(nstates == hmm.nstates)
  nstates = hmm.nstates;
end
%assert(nstates == length(hmm.priors));

if isfield(hmm, 'name')
  name = ['"' hmm.name '"'];
else 
  name = '"matlabhmm"';
end


fid = fopen(filename, 'w');

fprintf(fid, '~o\n');
%fprintf(fid, '<VecSize> %d\n', ndim);
%%desc = '<NULLD><USER><DIAGC>';
fprintf(fid, '<VecSize> %d %s\n', ndim, desc);

%fprintf(fid, '~h %s\n', name) 
fprintf(fid, '<BeginHMM>\n');
%fprintf(fid, '<VecSize> %d\n', ndim);
%fprintf(fid, '  <VecSize> %d %s\n', ndim, desc);
fprintf(fid, '  <NumStates> %d\n', nstates+2);

for n = 1:nstates
  if isfield(hmm, 'mu')
    fprintf(fid, '  <State> %d\n    <Mean> %d\n     ', n+1, ndim);
    fprintf(fid, ' %f', hmm.mu(:,n));
    fprintf(fid, '\n    <Variance> %d\n     ', ndim);
    fprintf(fid, ' %f', hmm.covar(:,n));
    fprintf(fid, '\n');
  else  % we have GMM emissions
    nmix = hmm.gmm{n}.nmix;
    fprintf(fid, '  <State> %d\n    <NumMixes> %d\n     ', n+1, nmix);
    for m = 1:nmix
      fprintf(fid, '<MIXTURE> %d %f\n', m, hmm.gmm{n}.mix(m));
      fprintf(fid, '  <MEAN> %d\n   ', length(hmm.gmm{n}.mu(:,m)));
      fprintf(fid, ' %f', hmm.gmm{n}.mu(:,m));
      fprintf(fid, '\n  <VARIANCE> %d\n   ', length(hmm.gmm{n}.covar(:,m)));
      fprintf(fid, ' %f', hmm.gmm{n}.covar(:,m));
      fprintf(fid, '\n');
    end
  end
end

% transmat
fprintf(fid, '  <TransP> %d\n', nstates+2);

% the first state is non emitting
transmat = [0, exp(hmm.priors), 0; ...
           zeros(nstates, 1), exp(hmm.transmat), zeros(nstates,1); ...
% the last state is also non emitting
           zeros(1, nstates+2)];

% the last emitting state needs to be able to transition to the
% final non emitting state, so we need to steal some probability
% mass from the other emitting states to give to this one:
% P(exit HMM| in last state) is arbitrarily set to 1/(nstates+1)
transmat(nstates+1, nstates+2) = 1/(nstates+1);
transmat(nstates+1,:) = transmat(nstates+1,:)/sum(transmat(nstates+1,:));


for n = 1:nstates+2
  fprintf(fid, ' %f', transmat(n,:));
  fprintf(fid, '\n'); 
end

fprintf(fid, '<EndHMM>');

fclose(fid);
