function Y = lazymap(fun, C)
% Y = lazymap(fun, C)
%
% Behaves like map/cellfun, but with lazy evaluation.  Returns an
% object that behaves like a cell array with same dimensions as C.
% Whenever an element in y is referenced (e.g. y(10) or y{1:end}) the
% function fun is applied to the corresponding cells of C and the
% result is returned.
%
% Example:
% numbers = {0, 0.5, 1, pi/2, pi, 2*pi};
% y = lazymap(@cos, numbers);
% y(10)   % returns cos(numbers(4))
% y = set(y, 'Function', @sin);
% y{10}   % returns sin(numbers(4))
% y{1:5}  % returns {sin(numbers(1)), sin(numbers(2)), ..., sin(numbers(5))}
%
% This lazy behavior is useful when only some elements of fun(C) are
% needed at any given time.  For example, when extracting features
% from a set of files, a call like:
% features = lazymap(@(x) compute_features(x, param1, param2), filenames)
% can be used to give convenient access to the features of a large
% data set without having to store all of it in memory.
%
% Note that this class doesn't support memoization so subsequent
% references to the same element, e.g. y{1}; y{1};, will result in
% multiple calls to fun(C{1}).
% 
% 2007-11-01 ronw@ee.columbia.edu

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

Y.cellarray = C;
Y.func = fun;

% Can't inherit from built in types...
% y = class(y, 'lazymap', cellarray);
Y = class(Y, 'lazymap');
