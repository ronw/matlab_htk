function h_out = plot_or_imagesc(data)
% h = plot_or_imagesc(data)
% 
% If data is a matrix, imagesc it.  If data is a vector, plot it.  If
% data is a scalar, bar it (I'm not sure why you would want to do this
% though).  Adds grid lines if data is not a matrix.

% Copyright (C) 2008 Ron J. Weiss (ronw@ee.columbia.edu)
%
% This program is free software: you can redistribute it and/or modify
% it under )the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

if isscalar(data)
  h = bar(data);
  xlim([0 2]);
  grid on
elseif isvector(data)
  h = plot(data);
  xlim([1 length(data)])
  grid on
elseif length(size(data)) == 2
  h = imagesc(double(data));
else
  error('Does not support tensors.')
end

if nargout > 0
  h_out = h;
end
