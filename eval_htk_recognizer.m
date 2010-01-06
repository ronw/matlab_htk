function [word_seq, wer, confmat] = eval_htk_recognizer(recognizer, data, data_filenames, transcript_mlf);
% word_seq = eval_htk_recognizer(recog, data)
%
% Evaluates HTK speech recognizer recog on the sequence of
% observations contained in data.  
%
% Data can be a cell array, in which case word_seq will also be a cell
% array.  If word transcripts are passed in then the word error rate
% (WER) and a confusion matrix (confmat) will be output as well.
%
% 2007-01-17  ronw@ee.columbia.edu

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

if isstr(data)
  % data contains the name of an SCP file
  data = read_text_file(data);
end

if ~iscell(data)
  data = {data};
end

%%%% Write out the recognizer components:

filename_prefix = [get_temp_filename() '/'];
mkdir(filename_prefix);

% hmms:
if isstruct(recognizer.hmms)
  hmm_filename = [filename_prefix 'hmm'];
  write_htk_hmm(hmm_filename, recognizer.hmms);
else
  hmm_filename = recgnizer.hmms;
end

dict_filename = load_file(recognizer.dict, [filename_prefix 'dict']);

word_list_filename = load_file(recognizer.word_list, ...
    [filename_prefix 'word_list']);

phone_list_filename = load_file(recognizer.phone_list, ...
    [filename_prefix 'phone_list']);

% convert grammar into an HTK word network
grammar_filename = [filename_prefix 'grammar'];
if iscellstr(recognizer.grammar)
  write_text_file(grammar_filename, recognizer.grammar); 
elseif isstruct(recognizer.grammar)
  write_htk_bnf(grammar_filename, recognizer.grammar);
else
  grammar_filename = recognizer.grammar;
end

wdnet_filename = [filename_prefix, 'wdnet'];
system([get_htk_path 'HParse ' grammar_filename ' ' wdnet_filename]);

output_mlf = [filename_prefix 'output.mlf'];
fid = fopen(output_mlf, 'w');
fprintf(fid, '#!MLF!#\n');
for n = 1:length(data)
  if ~isstr(data{n})
    % write out data:
    if nargin < 3
      data_filename = [filename_prefix 'data_' num2str(n)];
    else
      data_filename = [filename_prefix data_filenames{n}];
    end

    htkcode = 9;  % USER
    htkwrite(data{n}', data_filename, htkcode);
  else
    data_filename = data{n};
  end

  scp_filename = [filename_prefix 'scp'];
  write_text_file(scp_filename, {data_filename});

  % do Viterbi decode
  %HVite -C config -w wdnet -s 5.0 -p 0.0 -l '*' -H hmm$HMM/hmmdefs ...
  %  -H  hmm$HMM/macros -i $TRAINEVAL -S $TRAINFILE dict monophones1 
%  [error_code word_seq{n}] = system([get_htk_path 'HVite -w ' wdnet_filename ...
%        ' -s 5.0 -p 0.0 -H ' hmm_filename ' ' data_filename ...
%        ' ' dict_filename ' ' phone_list_filename]);


  output_filename = [filename_prefix 'out.mlf'];

  [error_code out] = system([get_htk_path 'HVite -H ' hmm_filename ...
        ' -S ' scp_filename ' -i ' output_filename ...
        ' -l ''*'' -w ' wdnet_filename ' -p 0.0 -s 5.0 ' ...
        dict_filename ' ' phone_list_filename]);
  disp(out);

  word_seq{n} = read_text_file(output_filename);
  for l = 2:length(word_seq{n})
    fprintf(fid, '%s\n', word_seq{n}{l});
  end

  %delete(output_filename);
  %delete(data_filename);

  if error_code ~= 0
    error('HTK error!');
  end
end
fclose(fid);

if length(word_seq) == 1
  word_seq = word_seq{1};
end

if nargin > 3 
  [error_code, out] = system([get_htk_path 'HResults -p -I ' transcript_mlf ' ' ...
        word_list_filename ' ' output_mlf]);

  tok = regexp(out, '\sAcc=(\S+)\s', 'tokens', 'once');, 
  if length(tok) > 0
    wer = 1 - str2num(tok{1})/100;
  else
    wer = 1;
  end

  confmat = out;
end

% clean up
rmdir(filename_prefix, 's');


%%%%%%%%
function filename = load_file(f, default_filename)

if iscellstr(f)
  filename = default_filename;
  write_text_file(filename, f);
else
  filename = f;
end
