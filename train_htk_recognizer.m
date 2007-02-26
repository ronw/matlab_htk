function htk_recognizer = train_htk_recognizer(traindat, word_list, word_grammar, phone_dict, traintranscripts, hmmtemplate, nmix, verb, traindat_filenames);
% recognizer = train_htk_recognizer(traindat, word_list, word_grammar, dict, traintranscripts,
%                                   hmmtemplate, nmix, verb)
%
% Use HTK to train a simple HMM speech recognizer.
%
% Inputs:
%  - traindat         - cell array of training data (or name of scp
%                       file or cell array containing a list of filenames)
%  - word_list        - cell array of words in the grammar (or filename)
%  - word_grammar     - fsm data structure containing the HTK grammar of word
%                       sequences accepted by the recognizer (or filename)
%  - dict             - phone dictionary - cell array (one word per
%                       element) that translates words into phones (or filename)
%  - traintranscripts - cell array of string word transcripts of
%                       traindat (or filename)
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
%                   recog.hmms       - cell array of HMMs
%                   recog.grammar
%                   recog.word_list
%                   recog.phone_list  
%                   recog.dict
%
% 2006-11-27 ronw@ee.columbia.edu


SCRIPT_DIR = regexp(which('train_htk_recognizer'), '(.+/)[^/]+$', 'tokens');
SCRIPT_DIR = SCRIPT_DIR{1}{1};

% is training data a list of filenames?

traindat_contains_data = 0;
if iscell(traindat)
  traindat_contains_data = ~ischar(traindat{1});
end

if nargin < 6
  % FIXME - this is broken if traindat_contains_data is false
  [ndim, ndat] = size(traindat{1});

  hmmtemplate = struct('name', 'template', ...
      'nstates', 3, ...
      'start_prob', log([1, 0, 0]), ...
      'end_prob', log([0, 0, 0.3]), ...
      'transmat', log(0.5*[1 1 0; 0 1 1; 0 0 1.4]), ...
      'emission_type', 'gaussian',...
      'means', zeros(ndim, 3), ...
      'covars', ones(ndim, 3));
end
if nargin < 7
  nmix = 1;
end
if nargin < 8
  verb = 0;
end

HTK_OPTIONS = '';
if verb
 HTK_OPTIONS = '-A -D ';
end


%%% Setup:
% write a bunch of files.
base_dir = [get_temp_filename() '/'];
mkdir(base_dir);
% place to store the data
mkdir([base_dir '/data']);
filename_prefix = [base_dir 'htk'];


if isstruct(word_grammar)
  grammar_filename = [filename_prefix '.grammar'];
  write_htk_bnf(grammar_filename, word_grammar);
elseif iscellstr(word_grammar)
  grammar_filename = [filename_prefix '.grammar'];
  write_text_file(grammar_filename, word_grammar);
else
  grammar_filename = word_grammar;
  word_grammar = read_text_file(grammar_filename);
end

% dictionary
if iscellstr(phone_dict)
  phone_dict_filename = [filename_prefix '.dict'];
  write_text_file(phone_dict_filename, phone_dict);
else
  phone_dict_filename = phone_dict;
end

% write word list
if iscellstr(word_list)
  word_list_filename = [filename_prefix '.wordlist'];
  write_text_file(word_list_filename, word_list);
else
  word_list_filename = word_list;
  word_list = read_text_file(word_list_filename);
end

% write out training data...
if traindat_contains_data 
  for n = 1:length(traindat)
    if nargin < 9
      traindat_filenames{n} = [base_dir 'data/htkdat_' num2str(n)];
    else
      traindat_filenames{n} = [base_dir 'data/' traindat_filenames{n}];
    end
    
    % custom data format:
    htkcode = 9;  % USER
    htkwrite(traindat{n}', traindat_filenames{n}, htkcode);
  end
else
  if iscell(traindat)
    traindat_filenames = traindat;
  else
    % traindat should contain the name of an HTK .scp file with a list
    % of training data filenames
    traindat_filenames = read_text_file(traindat);
  end
end

% I don't think HTK actually needs the wav file for anything
traindat_featfile = traindat_filenames;
%traindat_featfile{n} = [traindat_filenames{n} ' ' traindat_filenames{n}];

% write .scp file (tells htk where to find feature files)
featfiles = [base_dir 'trainfiles.scp'];
write_text_file(featfiles, traindat_featfile);

% format word transcripts ...
if iscellstr(traintranscripts)
  word_trans_filename = [filename_prefix '.word_transcripts'];
  fid = fopen(word_trans_filename,'w');
  for n = 1:length(traintranscripts)
    if n == 1
      fprintf(fid, '#!MLF!#');
    end
    fprintf('\n\"*/%s\"\n', [traindat_filenames{n} '.lab']);
    str = strread('%s ', traintranscripts{n});
    for word = str
      fprintf(fid, '%s\n', word);
    end
    fprintf(fid, '.\n');
  end
  fclose(fid);
else
  word_trans_filename = traintranscripts;
end

% write HMM template
hmmtemplate.name = 'proto';
hmm_template_filename = [base_dir 'proto'];
write_htk_hmm(hmm_template_filename, hmmtemplate);


%%% Training:
% we're going to use a shell script to do the rest of this
retval = system(['sh ' SCRIPT_DIR 'train_htk_recognizer.sh ' ...
      featfiles ' ' grammar_filename ' ' word_list_filename ' ' ...
      phone_dict_filename ' ' word_trans_filename ' ' ...
      hmm_template_filename ' ' num2str(nmix) ' ' base_dir ...
      ' "' HTK_OPTIONS '"']);

if retval ~= 0
  %rmdir(base_dir, 's');
  error('HTK error!');
end


%%% Output:
htk_recognizer.hmms = read_htk_hmm([base_dir 'hmm_final/hmmdefs']);
htk_recognizer.grammar = word_grammar;
htk_recognizer.word_list = word_list;
htk_recognizer.phone_list = read_text_file([base_dir 'monophones0']);
% only include words in the grammar, so read the right file
htk_recognizer.dict = read_text_file([base_dir 'dict']);

rmdir(base_dir, 's');

