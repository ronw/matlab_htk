function imgsc(varargin)
% imgsc(data1, data2, ..., datan, property1, value1, property2, value2, ...)
% 
% Plots all of the matrices contained in data1, data2, ...  as
% subplots of the same figure.  Supported data types are: matrices
% (plotted using imagesc), vectors (plotted using plot), and scalars
% (plotted using bar).
%
% A series of name value pairs that correspond to various Matlab plot
% properties can optionally be passed in.  Each property value can be
% either a scalar, in which case the same value is applied to all
% subplots, or a length n cell array which specifies the values for
% each subplot individually.
%
% Supported properties (default value):
% 'align'             ('xy'): set axes to be aligned.  can be any
%                             combination of 'x', 'y', and 'c'
% 'axis'              ('xy'): set axis appearance or scaling
% 'colorbar'          (true): if true displays a colorbar next to each plot
% 'colormap'      (colormap): colormap to use
% 'figure'             (gcf): figure handle
% 'fun'             (@(x) x): function to be applied to each
%                             element of data before plotting
% 'order'                ('r'): ordering of subplots ('r' for row-major order
%                             or 'c' for column-major order)
% 'pub'              (false): If true, try to make nicer looking
%                             plots suitable for publication
% 'subplot'          ([n 1]): subplot arrangement
% 'title'    ({'1','2',...}): cell array of titles for each matrix in data
% 'xlabel'              (''): x axis label
% 'ylabel'              (''): y axis label
%
% Other valid axis properties and values (e.g. 'CLim', 'XLim',
% 'XTick') can be passed in as well.  Furthermore, if the value
% specified for one of these properties is a function that takes no
% arguments, it will be evaluated each time the property is set.  An
% example where this is useful is in adjusting the units of tick
% labels without knowing where the ticks are in advance.  E.g. setting
% 'xticklabel' to @() get(gca, 'xtick')*1e-3 can automatically convert
% the horizontal axis labels from milliseconds to seconds.
% 
% If the 'pub' property is false, additional GUI controls are added to
% the figure, including scrollbars to control panning, zooming, and
% 'caxis' settings.  Also, if n is larger than the number of subplots
% specified in the properties, s, then only s subplots will be
% displayed at a given time, but paging controls will be added to
% figure to give access to the remaining n-s plots.
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

% Apply properties that apply to the entire figure.
try
  % Work on the specified figure without raising it.
  set(0, 'CurrentFigure', properties.figure)
catch
  % Figure didn't exist, need to create it.
  figure(properties.figure)
end

if properties.pub
  clf
end

colormap(properties.colormap)

properties = initialize_subplots(ndat, properties);

% Setup each subplot.
setup_subplots(data, properties, 1);



function setup_subplots(data, properties, curr_page)
ndat = length(data);
nplot = min(ndat, prod(properties.subplot));
npages = ceil(ndat/nplot);
plots = (curr_page-1)*nplot + [1:nplot];


% Pass 0: Hide all subplots.  The ones we use are made visible
% automatically.
for ax = properties.all_axes(:)'
  set(ax, 'Visible', 'off')
  children = get(ax, 'Children');
  set(children, 'Visible', 'off')
end


% Pass 1: plot everything and align axes.
all_axes = [];
all_image_axes = [];
for x = plots
  if x < 1 || x > ndat
    continue;
  end
  
  curr_axes = properties.axes(x);
  axes(curr_axes)
  all_axes = [all_axes curr_axes];
  
  d = squeeze(feval(properties.fun, data{x}));
  if isa(d, 'function_handle')
    feval(d);
  else
    if numel(d) == 1
      bar(d);
      xlim([0 2]);
      grid on
    elseif min(size(d)) == 1
      plot(d)
      xlim([1 length(d)])
      grid on
    else
      a = imagesc(double(d));
      axis(properties.axis)
      all_image_axes = [all_image_axes curr_axes];
    end
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
  if x < 1 || x > length(data)
    continue;
  end
  curr_axes = properties.axes(x);
  axes(curr_axes)

  title(properties.title{x});
  xlabel(properties.xlabel{x});
  ylabel(properties.ylabel{x});

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
      xlabel('')
      set(curr_axes, 'XTickLabel', [])
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
  % Remove all left over uicontrols before we create new ones.
  h = findobj(gcf, 'Type', 'uicontrol', '-or', 'type', 'uipanel');
  delete(h)

  if npages > 1
    add_pager_buttons(data, properties, curr_page)
  end

  make_figure_scrollable(properties.figure, all_axes);
end
%subplot 111



function add_pager_buttons(data, properties, curr_page)
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

pos = [20 20 40 20];
uicontrol('Style', 'pushbutton', 'String', 'First', 'Position', pos, ...
    'Callback', @(a,b) setup_subplots(data, properties, 1));
pos(1) = pos(1) + pos(3);
uicontrol('Style', 'pushbutton', 'String', 'Prev', 'Position', pos, ...
    'Callback', @(a,b) setup_subplots(data, properties, curr_page - 1), ...
    'Enable', enable_prev_button);
pos(1) = pos(1) + pos(3);
pos(3) = 50;
uicontrol('Style', 'edit', 'String', curr_page, 'Position', pos, ...
    'Callback', ...
    @(a,b) setup_subplots(data, properties, str2num(get(a, 'String'))));
pos(1) = pos(1) + pos(3);
uicontrol('Style', 'text', 'String', sprintf(' / %d', npages), ...
    'Position', pos);
pos(1) = pos(1) + pos(3);
pos(3) = 40;
uicontrol('Style', 'pushbutton', 'String', 'Next', 'Position', pos, ...
    'Callback', @(a,b) setup_subplots(data, properties, curr_page + 1), ...
    'Enable', enable_next_button);
pos(1) = pos(1) + pos(3);
uicontrol('Style', 'pushbutton', 'String', 'Last', 'Position', pos, ...
    'Callback', @(a,b) setup_subplots(data, properties, npages));



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
      props.fun, props.order, props.pub, props.subplot, props.title, ...
      props.xlabel, props.ylabel, varargout] = ...
    process_options(option_args, ...
    'align',    'xy', ...
    'axis',     'xy', ...
    'colorbar', true, ...
    'colormap', colormap, ...
    'figure',   gcf, ...
    'fun',      @(x) x, ...
    'order',    'r', ...
    'pub',      false, ...
    'subplot',  [ndat 1], ...
    'title',    cellstr(num2str([1:ndat]')), ...
    'xlabel',   '', ...
    'ylabel',   '');
other_properties = varargout;

per_subplot_fields = {'axis', 'title', 'xlabel', 'ylabel'};
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
all_axes = zeros(nplot, 1);
for x = 1:nplot
  all_axes(x) = subplot(props.subplot(1), props.subplot(2), x);
end
props.all_axes = all_axes;

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
props.axes = all_axes(plot_num);



function align_axes(axis_name, all_axes)
% Make sure that the given axes are aligned along axis_name ('x', 'y', or 'c').
prop = [axis_name 'lim'];
l = get(all_axes, prop);
if ~isempty(l)
  if iscell(l)
    l = cat(1, l{:});
  end
  aligned_lim = [min(l(:,1)) max(l(:,2))];
  set(all_axes, prop, aligned_lim);
end
