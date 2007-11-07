function varargout = map(fun, varargin)
% Y = map(fun, C)
%
% Wrapper around cellfun.  Takes function handle fun and cell array
% C and returns a new cell array that contains the result of
% applying fun to each element of C.
% 
% If fun takes N arguments, map must be passed N cell arrays
% corresponding to those N arguments:
% Y = map(fun, C1, C2, C3, ...);
% Each input cell array must have the same size.
%
% Similarly, map can handle functions that have multiple outputs. If
% called like this:
% [Y1, Y2, Y3, ...] = map(fun, C)
% Y1, Y2, ... will each be a cell array containing the analogous
% outputs of fun.
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

if ~iscell(varargin{1})
  error('2nd argument must be a cell array.')
end


[varargout{1:nargout}] = cellfun(fun, varargin{:}, 'UniformOutput', 0);
