function imgsc(data, varargin)
% imgsc(data1, data2, ..., options)
% 
% Plots all of the matrices contained in data1, data2, ...  as
% subplots of the same figure.  varargin takes a series of name value
% pairs that correspond to various Matlab plotting commands.
%
% varargin options (default value):
% 'axis'              ('xy'): set axis appearance or scaling
% 'caxis'  (imagesc default): color axis to use across all subplots
% 'colorbar'             (1): if 1 displays a colorbar next to each plot
% 'colormap'      (colormap): colormap to use
% 'figure'             (gcf): figure handle
% 'subplot'       ([ndat 1]): subplot arrangement
% 'title'    ({'1','2',...}): cell array of titles for each matrix in data
% 'xlabel'              (''): x axis label
% 'xlim'                ([]): x axis limits
% 'xtick'               ([]): x axis tick locations
% 'xticklabel'          ([]): x axis tick labels
% 'ylabel'              (''): y axis label
% 'ylim'                ([]): y axis limits
% 'ytick'               ([]): y axis tick locations
% 'yticklabel'          ([]): y axis tick labels
% 'orient'             ('v'): orientation of subplots ('v' or 'h')
%                             ignored if 'subplot' option is set
%
% 2007-03-12 ronw@ee.columbia.edu

% Copyright (C) 2007-2008 Ron J. Weiss (ronw@ee.columbia.edu)
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

if ~iscell(data)
  data = {data};
end

option_args = {};
for idx = 1:length(varargin)
  d = varargin{idx};

  if ischar(d)
    option_args = varargin(idx:end);
    break;
  elseif iscell(d)
    s = length(data);
    for n = 1:length(d)
      data{s + n} = d{n};
    end
  else
    data{length(data) + 1} = d;
  end
end

ndat = length(data);

[ax, cax, cfun, draw_colorbar, cmap, fig, subp, titles, ...
      xlbls, xlims, xticks, xticklbls, ...
      ylbls, ylims, yticks, yticklbls, ...
      xaxis, yaxis pub orient] = ...
    process_options(option_args, ...
    'axis',       'xy', ...
    'caxis',      {}, ...
    'cellfun',    @(x) x, ...
    'colorbar',   1, ...
    'colormap',   colormap, ...
    'figure',     gcf, ...
    'subplot',    {}, ...
    'title',      cellstr(num2str([1:ndat]')), ...
    'xlabel',     {}, ...
    'xlim',       {}, ...
    'xtick',      {}, ...
    'xticklabel', {}, ...
    'ylabel',     {}, ...
    'ylim',       {}, ...
    'ytick',      {}, ...
    'yticklabel', {}, ...
    'xaxis',      {}, ...
    'yaxis',      {}, ...
    'pub',        0, ...
    'orient',     'v');

if isempty(subp)
  if strcmpi(orient, 'v')
    subp = [ndat 1];
  elseif strcmpi(orient, 'h')
    subp = [1 ndat];
  else
    error(['Invalid option for ''orient'': ' orient]);
  end
end


data = cellfun(cfun, data, 'UniformOutput', false);

if ~iscell(cax),  cax = {cax};  end
if ~iscell(titles),  titles = {titles};  end
if ~iscell(xlbls),  xlbls = {xlbls};  end
if ~iscell(xlims),  xlims = {xlims};  end
if ~iscell(xticks),  xticks = {xticks};  end
if ~iscell(ylbls),  ylbls = {ylbls};  end
if ~iscell(ylims),  ylims = {ylims};  end
if ~iscell(yticks), yticks = {yticks};  end

if ~isempty(xticklbls),  xticklbls = {xticklbls};  end
if ~isempty(yticklbls),  yticklbls = {yticklbls};  end

figure(fig);
if pub, clf; end
colormap(cmap);

for x = 1:ndat
  if ndat > 1, 
    if length(subp) == 1
      subplot(10*subp + x);
    else
      subplot(subp(1), subp(2), x);
    end
  end
  
  if prod(size(data{x})) == 1
    bar(data{x});
    xlim([0 2]);
    grid on
  elseif min(size(data{x})) == 1
    plot(data{x})
    xlim([1 length(data{x})])
    grid on
  else
    imagesc(data{x}); 

    axis(ax);
    if ~isempty(cax),  caxis(cell_index(cax, x));  end
    if draw_colorbar,  colorbar();  end

    if pub 
      if  x <= ndat - subp(2)
        xlabel('')
        set(gca, 'XTickLabel', [])
      end
      
      if subp(2) == 1 && mod(x, subp(1)) ~= (subp(1)-1)/2 + 1
        ylabel('')
      end
    end
  end
  
  if ~isempty(xlbls),  xlabel(cell_index(xlbls, x));  end
  if ~isempty(xlims),  xlim(cell_index(xlims, x));  end
  if ~isempty(xticks),  set(gca, 'xtick', cell_index(xticks, x));  end
  if ~isempty(xticklbls),  set(gca, 'xticklabel', cell_index(xticklbls, x)); end
  if ~isempty(ylbls),  ylabel(cell_index(ylbls, x)); end
  if ~isempty(ylims),  ylim(cell_index(ylims, x));  end
  if ~isempty(yticks),  set(gca, 'ytick', cell_index(yticks, x));  end
  if ~isempty(yticklbls),  set(gca, 'yticklabel', cell_index(yticklbls, x)); end

  title(cell_index(titles, x));
end

if ~pub, make_figure_scrollable(fig); end
subplot 111


function y = cell_index(cell, idx)
% Return the idx'th element of cell unless idx > length(cell) in
% which case return the last element of cell.

y = cell{min(length(cell), idx)};
