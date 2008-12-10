function h_widget = zooming_scrollbar(h_axis, init_val, callback_fun, location, px_offset)
% scrollbar_handle = zooming_scrollbar(axis_handle, init_val, callback_fun,
%                                      location)
%
% Adds a scrollbar to the given axis that includes scrolling, zooming,
% and reset controls.  init_val = [min_val max_val] controls the
% inital settings of the scrollbar (scaled between 0 and 1).  Every
% time the widget is updated, callback_fun can be used to update the
% given axes.  It is called as follows:
%
% callback_fun(scrollbar_handle, axis_handle, min_val, max_val)
%
% Where min_val and max_val are the current values of the left hand
% and right hand positions of the scrollbar respectively scaled
% between 0 and 1.0.  Any additional state information can be stored
% in the 'UserData' property of the scrollbar_handle.
%
% location controls the position and orientation of the scrollbar
% relative to h_axis.  Valid settings are 'left' or 'right' to create
% a vertial scrollbar or 'top' or 'bottom' to create a horizontal
% scrollbar.  The default setting is 'left'.
%
% Returns a handle to the scrollbar graphics object h.

% Copyright (C) 2008 Ron J. Weiss (ronw@ee.columbia.edu)
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% x(at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

if nargin < 1;  h_axis = gca;  end
if nargin < 2;  init_val = [0 1];  end
if nargin < 3;  callback_fun = @(a,b,c,d) 0;  end
if nargin < 4;  location = 'left';  end
if nargin < 5;  px_offset = 2;  end

if strcmpi(location, 'left') || strcmpi(location, 'right')
  horiz_flag = false;
else
  horiz_flag = true;
end

saved_axis = gca;

h_fig = get(h_axis, 'Parent');

min_val = init_val(1);
max_val = init_val(2);

h_widget = uipanel('Parent', h_fig, 'Tag', 'zooming_scrollbar', ...
    'BorderType', 'none', 'HitTest', 'off');

% Set up other widgets.
h_bar = uipanel('Parent', h_widget, 'BorderType', 'none', ...
    'Tag', 'zooming_scrollbar_widget_wrapper');
% Set up an invisible set of axes to get access to 'CurrentPoint' for
% mouse motion in units relative to barbg's size.  We'll also store
% private UserData for this scrollbar in these axes.
h_ud = axes('Parent', h_bar, 'Visible', 'off', 'HitTest', 'off', ...
    'Tag', 'zooming_scrollbar_background', ...
    'Units', 'normalized', 'Position', [0 0 1.0 1.0], ...
    'XLim', [0 1], 'YLim', [0 1], 'XTick', [], 'YTick', []);
cb = @(a,b) callback_fun(h_widget, h_axis, a, b);
h_barbg = uipanel('Parent', h_bar, ...
    'BackgroundColor', [0.6 0.6 0.6], 'BorderType', 'etchedout', ...
    'Units', 'normalized', 'Position', [0 0 1.0 1.0], ...
    'Tag', 'zooming_scrollbar_background', 'HitTest', 'on', ...
    'ButtonDownFcn', @(a,b) zooming_scrollbar_callback(a, b, h_ud, cb));
h_barfg = uipanel('Parent', h_barbg, ...
    'BackgroundColor', [0.8 0.8 0.8],  'BorderType', 'beveledout', ...
    'Tag', 'zooming_scrollbar_widget', 'HitTest', 'off');

% Other controls
h_reset_btn = uicontrol(h_widget, 'Style', 'pushbutton', ...
    'Tag', 'zooming_scrollbar_button', 'String', 'R', ...
    'Callback', @(a,b) zooming_scrollbar_update(h_ud, cb, min_val, max_val));
h_zout_btn = uicontrol(h_widget, 'Style', 'pushbutton', ...
    'Tag', 'zooming_scrollbar_button', 'String', '-', ...
    'Callback', @(a,b) zoom_out_callback(a, b, h_ud, cb));
h_zin_btn = uicontrol(h_widget, 'Style', 'pushbutton', ...
    'Tag', 'zooming_scrollbar_button', 'String', '+', ...
    'Callback', @(a,b) zoom_in_callback(a, b, h_ud, cb));
dstr = 'v';
ustr = '^';
if horiz_flag
  dstr = '<';
  ustr = '>';
end
h_scrdown_btn = uicontrol(h_widget, 'Style', 'pushbutton', ...
    'Tag', 'zooming_scrollbar_button', 'String', dstr, ...
    'Callback', @(a,b) scroll_down_callback(a, b, h_ud, cb));
h_scrup_btn = uicontrol(h_widget, 'Style', 'pushbutton', ...
    'Tag', 'zooming_scrollbar_button', 'String', ustr, ...
    'Callback', @(a,b) scroll_up_callback(a, b, h_ud, cb));

handles = [h_scrup_btn h_bar h_scrdown_btn h_zout_btn h_zin_btn h_reset_btn];
set(h_widget, 'ResizeFcn', @(a,b) position_widgets(a, b, h_widget, h_axis, ...
    h_fig, handles, location, px_offset))
position_widgets([], [], h_widget, h_axis, h_fig, handles, ...
    location, px_offset);

pack_userdata(h_ud, h_fig, h_widget, h_barfg, h_axis, min_val, max_val, ...
    horiz_flag);
set_position(h_ud, min_val, max_val);

axes(saved_axis)



% FIXME - this function gets called before h_axis is resized so it
% bases itself on the old size (I'm pretty sure).  This is only a
% problem for colorbars but not regular axes for some reason.
function position_widgets(source, eventdata, h_widget, h_axis, h_fig, ...
    handles, location, px_offset)
% Keep the scrollbar height/width and distance from target axis
% constant but let the other dimensions scale with the rest of the
% figure.
fixed_size_px = 19;
fixed_offset_px = px_offset;

% Position overall widget relative to h_axis.
[axis_pos_n axis_pos_px] = get_widget_pos(h_axis);
try
  % Want to avoid axis labels as well.
  [axis_tightinset_n axis_tightinset_px] = get_widget_pos(h_axis, 'TightInset');
catch
  axis_tightinset_n  = [0 0 0 0];
  axis_tightinset_px = [0 0 0 0];
end
axis_pos_px(1:2) = axis_pos_px(1:2) - axis_tightinset_px(1:2);
axis_pos_px(3:4) = axis_pos_px(3:4) + axis_tightinset_px(1:2) ...
    + axis_tightinset_px(3:4);

widget_pos_px = axis_pos_px;
if strcmpi(location, 'bottom')
  orient_idx = [2 1 4 3];
  widget_length_px = axis_pos_px(3);
  widget_pos_px(4) = fixed_size_px;
  widget_pos_px(2) = axis_pos_px(2) - fixed_offset_px - fixed_size_px;
elseif strcmpi(location, 'top')
  orient_idx = [2 1 4 3];
  widget_length_px = axis_pos_px(3);
  widget_pos_px(4) = fixed_size_px;
  widget_pos_px(2) = axis_pos_px(2) + axis_pos_px(4) + fixed_offset_px;
elseif strcmpi(location, 'left')
  orient_idx = [1 2 3 4];
  widget_length_px = axis_pos_px(4);
  widget_pos_px(3) = fixed_size_px;
  widget_pos_px(1) = axis_pos_px(1) - fixed_offset_px - fixed_size_px;
elseif strcmpi(location, 'right')
  orient_idx = [1 2 3 4];
  widget_length_px = axis_pos_px(4);
  widget_pos_px(3) = fixed_size_px;
  widget_pos_px(1) = axis_pos_px(1) + axis_pos_px(3) + fixed_offset_px;
else
  error('zooming_scrollbar: Invalid value for location');
end
% Only draw the controls if there is enough room for them.
if widget_length_px < 5*fixed_size_px + 1
  set(h_widget, 'Visible', 'off')
  return
else
  set(h_widget, 'Visible', 'on')
end

[a old_widget_pos_px] = get_widget_pos(h_widget);
set_widget_pos(h_widget, widget_pos_px, 'pixels', h_fig)

% Position internal widgets from the bottom up.
h_scrup_btn = handles(1);
h_bar = handles(2);
h_scrdown_btn = handles(3);
h_zout_btn = handles(4);
h_zin_btn = handles(5);
h_reset_btn = handles(6);

fixed_size_px = fixed_size_px - 1;
pos = [0 0 fixed_size_px fixed_size_px];
set_widget_pos(h_reset_btn, pos(orient_idx), 'pixels', h_fig)
pos(2) = pos(2) + pos(4);
set_widget_pos(h_zin_btn, pos(orient_idx), 'pixels', h_fig)
pos(2) = pos(2) + pos(4);
set_widget_pos(h_zout_btn, pos(orient_idx), 'pixels', h_fig)
pos(2) = pos(2) + pos(4);
set_widget_pos(h_scrdown_btn, pos(orient_idx), 'pixels', h_fig)
pos(2) = pos(2) + pos(4);
pos(4) = max(widget_length_px - 5*fixed_size_px, 1);
set_widget_pos(h_bar, pos(orient_idx), 'pixels', h_fig)
pos(2) = pos(2) + pos(4);
pos(4) = fixed_size_px;
set_widget_pos(h_scrup_btn, pos(orient_idx), 'pixels', h_fig)



function [pos_n pos_px] = get_widget_pos(h, property)
if nargin < 2;  property = 'Position';  end
old_units = get(h, 'Units');
set(h, 'Units', 'normalized');
pos_n = get(h, property);
set(h, 'Units', 'pixels');
pos_px = get(h, property);
set(h, 'Units', old_units);



function set_widget_pos(h, pos, units, h_fig)
% Make sure its always visible
if strcmpi(units, 'pixels')
  offset = 2;
  lower_limits = [1 1] * offset;
  [tmp fig_pos_px] = get_widget_pos(h_fig);
  upper_limits = fig_pos_px([3 4]) - offset;
elseif strcmpi(units, 'normalized')
  offset = 0;
  lower_limits = [0.0 0.0];
  upper_limits = [1.0 1.0];
end

fixed_pos = pos;
for x = 1:2
  fixed_pos(x) = min(max(lower_limits(x), pos(x)), upper_limits(x));
end
if pos(1) + pos(3) > upper_limits(1)
  fixed_pos(1) = pos(1) - (pos(1) + pos(3) - upper_limits(1)) - offset;
end
if pos(2) + pos(4) > upper_limits(2)
  fixed_pos(2) = pos(2) - (pos(2) + pos(4) - upper_limits(2)) - offset;
end

old_units = get(h, 'Units');
set(h, 'Units', units, 'Position', fixed_pos);
set(h, 'Units', old_units);



function pack_userdata(h_ud, h_fig, h_widget, h_barfg, ...
    h_axis, min_val, max_val, horiz_flag)
set(h_ud, 'UserData', [h_fig h_widget h_barfg h_axis ...
      min_val max_val horiz_flag]);



function [h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
    = unpack_userdata(h_ud)
ud = get(h_ud, 'UserData');
h_fig = ud(1);
h_widget = ud(2);
h_barfg = ud(3);
h_axis = ud(4);
min_val = ud(5);
max_val = ud(6);
horiz_flag = ud(7);



function zooming_scrollbar_callback(source, eventdata, h_ud, cb)
[h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
    = unpack_userdata(h_ud);
% How and where did we click?
pt = get(h_ud, 'CurrentPoint');
if horiz_flag
  click_pt = pt(1,1);
else
  click_pt = pt(1,2);
end
click_pt = max(min(1.0, click_pt), 0.0);

click_type = get(h_fig, 'SelectionType');
[sc_min sc_max] = get_position(h_ud);
if strcmpi(click_type, 'normal')
  if click_pt > sc_max
    scroll_up_callback(source, eventdata, h_ud, cb);
    return
  elseif click_pt < sc_min
    scroll_down_callback(source, eventdata, h_ud, cb);
    return
  end
elseif strcmpi(click_type, 'alt')
  mouse_motion_callback(source, eventdata, h_ud, cb, click_pt, click_type);
else
  return
end

set(h_fig, 'WindowButtonMotionFcn', ...
    @(a,b) mouse_motion_callback(a, b, h_ud, cb, click_pt, click_type));
set(h_fig, 'WindowButtonUpFcn', ...
    @(a,b) reset_mouse_functions(a, b, h_ud, cb, click_pt, click_type))
set(h_barfg, 'BorderType', 'beveledin');
% fprintf('Got %s click at: %f\n', click_type, click_pt)



function reset_mouse_functions(source, eventdata, h_ud, cb, click_pt, ...
    click_type)
[h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
    = unpack_userdata(h_ud);
set(h_fig, 'WindowButtonMotionFcn', []);
set(h_fig, 'WindowButtonUpFcn', []);  
set(h_barfg, 'BorderType', 'beveledout');



function mouse_motion_callback(source, eventdata, h_ud, cb, click_pt, ...
    click_type)
[h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
    = unpack_userdata(h_ud);
[sc_min sc_max] = get_position(h_ud);

pt = get(h_ud, 'CurrentPoint');
if horiz_flag
  curr_pt = pt(1,1);
else
  curr_pt = pt(1,2);
end
% Don't go past the edge of the scrollbar.
curr_pt = max(min(1.0, curr_pt), 0.0);
% fprintf('  Got update at: %f\n', curr_pt)

center = sc_min + (sc_max - sc_min)/2;
if strcmpi(click_type, 'normal')
  % If left click, drag the center of the range to a new value.
  shift = curr_pt - center;
  sc_max = sc_max + shift;
  sc_min = sc_min + shift;
elseif strcmpi(click_type, 'alt')
  % If right click, drag one of the limits to a new value.
  if click_pt > center
    sc_max = curr_pt;
  else
    sc_min = curr_pt;
  end
end
zooming_scrollbar_update(h_ud, cb, sc_min, sc_max);



function zooming_scrollbar_update(h_ud, cb, sc_min, sc_max)
% Only update if we haven't scrolled too far.
if sc_max - sc_min < 0.01
  return
end
if sc_max > 1.0
  sc_min = max(sc_min - (sc_max - 1.0), 0);
  sc_max = 1.0;
end
if sc_min < 0
  sc_max = min(sc_max - sc_min, 1.0);
  sc_min = 0.0;
end
set_position(h_ud, sc_min, sc_max);
feval(cb, sc_min, sc_max);



function set_position(h_ud, sc_min, sc_max);
[h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
      = unpack_userdata(h_ud);
pos = get(h_barfg, 'Position');
new_pos = [pos(1) sc_min pos(3) sc_max-sc_min];
if horiz_flag
  new_pos = [sc_min pos(2) sc_max-sc_min pos(4)];
end
set(h_barfg, 'Position', new_pos);



function [sc_min sc_max] = get_position(h_ud);
[h_fig h_widget h_barfg h_axis min_val max_val horiz_flag] ...
    = unpack_userdata(h_ud);
pos = get(h_barfg, 'Position');
if horiz_flag
  pos = pos([2 1 4 3]);
end
sc_min = pos(2);
sc_max = sc_min + pos(4);



function zoom_out_callback(source, event, h_ud, callback)
ZOOM = 0.9;
[sc_min sc_max] = get_position(h_ud);
range = sc_max - sc_min;
center = sc_min + range / 2;
new_range = range / ZOOM;
new_sc_min = center - new_range/2;
new_sc_max = center + new_range/2;
zooming_scrollbar_update(h_ud, callback, new_sc_min, new_sc_max);



function zoom_in_callback(source, event, h_ud, callback)
ZOOM = 0.9;
[sc_min sc_max] = get_position(h_ud);
range = sc_max - sc_min;
center = sc_min + range / 2;
new_range = range * ZOOM;
new_sc_min = center - new_range/2;
new_sc_max = center + new_range/2;
zooming_scrollbar_update(h_ud, callback, new_sc_min, new_sc_max);



function scroll_up_callback(source, event, h_ud, callback)
SCROLL = 0.05;
[sc_min sc_max] = get_position(h_ud);
zooming_scrollbar_update(h_ud, callback, sc_min + SCROLL, sc_max + SCROLL);



function scroll_down_callback(source, event, h_ud, callback)
SCROLL = 0.05;
[sc_min sc_max] = get_position(h_ud);
zooming_scrollbar_update(h_ud, callback, sc_min - SCROLL, sc_max - SCROLL);
