function y = flatten(x)
% y = flatten(x)
%
% Takes a cell array x that contains nested cell arrays and
% flattens the contents into a single cell array.
% E.g. flatten({1, {2, 3, {4}, 5}}) returns {1, 2, 3, 4, 5}

if ~iscell(x)
  error('flatten only works on cell arrays.');
end

y = inner_flatten(x);


function y = inner_flatten(x)
if ~iscell(x)
  y = {x};
else
  y = {};
  for n = 1:length(x)
    tmp = inner_flatten(x{n});
    y = {y{:} tmp{:}};
  end
end
