function make_figure_scrollable(fig_handle)
% make_figure_scrollable(fig_handle)
%
% Adds buttons to the given figure window that let you zoom and pan
% all subplots at once (x axis only).  Based on Michael Mandel's zxi.m
% and panx.m

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

if nargin < 1;  fig_handle = gcf;  end

kZOOM = 1.1; %2;
kPAN  = 0.1; %0.5;

W = 40;
H = 20;

x = 0;
y = 0;
reset_button = uicontrol(fig_handle, 'Style', 'pushbutton', ...
    'String', 'Reset', ...
    'Position', [x y W H], ...
    'Callback', {@(a,b) reset_button_Callback(a, b, fig_handle)});
x = x+W;
zoom_in_button = uicontrol(fig_handle, 'Style', 'pushbutton', ...
    'String', '+', ...
    'Position', [x y W H], ...
    'Callback', {@(a,b) zoom_button_Callback(a, b, fig_handle, kZOOM)});
x = x+W;
zoom_out_button = uicontrol(fig_handle, 'Style', 'pushbutton', ...
    'String', '-', ...
    'Position', [x y W H], ...
    'Callback', {@(a,b) zoom_button_Callback(a, b, fig_handle, 1/kZOOM)});
x = x+W;
scroll_left_button = uicontrol(fig_handle, 'Style', 'pushbutton', ...
    'String', '<-', ...
    'Position', [x y W H], ...
    'Callback', {@(a,b) scroll_button_Callback(a, b, fig_handle, -kPAN)});
x = x+W;
scroll_right_button = uicontrol(fig_handle, 'Style', 'pushbutton', ...
    'String', '->', ...
    'Position', [x y W H], ...
    'Callback', {@(a,b) scroll_button_Callback(a, b, fig_handle, kPAN)});


%align([zoom_in_button, zoom_out_button, ...
%      scroll_left_button, scroll_right_button],'Right','None');

% add figure toolbar back
set(fig_handle, 'Toolbar', 'figure')

% Link axes so that standard zoom/pan controls apply to all axes (but
% not colorbars)
linkaxes(findobj(gcf, 'Type', 'axes', 'Tag', ''))

function reset_button_Callback(source, eventdata, fig_handle)
  kids = findobj(fig_handle, 'Type', 'axes', 'Tag', '');
  for i=1:length(kids)
    xlim(kids(i), 'auto');
  end
function zoom_button_Callback(source, eventdata, fig_handle, times)
  kids = findobj(fig_handle, 'Type', 'axes', 'Tag', '');
  for i=1:length(kids)
    xl = get(kids(i), 'xlim');
    xl2 = [xl(1) (xl(2)-xl(1))/times+xl(1)];
    xlim(kids(i), xl2);
  end
function scroll_button_Callback(source, eventdata, fig_handle, frac) 
  kids = findobj(fig_handle, 'Type', 'axes', 'Tag', '');
  for i=1:length(kids)
    xl = get(kids(i), 'xlim');
    xl2 = xl - (xl(1)-xl(2))*frac;
    xlim(kids(i), xl2);
  end
