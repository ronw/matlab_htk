function y = mapreduce(mapfun, reducefun, C, initial)
% y = mapreduce(mapfun, reducefun, C, initial)
%
% Combines map and reduce into a single operation.  First run mapfun
% on each element of cell array C, then reduce the result to a single
% element.  This is essentially syntactic sugar for:
%   reduce(reducefun, map(mapfun, C), initial)
%
% 2007-11-13 ronw@ee.columbia.edu

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

if ~isa(reducefun, 'function_handle') || ~isa(mapfun, 'function_handle') 
  error('1st two arguments must be function handles.')
end

if nargin(reducefun) > 0 && nargin(reducefun) ~= 2 
  error('reduce function must take two arguments.');
end

if ~iscell(C)
  error('3rd argument must be a cell array.')
end

y = feval(mapfun, C{1});
if nargin == 4
  y = reducefun(initial, y);
end

for n = 2:numel(C),
  y = feval(reducefun, y, feval(mapfun, C{n}));
end
