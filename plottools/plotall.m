function plotall(varargin)
% plotall(data1, data2, ..., datan, property1, value1, property2, value2, ...)
% 
% Plots all of the matrices contained in data1, data2, ... as subplots
% of the same figure.
%
% A series of name value pairs that correspond to optional settings
% and various Matlab plot properties can optionally be passed in.
%
% Supported properties applied across all subplots (default value):
% 'align'                ('xyc'): set axes to be aligned.  can be any
%                                 combination of 'x', 'y', and 'c'
% 'colorbar'              (true): if true displays a colorbar next to each plot
% 'colormap'          (colormap): colormap to use
% 'figure'                 (gcf): figure handle
% 'fun'                 (@(x) x): function to be applied to each element of
%                                 data before plotting
% 'order'                  ('r'): ordering of subplots ('r' for row-major order
%                                 or 'c' for column-major order)
% 'pub'                  (false): If true, try to make nicer looking
%                                 plots suitable for publication
% 'subplot'              ([n 1]): subplot arrangement
%
% If the 'pub' property is false, additional GUI controls are added to
% the figure, including scrollbars to control panning, zooming, and
% 'caxis' settings.  Also, if n is larger than the number of subplots
% specified in the properties, s, then only s subplots will be
% displayed at a given time, but paging controls will be added to
% figure to give access to the remaining n-s plots.
%
% Supported per-subplot properties (default value):
% 'axis'                  ('xy'): set axis appearance or scaling
% 'plot_fun'  (@plot_or_imagesc): function to use for plotting each element
%                                 of data
% 'title'        ({'1','2',...}): titles for each matrix in data
% 'xlabel'                  (''): x axis label
% 'ylabel'                  (''): y axis label
% 'zlabel'                  (''): z axis label
%
% Other valid per-subplot axis properties and values (e.g. 'CLim',
% 'XLim', 'XTick') can be passed in as well.  
%
% Each per-subplot property value can be either a scalar, in which
% case the same value is applied to all subplots, or a cell array
% which specifies the values for each subplot individually.  Finally
% if value specified for one of these properties is a function that
% takes no arguments, it will be evaluated each time the property is
% set.  For example, is useful for adjusting the units of tick labels
% without knowing where the ticks are in advance.  E.g. setting
% 'xticklabel' to @() get(gca, 'xtick')*1e-3 can automatically convert
% the horizontal axis labels from milliseconds to seconds.
% 
% 2008-11-12 ronw@ee.columbia.edu

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

[data properties] = parse_args(varargin);
ndat = length(data);

try
  % Work on the specified figure without raising it.
  set(0, 'CurrentFigure', properties.figure)
catch
  % Figure didn't exist, need to create it.
  warning('Figure didn''t exist, need to create it.')
  figure(properties.figure)
end

if properties.pub
  clf
end
colormap(properties.colormap)

properties = initialize_subplots(ndat, properties);
plot_page(data, properties, 1)



function [data props] = parse_args(args)
% Some of varargin may contain data to be plotted.  Assume that all
% elements of varargin before the first string consist of data to
% be plotted, and remove those.  The remaining elements are
% properties to be parsed.
option_args = {};
data = args{1};
if ~iscell(data)
  data = {data};
end
for idx = 2:length(args)
  d = args{idx};
  if ischar(d)
    option_args = args(idx:end);
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

