function C = set(C, varargin)

propertyArgIn = varargin;
while length(propertyArgIn) >= 2,
  prop = propertyArgIn{1};
  val = propertyArgIn{2};
  propertyArgIn = propertyArgIn(3:end);

  switch prop
    case 'Function'
        C.func = val;
    otherwise
      error('Invalid property')
  end
end
