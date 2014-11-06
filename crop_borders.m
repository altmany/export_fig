%CROP_BORDERS Crop the borders of an image or stack of images
%
%   [B, v] = crop_borders(A, bcol, [padding])
%
%IN:
%   A - HxWxCxN stack of images.
%   bcol - Cx1 background colour vector.
%   padding - scalar indicating how many pixels padding to have. Default: 0.
%
%OUT:
%   B - JxKxCxN cropped stack of images.
%   v - 1x4 vector of start and end indices for first two dimensions, s.t.
%       B = A(v(1):v(2),v(3):v(4),:,:).

function [A, v] = crop_borders(A, bcol, padding)
if nargin < 3
    padding = 0;
end
[h, w, c, n] = size(A);
if isscalar(bcol)
    bcol = bcol(ones(c, 1));
end
bail = false;
for l = 1:w
    for a = 1:c
        if ~all(col(A(:,l,a,:)) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bcol = A(ceil(end/2),w,:,1);
bail = false;
for r = w:-1:l
    for a = 1:c
        if ~all(col(A(:,r,a,:)) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bcol = A(1,ceil(end/2),:,1);
bail = false;
for t = 1:h
    for a = 1:c
        if ~all(col(A(t,:,a,:)) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
bcol = A(h,ceil(end/2),:,1);
bail = false;
for b = h:-1:t
    for a = 1:c
        if ~all(col(A(b,:,a,:)) == bcol(a))
            bail = true;
            break;
        end
    end
    if bail
        break;
    end
end
% Crop the background, leaving one boundary pixel to avoid bleeding on resize
v = [max(t-padding, 1) min(b+padding, h) max(l-padding, 1) min(r+padding, w)];
A = A(v(1):v(2),v(3):v(4),:,:);
end

function A = col(A)
A = A(:);
end
