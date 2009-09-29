function align_axes(axis_name, all_axes)
% align_axes(axis_name, axes)
%
% Make sure that the given axes are aligned along the given axis_name
% ('x', 'y', 'c', or any combination thereof (e.g. 'xy' which is the
% default)).  If no axis handles are specified all axes in the current
% figure are used.
%
% 2008-12-01 ronw@ee.columbia.edu

if nargin < 1;  axis_name = 'xy';  end
if nargin < 2;  all_axes = findobj(gcf, 'Type', 'axes', 'Tag', '');  end

for n = 1:length(axis_name)
  prop = [axis_name(n) 'lim'];
  l = get(all_axes, prop);
  if ~isempty(l)
    if iscell(l)
      l = cat(1, l{:});
    end
    aligned_lim = [min(l(:,1)) max(l(:,2))];
    set(all_axes, prop, aligned_lim);
  end
end
