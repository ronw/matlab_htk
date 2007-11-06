function Y = map(fun, C)
% Y = map(fun, C)
%
% Wrapper around cellfun.  Takes function handle fun and cell array
% C and returns a new cell array that contains the result of
% applying fun to each element of C.
%
% 2007-11-06 ronw@ee.columbia.edu

if ~isa(fun, 'function_handle')
  error('1st argument must be a function handle')
end

if ~iscell(C)
  error('2nd argument must be a cell array.')
end


Y = cellfun(fun, C, 'UniformOutput', 0);
