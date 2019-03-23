function out = objvcat (varargin)
  # Hack to concatenate object vectorss because Octave doesn't support it as of 5.1
  #
  # The "v" in "objvcat" is for "vector" concatenation, not "vertical".
  out = [];
  for i_arg = 1:numel (varargin)
    B = varargin{i_arg};
    if isempty (out)
      out = B;
    else
      for i_B = 1:numel (B)
        out(end+1) = B(i_B);
      endfor
    endif
  endfor
endfunction
