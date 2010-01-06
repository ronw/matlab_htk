function write_text_file(filename, txt);
% write_text_file(filename, txt)
%
% write a text file. each element of txt is a line in the file.

fid = fopen(filename, 'w');
for n = 1:length(txt)
  fprintf(fid, '%s\n', txt{n});
end
fclose(fid); 
