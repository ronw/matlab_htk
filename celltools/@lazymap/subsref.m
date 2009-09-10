function varargout = subsref(C, S);

if S.type == '.'
  error('Attempt to reference field of non-structure array.');
end

tmpS = S;
tmpS.type = '()';
B = subsref(C.cellarray, tmpS);
B = cellfun(C.func, B, 'UniformOutput', 0);

if S.type == '{}'
  varargout = B;
else
  varargout{1} = B;
end

