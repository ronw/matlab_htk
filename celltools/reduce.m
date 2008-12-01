function y = reduce(fun, C, initial)
% y = reduce(fun, C, initial)
%
% Reduces the contents of cell array C to a single value by
% accumulating the result of applying binary function fun to elements
% from C.
% e.g. reduce(@plus, {0, 1, 2, 3, 4}) will return 10.
%
% Optional argument initial can be used to set the initial value in
% the accumulator, as if it was prepended to C.
% e.g. reduce(@plus, {0, 1, 2, 3, 4}, 10) will return 20.
%
% 2007-11-06 ronw@ee.columbia.edu

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

if ~isa(fun, 'function_handle')
  error('1st argument must be a function handle')
end

if nargin(fun) > 0 && nargin(fun) ~= 2 
  error('reduce function must take two arguments.');
end

if ~iscell(C)
  error('2nd argument must be a cell array.')
end


if nargin == 3
  y = feval(fun, initial, C{1});
else
  y = C{1};
end

for n = 2:numel(C),
  y = feval(fun, y, C{n});
end