props = struct();
[props.align, props.axis, props.colorbar, props.colormap, props.figure, ...
      props.fun, props.order, props.plot_fun, props.pub, props.subplot, ...
      props.title, props.xlabel, props.ylabel, props.zlabel, varargout] = ...
    process_options(option_args, ...
    'align',    'xyc', ...
    'axis',     'xy', ...
    'colorbar', true, ...
    'colormap', colormap, ...
    'figure',   gcf, ...
    'fun',      @(x) x, ...
    'order',    'r', ...
    'plot_fun',     @plot_or_imagesc, ...
    'pub',      false, ...
    'subplot',  [ndat 1], ...
    'title',    cellstr(num2str([1:ndat]')), ...
    'xlabel',   '', ...
    'ylabel',   '', ...
    'zlabel',   '');
other_properties = varargout;

per_subplot_fields = {'axis', 'plot_fun', 'title', 'xlabel', 'ylabel', ...
      'zlabel'};
props = make_properties_the_correct_length(props, per_subplot_fields, ndat);

% Set other properties.
% This doesn't work properly with cell arrays - it converts the struct into
% an array of structs if one of the fields contains a cell array which is
% not what we want.
%props.other = struct(other_properties{:});
[props.other{1:ndat}] = deal(struct());
for x = 1:2:length(other_properties)
  name = other_properties{x};
  value = other_properties{x+1};
  for n = 1:ndat
    curr_value = value;
    if iscell(curr_value)
      if n < length(curr_value)
        curr_value = value{n};
      else
        curr_value = value{end};
      end
    end
    props.other{n} = setfield(props.other{n}, name, curr_value);
  end
end



function props = make_properties_the_correct_length(props, fields, final_len)
for f = 1:length(fields)
  field = fields{f};
  value = getfield(props, field);
  
  if ~iscell(value)
    value = {value};
  end
  % Repeat the final value for all unset plots.
  len = length(value);
  if len < final_len
    [value{len:final_len}] = deal(value{len});
  end
  props = setfield(props, field, value);
end



function props = initialize_subplots(ndat, props)
nplot = prod(props.subplot);
subplots = cell(1, nplot);
for x = 1:nplot
  subplots{x} = {props.subplot(1), props.subplot(2), x};
end
props.subplots = subplots;

if props.order == 'r'
  plot_order = 1:nplot;
elseif props.order == 'c'
  plot_order = reshape(1:nplot, props.subplot([2 1]))';
  plot_order = plot_order(:)';
else
  error(['Unsupported value for ''order'' property.  ' ...
         'Must be either ''r'' or ''c''']);
end

% Only nplot plots can be shown at once.
plot_num = plot_order(mod([1:ndat] - 1, nplot) + 1);
props.subplots = subplots(plot_num);



function plot_page(data, properties, curr_page)
ndat = length(data);
nplot = min(ndat, prod(properties.subplot));
npages = ceil(ndat/nplot);
plots = (curr_page-1)*nplot + [1:nplot];

% Pass 1: plot everything and align axes.
clf

all_axes = [];
all_image_axes = [];
for x = plots
  if x < 1 || x > ndat
    continue;
  end

  d = squeeze(feval(properties.fun, data{x}));
  
  curr_axes = subplot(properties.subplots{x}{:});
  feval(properties.plot_fun{x}, d);

  all_axes = [all_axes curr_axes];
  if length(size(d)) == 2
    all_image_axes = [all_image_axes curr_axes];
  end
end

if regexp(properties.align, 'x', 'ignorecase')
  align_axes('x', all_axes);
end
if regexp(properties.align, 'y', 'ignorecase')
  align_axes('y', all_image_axes);
end
if regexp(properties.align, 'c', 'ignorecase')
  align_axes('c', all_image_axes);
end

% Pass 2: set specified axis properties.
for x = plots
  if x < 1 || x > ndat;
    continue;
  end
  curr_axes = all_axes(x - plots(1) + 1);
  axes(curr_axes)

  axis(properties.axis{x})
  title(properties.title{x});
  xlabel(properties.xlabel{x});
  ylabel(properties.ylabel{x});
  zlabel(properties.zlabel{x});

  other_props = fieldnames(properties.other{x});
  for y = 1:length(other_props)
    try
      name = other_props{y};
      val = properties.other{x}.(name);
      if isa(val, 'function_handle') ...
            && isempty(regexp(name, 'fcn$', 'ignorecase'))
        if nargin(val) == 0
          val = feval(val);
        else
          warning(sprintf(['''%s'' property: function handle values '...
              'must take 0 arguments.'], name))
        end
      end
      set(curr_axes, name, val)
    catch
      warning(sprintf('Unable to set ''%s'' property.', name))
    end
  end
  
  if properties.pub 
    if x <= nplot - properties.subplot(2)
      xlabel('  ')
      %set(curr_axes, 'XTickLabel', ' ')
    end
    
    if properties.subplot(1) == 1 ...
          && mod(x, properties.subplot(1)) ~= (properties.subplot(1)-1)/2 + 1
      ylabel('')
    end
  end
  
  % Draw colorbars on all plots (even if they are not images) to keep
  % axis widths consistent.
  if properties.colorbar
    colorbar()
  end
end

if ~properties.pub
  % Remove all left over pager and pan and zoom controls before we
  % create new ones.
  h = findobj(gcf, 'Type', 'uicontrol', '-or', 'type', 'uipanel');
  h_del = findobj(h, 'Tag', mfilename);
  delete(h_del)
  h = findobj(gcf, 'Type', 'uicontrol', '-or', 'type', 'uipanel');
  h_del = findobj(h, 'Tag', 'add_pan_and_zoom_controls_to_figure');
  delete(h_del)

  if npages > 1
    add_pager_controls(data, properties, curr_page)
  end

  add_pan_and_zoom_controls_to_figure(properties.figure, all_axes);
end
subplot 111



function add_pager_controls(data, properties, curr_page)
ndat = length(data);
nplot = min(ndat, prod(properties.subplot));
npages = ceil(ndat/nplot);

if curr_page == 1
  enable_prev_button = 'off';
else
  enable_prev_button = 'on';
end

if curr_page == npages
  enable_next_button = 'off';
else
  enable_next_button = 'on';
end

h_panel = uipanel('Units', 'normalized', 'Position', [0 1.0 1.0 1.0], ...
    'Tag', mfilename);
pos = [0 0 40 20];
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'First', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) plot_page(data, properties, 1));
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Prev', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) plot_page(data, properties, curr_page - 1), ...
    'Enable', enable_prev_button);
pos(1) = pos(1) + pos(3);
pos(3) = 50;
uicontrol('Parent', h_panel, 'Style', 'edit', 'String', curr_page, ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) plot_page(data, properties, ...
    max(min(str2num(get(a, 'String')), npages), 1)));
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'text', 'String', sprintf(' / %d', npages), ...
    'Position', pos);
pos(1) = pos(1) + pos(3);
pos(3) = 40;
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Next', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) plot_page(data, properties, curr_page + 1), ...
    'Enable', enable_next_button);
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Last', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) plot_page(data, properties, npages));

width_px = pos(1) + pos(3);
height_px = pos(4);
position_pager_controls(h_panel, width_px, height_px)
set(h_panel, 'ResizeFcn', ...
    @(a,b) position_pager_controls(h_panel, width_px, height_px))



function position_pager_controls(h_panel, width_px, height_px)
set(h_panel, 'Units', 'pixels', 'Position', [0 0 width_px height_px])
set(h_panel, 'Units', 'normalized')
pos = get(h_panel, 'Position');
pos(1) = 0;
pos(2) = 1.0 - pos(4);
set(h_panel, 'Position', pos);

