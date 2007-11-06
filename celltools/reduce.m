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

if ~isa(fun, 'function_handle')
  error('1st argument must be a function handle')
end

if nargin(fun) ~= 2
  error('reduce function must take two arguments.');
end

if ~iscell(C)
  error('2nd argument must be a cell array.')
end


if nargin == 3
  y = fun(initial, C{1});
else
  y = C{1};
end

for n = 2:numel(C),
  y = fun(y, C{n});
end
