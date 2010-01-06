function tmpfile = get_temp_filename()
% filename = get_temp_filename()
%
% Returns a unique filename for use as a temp file in /tmp.  This
% assumes that /tmp exists.  
%
% 2006-11-30 ronw@ee.columbia.edu

unique = 1;
while unique == 1
  tmpfile = ['/tmp/matlabtmp', num2str(round(1000*rand(1))), datestr(now,30)];
  files = dir('/tmp');
  unique = ~isempty(strmatch(tmpfile, strvcat(files(:).name), 'exact'));
end                                                                   
