function c = crange(arg1, arg2, arg3)
% c = crange(last)
% c = crange(first, last)
% c = crange(first, step, last)
%
% Creates a cell array containing a range of numbers.  Analagous to
% c = first:step:last
% but creates a cell array instead of a normal matlab matrix.  If
% either first or step are not specified, they each default to 1.

if nargin == 1
  first = 1;
  step = 1;
  last = arg1;
elseif nargin == 2
  first = arg1;
  step = 1;
  last = arg2;
elseif nargin == 3
  first = arg1;
  step = arg2;
  last = arg3;
end

c = num2cell(first:step:last);
