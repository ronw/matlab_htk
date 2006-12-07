htk_recognizer = trainhtkrecognizer(wordlist, grammar, traindat, traintranscripts, hmmtemplate, nmix);
% recognizer = trainhtkrecognizer(wordlist, grammar, traindat, traintranscripts,
%                                 hmmtemplate, symmap, mnmix)
%
% Use HTK to train a simple HMM speech recognizer.
%
% Inputs:
%  - wordlist         - cell array of words contained in the grammar
%  - grammar          - string containing the HTK grammar of the valid word
%                       sequences accepted by the recognizer
%  - traindat         - cell array of training data
%  - traintranscripts - cell array of string word transcripts of traindat
%  - hmmtemplate*     - hmm structure containing the template
%                       symbol hmm.  Defaults to a 3 state forward
%                       model.
%  - nmix*            - number of mixture components to split each
%                       state into (if hmmtemplate has only single
%                       gaussian emissions).  Defaults to 1.
%
%  * optional argument
%
% Outputs:
%  - recognizer - structure containing the components of an hmm
%                 recognizer:
%                   recog.wordnet - 
%                   recog.hmms    - cell array of HMMs
%                   recog.wordlist - 
%                   recog.
%
% 2006-11-27 ronw@ee.columbia.edu

[ndim, ndat] = size(traindat{1});

if nargin < 5
  hmmtemplate = struct('name', 'template', ...
      'priors', log([1, 0, 0]/3), ...
      'transmat', log(0.5*[1 1 0; 0 1 1; 0 0 2]), ...
      'mu', zeros(ndim, 3), ...
      'covar', ones(ndim, 3));
end
if nargin < 6
  nmix = 1;
end

% write a bunch of files.
wordlist_filename = [get_temp_filename() '.wordlist'];
fid = fopen(wordlist_filename,'w');
fprintf(fid, strvcat(wordlist));
fclose(fid);

grammar_filename = [get_temp_filename() '.grammar'];



