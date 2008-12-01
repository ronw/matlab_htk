function out_struct = sfilter(struct, varargin);
% out_struct = sfilter(struct, 'field1', val1, 'field2', val2, ...)
%
% Filters the given struct array to only include those that match all
% of the given field, value pairs.
%
% 2008-10-27 ronw@ee.columbia.edu

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

fields = varargin(1:2:end);
values = varargin(2:2:end);
nfields = length(fields);

idx = 1;
for x = 1:length(struct)
  include_this_struct = true;
  for y = 1:length(fields)
    tmp = getfield(struct(x), fields{y});
    if (isstr(tmp) && ~strcmp(tmp, values{y})) || any(tmp ~= values{y})
      include_this_struct = false;
      break;
    end
  end
  if include_this_struct
    out_struct(idx) = struct(x);
    idx = idx + 1;
  end
end

if ~exist('out_struct', 'var')
  out_struct = [];
end
