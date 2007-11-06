function varargout = size(C, dim)

if nargin == 1
  [varargout{1:nargout}] = size(C.cellarray);
else
  varargout{1} = size(C.cellarray, dim);
end
