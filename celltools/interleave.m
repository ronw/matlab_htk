function C = interleave(varargin)
% C = interleave(cell1, cell2, cell3, ...)
%
% Interleaves the elements of cell1, cell2, cell3, ... in a lazy manner (i.e.
% without making any copies of the elements of celli).  This is similar to 
% Python's zip function (and roughly equivalent to 
% flatten(czip(cell1, cell2, cell3, ...)), except with lazy evaluation).
%
% Note that cell1, cell2, ... must be the same length.

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

lens = cell2mat(map(@length, varargin));
if any(lens ~= lens(1))
  error('Inputs must all have the same length.');
end

len = sum(lens);
C = lazymap(@(x) interleaved_index(varargin, x), crange(len));

function y = interleaved_index(cell_arrays, x)
narrays = length(cell_arrays);
array = mod(x-1, narrays) + 1;
offs = floor((x-1) / narrays) + 1;
y = cell_arrays{array}{offs};
