function display(C)

disp([inputname(1) ' = '])
disp(['  lazymap object:'])
disp(['                size: ' mat2str(size(C))])
disp(['        map function: ' func2str(C.func)])
