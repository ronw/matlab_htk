function files = glob(pattern)
% files = glob(pattern)
%
% Returns a cell array containing a list of files that match the given
% pattern.
%
% 2008-04-30 ronw@ee.columbia.edu

files = {};
try
  list_str = ls('-d1', pattern);
  idx = regexp(list_str, '\n');
  files = cell(length(idx), 1);
  last_idx = 1;
  for i = 1:length(idx)
    files{i} = list_str(last_idx:idx(i)-1);
    last_idx = idx(i) + 1;
  end
end

