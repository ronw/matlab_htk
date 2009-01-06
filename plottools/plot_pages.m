function plot_pages(page_funs, page_names)
% plot_pages({page1_fun, page2_fun, page3_fun, ...})
% 
% Sets up a figure with controls that allow browsing across number of
% "pages" drawn up by the given function handles.
%
% Each entry of the {page_funi} cell array should be a function handle
% to a function that takes no arguments and draws the contents of a
% particular page.
%
% E.g.  plot_pages({@() plot(x, y), @() imagesc(rand(100))})
%
% will setup a figure containing plot(x,y) and controls that allow the
% user to switch to the next page.  When the "Next" button is clicked,
% the figure will be redrawn to contain a random 100x100 pixel image.
%
% Note that the pagei_fun is called every time the user switches to
% page i.  So in the previous example, the random image will change
% every time page 2 is redrawn (by interacting with the paging
% controls, not by underlying GUI updates).
%
% 2008-12-22 ronw@ee.columbia.edu

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

if nargin < 2;  page_names = {};  end

draw_page(page_funs, page_names, 1);


function draw_page(page_funs, page_names, page_num)
npages = length(page_funs);

if nargin(page_funs{page_num}) > 0
  warning(sprintf('Cannot draw page %d. Invalid drawing function: %s.', ...
      page_num, func2str(page_funs{page_num})))
  return
end

clf
feval(page_funs{page_num});

if npages == 1
  return
end

if page_num == 1
  enable_prev_button = 'off';
else
  enable_prev_button = 'on';
end

if page_num == npages
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
    'Callback', @(a,b) draw_page(page_funs, page_names, 1));
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Prev', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) draw_page(page_funs, page_names, page_num-1), ...
    'Enable', enable_prev_button);
pos(1) = pos(1) + pos(3);
pos(3) = 50;
uicontrol('Parent', h_panel, 'Style', 'edit', 'String', page_num, ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) draw_page(page_funs, page_names, ...
    max(min(str2num(get(a, 'String')), npages), 1)));
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'text', ...
    'Tag', mfilename, ...
    'String', sprintf(' / %d', npages), 'Position', pos);
pos(1) = pos(1) + pos(3);
pos(3) = 40;
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Next', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) draw_page(page_funs, page_names, page_num+1), ...
    'Enable', enable_next_button);
pos(1) = pos(1) + pos(3);
uicontrol('Parent', h_panel, 'Style', 'pushbutton', 'String', 'Last', ...
    'Tag', mfilename, ...
    'Units', 'pixels', 'Position', pos, ...
    'Callback', @(a,b) draw_page(page_funs, page_names, npages));
if ~isempty(page_names)
  pos(1) = pos(1) + pos(3);
  pos(3) = 300;
  uicontrol('Parent', h_panel, 'Style', 'popupmenu', ...
      'String', page_names, 'Value', page_num, ...
      'Tag', mfilename, ...
      'Units', 'pixels', 'Position', pos, ...
      'Callback', ...
      @(h,b) draw_page(page_funs, page_names, get(h, 'Value')));
end


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

