function hmms = apply_mllr_transform(hmms, W, b)
% recognizer = apply_mllr_transform(recognizer, W, b)
%
% Applies the global MLLR mean transform [W,b] to the recognizer
% parameters.
%
% 2007-02-20 ronw@ee.columbia.edu

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
