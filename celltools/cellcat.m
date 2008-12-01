function c = cellcat(varargin)
% c = cellcat(c1, c2, c3, ..., cn)
%
% Concatenates the concents of each cell array c1, ..., cn into one
% big cell array.

c = {};
for n = 1:length(varargin)
  tmp = varargin{n};
  if ~iscell(tmp)
    tmp = {tmp};
  end
  c = {c{:} tmp{:}};
end
