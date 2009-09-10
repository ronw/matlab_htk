function Y = cfilter(fun, C)
% Y = cfilter(fun, C)
%
% Returns a cell array only containing elements of C for which fun(C{i}) == 1.
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

if ~iscell(C)
  error('2nd argument must be a cell array.')
end

bool = zeros(size(C));
for n = 1:numel(C)
  bool(n) = feval(fun, C{n});
end
Y = C(bool);
