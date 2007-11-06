function txt = read_text_file(filename);
% txt = read_text_file(filename);
%
% Read a text file into a cell array (each element of the array is
% one line in the text file).

fid = fopen(filename, 'r');
txt = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '', 'bufSize', 16000);
fclose(fid);
txt = txt{1};
