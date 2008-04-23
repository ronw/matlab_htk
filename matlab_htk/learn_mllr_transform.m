function [W b] = learn_mllr_transform(recognizer, adapt_dat, word_trans, verb);
% [W b] = learn_mllr_transform(recognizer, adaptation_data,
%                                  word_transcripts, verb)
%
% Use HTK to learn a global MLLR mean transform from adaptation_data
%
% 2007-02-13 ronw@ee.columbia.edu

% Copyright (C) 2007 Ron J. Weiss
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

% is adaptation data a list of filenames?
adapt_dat_contains_data = 0;
if iscell(adapt_dat)
  adapt_dat_contains_data = ~ischar(adapt_dat{1});
end
if nargin < 4
  verb = 0;
end

HTK_OPTIONS = '';
if verb
 HTK_OPTIONS = '-A -D';
 
 if verb >= 2
   HTK_OPTIONS = [HTK_OPTIONS ' -T 1'];
 end
end


%%% Setup:
% write a bunch of files.
base_dir = [get_temp_filename() '/'];
mkdir(base_dir);
% place to store the data
mkdir([base_dir '/data']);
filename_prefix = [base_dir 'htk'];

if isstruct(recognizer.grammar)
  grammar_filename = [filename_prefix '.grammar'];
  write_htk_bnf(grammar_filename, recognizer.grammar);
elseif iscellstr(recognizer.grammar)
  grammar_filename = [filename_prefix '.grammar'];
  write_text_file(grammar_filename, recognizer.grammar);
else
  grammar_filename = recognizer.grammar;
end

% dictionary
if iscellstr(recognizer.dict)
  phone_dict_filename = [filename_prefix '.dict'];
  write_text_file(phone_dict_filename, recognizer.dict);
else
  phone_dict_filename = recognizer.dict;
end

% write phone list
if iscellstr(recognizer.phone_list)
  phone_list_filename = [filename_prefix '.phonelist'];
  write_text_file(phone_list_filename, recognizer.phone_list);
else
  phone_list_filename = recognizer.phone_list;
end

% format word transcripts ...
if iscellstr(word_trans)
  word_trans_filename = [filename_prefix '.word_transcripts'];
  fid = fopen(word_trans_filename,'w');
  for n = 1:length(word_trans)
    if n == 1
      fprintf(fid, '#!MLF!#');
    end
    fprintf('\n\"*/%s\"\n', [adapt_dat_filenames{n} '.lab']);
    str = strread('%s ', word_trans{n});
    for word = str
      fprintf(fid, '%s\n', word);
    end
    fprintf(fid, '.\n');
  end
  fclose(fid);
else
  word_trans_filename = word_trans;
end

% Write MMF file with phone HMMs
mmf_filename = [base_dir 'hmmdefs'];
write_htk_hmm(mmf_filename, recognizer.hmms);

% write out adaptation data...
if adapt_dat_contains_data 
  for n = 1:length(adapt_dat)
    if nargin < 9
      adapt_dat_filenames{n} = [base_dir 'data/htkdat_' num2str(n)];
    else
      adapt_dat_filenames{n} = [base_dir 'data/' adapt_dat_filenames{n}];
    end
    
    % custom data format:
    htkcode = 9;  % USER
    htkwrite(adapt_dat{n}', adapt_dat_filenames{n}, htkcode);
  end
else
  if iscell(adapt_dat)
    adapt_dat_filenames = adapt_dat;
  else
    % adapt_dat should contain the name of an HTK .scp file with a list
    % of adapting data filenames
    adapt_dat_filenames = read_text_file(adapt_dat);
  end
end

% write .scp file (tells htk where to find feature files)
featfiles = [base_dir 'adaptfiles.scp'];
write_text_file(featfiles, adapt_dat_filenames);



%%% Adapting:

% 1. force align adapt_dat using recognizer
alignment_filename = [base_dir 'aligned_phones.mlf'];

retval = system([get_htk_path 'HVite ' HTK_OPTIONS ' -l ''*'' -o SWT -a ' ...
      '-H ' mmf_filename ' -i ' alignment_filename ...
      ' -m -t 250.0 10000.0 500000.0 -I ' ...
      word_trans_filename ' -y lab -S ' featfiles ' ' phone_dict_filename ...
      ' ' phone_list_filename]);


% ~/dl/htk-3.4/HTKTools/HERest -A -V -T 1 -C config  -S ...
%    adaptfiles.scp  -I aligned_phones.mlf -H hmmdefs -u a -z TMF
%    htk.phonelist 

% config:
config{1} = 'HADAPT:TRANSKIND         = MLLRMEAN';
config{2} = 'HADAPT:USEBIAS           = TRUE';
config{3} = 'HADAPT:BASECLASS         = global';
config{4} = 'HADAPT:ADAPTKIND         = BASE';
config{5} = 'HADAPT:KEEPXFORMDISTINCT = FALSE';
config{6} = 'HADAPT:TRACE   = 61';
config{7} = 'HMODEL:TRACE   = 512';
config_file = [base_dir 'config'];
write_text_file(config_file, config);

% global:
nstates = max([recognizer.hmms.nstates]);
if strcmp(recognizer.hmms(1).emission_type, 'GMM');
  nmix = max([recognizer.hmms(1).gmms.nmix]);
else
  nmix = 1;
end
global_conf{1} = '~b "global"';
global_conf{2} = '<MMFIDMASK> *';
global_conf{3} = '<PARAMETERS> MIXBASE';
global_conf{4} = '<NUMCLASSES> 1';
global_conf{5} = ['  <CLASS> 1 {*.state[2-' num2str(nstates+1) ...
      '].mix[1-' num2str(nmix) ']}'];
global_file =  [base_dir 'global'];
write_text_file(global_file, global_conf);

transform_filename = [base_dir 'transform']

% ~/dl/htk-3.4/HTKTools/HERest -A -V -T 1 -C config  -S ...
%    adaptfiles.scp  -I aligned_phones.mlf -H hmmdefs -u a -z TMF htk.phonelist 
%retval = system([get_htk_path 'HERest ' HTK_OPTIONS ...
HTK_3_4_DIR = '~ronw/dl/htk-3.4/HTKTools/';
retval = system([HTK_3_4_DIR 'HERest ' HTK_OPTIONS ...
      ' -t 250.0 5000.0 50000.0 -C ' ...
      config_file ' -S ' featfiles ' -I ' alignment_filename ' -H ' ...
      mmf_filename ' -H ' global_file ' -u a -z ' ...
      transform_filename ' ' phone_list_filename]);

if retval ~= 0
  %rmdir(base_dir, 's');
  error('HTK error!');  
end


%%% Output:

% parse transform_filename
tfm = read_text_file(transform_filename);
bias_offset = strmatch('<BIAS>', tfm) + 1;
ndim = sscanf(tfm{bias_offset-1}, '<BIAS> %d');
b = sscanf(tfm{bias_offset}, ' %f');

tfm_offset = strmatch('<XFORM>', tfm);
W = zeros(ndim);
for r = 1:ndim
  W(r,:) = sscanf(tfm{tfm_offset+r}, ' %f');
end

rmdir(base_dir, 's');

