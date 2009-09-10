function files = glob(pattern)
% files = glob(pattern)
%
% Returns a cell array containing a list of files that match the given
% pattern.
%
% 2008-04-30 ronw@ee.columbia.edu

% Copyright (C) 2008 Ron J. Weiss
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

files = glob_with_backoff(pattern);
%files = dirglob(pattern);


function files = dirglob(pattern)
% This function doesn't produce the same output as lsglob:
% 1. If pattern is 'some/path/' lsglob will return a single result while
%    this function will return all files in 'some/path/'.
%    I.e. dirglob('some/path/') is the same as lsglob('some/path/*')
% 2. This doesn't work with nested globs (e.g. 'some/path/*/*.mat')
path = fileparts(pattern);
tmp = dir(pattern);
files = cell(length(tmp), 1);
for n = 1:length(tmp)
  files{n} = fullfile(path, tmp(n).name);
end


function files = lsglob(pattern)
files = {};
list_str = ls('-d1', pattern);
idx = regexp(list_str, '\n');
files = cell(length(idx), 1);
last_idx = 1;
for i = 1:length(idx)
  files{i} = list_str(last_idx:idx(i)-1);
  last_idx = idx(i) + 1;
end


function files = glob_with_backoff(pattern)
try
  files = lsglob(pattern);
catch
  err = lasterror();
  warning(sprintf('Backing off to dir because ls gave a %s error.  Note that this has slightly different behavior so you might not get what you want.', err.identifier))
  files = dirglob(pattern);
end
