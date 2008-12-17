function C = czip(varargin)
% C = czip(cell1, cell2, cell3, ...)
%
% Like Python's zip function. Returns a cell array C containing a list of
% cell arrays such that:
%  C{i} = {cell1{i}, cell2{i}, cell3{i}, ...}
%
% C is truncated to the length of the smallest of the input arrays.

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

len = mapreduce(@length, @(x,y) min(x,y), varargin);
C = cell(len, 1);
for l = 1:len
  for n = 1:nargin
    C{l}{n} = varargin{n}{l};
  end
end
