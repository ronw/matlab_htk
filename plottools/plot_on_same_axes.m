function plot_on_same_axes(varargin)
% plot_on_same_axes(data1, data2, ...)
% 
% Plots all of data1, data2, ...  on the same axis.

% Copyright (C) 2008 Ron J. Weiss (ronw@ee.columbia.edu)
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
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

plot_args = {};
for n = 1:length(varargin)
  curr = varargin{n};
  if ~iscell(curr)
    curr = {curr};
  end

  for m = 1:length(curr)
    plot_args = {plot_args{:} 1:length(curr{m}) curr{m}};
  end
end

plot(plot_args{:});
grid on
