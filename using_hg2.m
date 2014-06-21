%USING_HG2 Determine if the HG2 graphics pipeline is used
%
%   tf = using_hg2()
%
%OUT:
%   tf - boolean indicating whether the HG2 graphics pipeline is being used
%        (true) or not (false).

function tf = using_hg2()
tf = ~verLessThan('matlab', '8.4');