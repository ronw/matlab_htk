function Y = cfilter(fun, C)
% Y = cfilter(fun, C)
%
% Returns a cell array only containing elements of C for which fun(C{i}) == 1.
%
% 2007-11-06 ronw@ee.columbia.edu

if ~isa(fun, 'function_handle')
  error('1st argument must be a function handle')
end

if ~iscell(C)
  error('2nd argument must be a cell array.')
end


bool = cellfun(fun, C, 'UniformOutput', 1);

if ~islogical(bool),
  error('filter function must return a logical array');
end

Y = C(bool);
