function e = end(C, k, n)

if n == 1
  e = numel(C.cellarray);
else
  e = size(C.cellarray, k);
end
