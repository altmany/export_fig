%PRINT2EPS  Prints figures to eps with improved line styles
%
% Examples:
%   print2eps filename
%   print2eps(filename, fig_handle)
%   print2eps(filename, fig_handle, bb_padding)
%   print2eps(filename, fig_handle, bb_padding, options)
%
% This function saves a figure as an eps file, with two improvements over
% MATLAB's print command. First, it improves the line style, making dashed
% lines more like those on screen and giving grid lines their own dotted
% style. Secondly, it substitutes original font names back into the eps
% file, where these have been changed by MATLAB, for up to 11 different
% fonts.
%
%IN:
%   filename - string containing the name (optionally including full or
%              relative path) of the file the figure is to be saved as. A
%              ".eps" extension is added if not there already. If a path is
%              not specified, the figure is saved in the current directory.
%   fig_handle - The handle of the figure to be saved. Default: gcf().
%   bb_padding - Scalar value of amount of padding to add to border around
%                the cropped image, in points (if >1) or percent (if <1).
%                Can be negative as well as positive; Default: 0.
%                May be a 2-element vector of padding and crop amount. 
%   options - Additional parameter strings to be passed to print.

% Copyright (C) Oliver Woodford 2008-2014

% The idea of editing the EPS file to change line styles comes from Jiro
% Doke's FIXPSLINESTYLE (fex id: 17928)
% The idea of changing dash length with line width came from comments on
% fex id: 5743, but the implementation is mine :)

% 14/11/11: Fix a MATLAB bug rendering black or white text incorrectly.
%           Thanks to Mathieu Morlighem for reporting the issue and
%           obtaining a fix from TMW.
% 08/12/11: Added ability to correct fonts. Several people have requested
%           this at one time or another, and also pointed me to printeps
%           (fex id: 7501), so thank you to them. My implementation (which
%           was not inspired by printeps - I'd already had the idea for my
%           approach) goes slightly further in that it allows multiple
%           fonts to be swapped.
% 14/12/11: Fix bug affecting font names containing spaces. Thanks to David
%           Szwer for reporting the issue.
% 25/01/12: Add a font not to be swapped. Thanks to Anna Rafferty and Adam
%           Jackson for reporting the issue. Also fix a bug whereby using a
%           font alias can lead to another font being swapped in.
% 10/04/12: Make the font swapping case insensitive.
% 26/10/12: Set PaperOrientation to portrait. Thanks to Michael Watts for
%           reporting the issue.
% 26/10/12: Fix issue to do with swapping fonts changing other fonts and
%           sizes we don't want, due to listeners. Thanks to Malcolm Hudson
%           for reporting the issue.
% 22/03/13: Extend font swapping to axes labels. Thanks to Rasmus Ischebeck
%           for reporting the issue.
% 23/07/13: Bug fix to font swapping. Thanks to George for reporting the
%           issue.
% 13/08/13: Fix MATLAB feature of not exporting white lines correctly.
%           Thanks to Sebastian Heßlinger for reporting it.
% 24/02/15: Fix for Matlab R2014b bug (issue #31): LineWidths<0.75 are not
%           set in the EPS (default line width is used)
% 25/02/15: Fixed issue #32: BoundingBox problem caused uncropped EPS/PDF files
% 05/03/15: Fixed issue #43: Inability to perform EPS file post-processing
% 06/03/15: Improved image padding & cropping thanks to Oscar Hartogensis

function print2eps(name, fig, bb_padding, varargin)
options = {'-depsc2'};
if nargin > 3
    options = [options varargin];
elseif nargin < 3
    bb_padding = 0;
    if nargin < 2
        fig = gcf();
    end
end
% Retrieve crop value (2nd element of bb_padding vector, or default=0)
try
    bb_crop = bb_padding(2);
    bb_padding = bb_padding(1);  % reached this point, so it's a vector
catch
    bb_crop = 0;  % scalar value, so use default bb_crop value of 0
end
% Construct the filename
if numel(name) < 5 || ~strcmpi(name(end-3:end), '.eps')
    name = [name '.eps']; % Add the missing extension
end
% Set paper size
old_pos_mode = get(fig, 'PaperPositionMode');
old_orientation = get(fig, 'PaperOrientation');
set(fig, 'PaperPositionMode', 'auto', 'PaperOrientation', 'portrait');
% Find all the used fonts in the figure
font_handles = findall(fig, '-property', 'FontName');
fonts = get(font_handles, 'FontName');
if ~iscell(fonts)
    fonts = {fonts};
end
% Map supported font aliases onto the correct name
fontsl = lower(fonts);
for a = 1:numel(fonts)
    f = fontsl{a};
    f(f==' ') = [];
    switch f
        case {'times', 'timesnewroman', 'times-roman'}
            fontsl{a} = 'times-roman';
        case {'arial', 'helvetica'}
            fontsl{a} = 'helvetica';
        case {'newcenturyschoolbook', 'newcenturyschlbk'}
            fontsl{a} = 'newcenturyschlbk';
        otherwise
    end
end
fontslu = unique(fontsl);
% Determine the font swap table
matlab_fonts = {'Helvetica', 'Times-Roman', 'Palatino', 'Bookman', 'Helvetica-Narrow', 'Symbol', ...
                'AvantGarde', 'NewCenturySchlbk', 'Courier', 'ZapfChancery', 'ZapfDingbats'};
matlab_fontsl = lower(matlab_fonts);
require_swap = find(~ismember(fontslu, matlab_fontsl));
unused_fonts = find(~ismember(matlab_fontsl, fontslu));
font_swap = cell(3, min(numel(require_swap), numel(unused_fonts)));
fonts_new = fonts;
for a = 1:size(font_swap, 2)
    font_swap{1,a} = find(strcmp(fontslu{require_swap(a)}, fontsl));
    font_swap{2,a} = matlab_fonts{unused_fonts(a)};
    font_swap{3,a} = fonts{font_swap{1,a}(1)};
    fonts_new(font_swap{1,a}) = {font_swap{2,a}};
end
% Swap the fonts
if ~isempty(font_swap)
    fonts_size = get(font_handles, 'FontSize');
    if iscell(fonts_size)
        fonts_size = cell2mat(fonts_size);
    end
    M = false(size(font_handles));
    % Loop because some changes may not stick first time, due to listeners
    c = 0;
    update = zeros(1000, 1);
    for b = 1:10 % Limit number of loops to avoid infinite loop case
        for a = 1:numel(M)
            M(a) = ~isequal(get(font_handles(a), 'FontName'), fonts_new{a}) || ~isequal(get(font_handles(a), 'FontSize'), fonts_size(a));
            if M(a)
                set(font_handles(a), 'FontName', fonts_new{a}, 'FontSize', fonts_size(a));
                c = c + 1;
                update(c) = a;
            end
        end
        if ~any(M)
            break;
        end
    end
    % Compute the order to revert fonts later, without the need of a loop
    [update, M] = unique(update(1:c));
    [M, M] = sort(M);
    update = reshape(update(M), 1, []);
end
% MATLAB bug fix - black and white text can come out inverted sometimes
% Find the white and black text
black_text_handles = findobj(fig, 'Type', 'text', 'Color', [0 0 0]);
white_text_handles = findobj(fig, 'Type', 'text', 'Color', [1 1 1]);
% Set the font colors slightly off their correct values
set(black_text_handles, 'Color', [0 0 0] + eps);
set(white_text_handles, 'Color', [1 1 1] - eps);
% MATLAB bug fix - white lines can come out funny sometimes
% Find the white lines
white_line_handles = findobj(fig, 'Type', 'line', 'Color', [1 1 1]);
% Set the line color slightly off white
set(white_line_handles, 'Color', [1 1 1] - 0.00001);
% Print to eps file
print(fig, options{:}, name);
% Do post-processing on the eps file
try
    % Read the EPS file into memory
    fstrm = read_write_entire_textfile(name);
catch
    fstrm = '';
end
% Fix for Matlab R2014b bug (issue #31): LineWidths<0.75 are not set in the EPS (default line width is used)
try
    if ~isempty(fstrm) && using_hg2(fig)
        % Modify all thin lines in the figure to have 10x LineWidths
        hLines = findall(fig,'Type','line');
        hThinLines = [];
        for lineIdx = 1 : numel(hLines)
            thisLine = hLines(lineIdx);
            if thisLine.LineWidth < 0.75 && strcmpi(thisLine.Visible,'on')
                hThinLines(end+1) = thisLine; %#ok<AGROW>
                thisLine.LineWidth = thisLine.LineWidth * 10;
            end
        end
        % If any thin lines were found
        if ~isempty(hThinLines)
            % Prepare an EPS with large-enough line widths
            print(fig, options{:}, name);
            % Restore the original LineWidths in the figure
            for lineIdx = 1 : numel(hThinLines)
                thisLine = handle(hThinLines(lineIdx));
                thisLine.LineWidth = thisLine.LineWidth / 10;
            end
            % Compare the original and the new EPS files and correct the original stream's LineWidths
            fstrm_new = read_write_entire_textfile(name);
            idx = 500;  % skip heading with its possibly-different timestamp
            markerStr = sprintf('10.0 ML\nN');
            markerLen = length(markerStr);
            while ~isempty(idx) && idx < length(fstrm)
                lastIdx = min(length(fstrm), length(fstrm_new));
                delta = fstrm(idx+1:lastIdx) - fstrm_new(idx+1:lastIdx);
                idx = idx + find(delta,1);
                if ~isempty(idx) && ...
                   isequal(fstrm(idx-markerLen+1:idx), markerStr) && ...
                   ~isempty(regexp(fstrm_new(idx-markerLen+1:idx+12),'10.0 ML\n[\d\.]+ LW\nN')) %#ok<RGXP1>
                    value = str2double(regexprep(fstrm_new(idx:idx+12),' .*',''));
                    if isnan(value), break; end  % something's wrong... - bail out
                    newStr = sprintf('%0.3f LW\n',value/10);
                    fstrm = [fstrm(1:idx-1) newStr fstrm(idx:end)];
                    idx = idx + 12;
                else
                    break;
                end
            end
            % In HG2, grid lines and axes Ruler Axles have a default LineWidth of 0.5 => replace en-bulk (assume that 1.0 LineWidth = 1.333 LW)
            %  hAxes=gca; hAxes.YGridHandle.LineWidth, hAxes.YRuler.Axle.LineWidth
            fstrm = regexprep(fstrm, '10.0 ML\nN', '10.0 ML\n0.667 LW\nN');
        end
    end
catch err
    fprintf(2, 'Error fixing LineWidths in EPS file: %s\n at %s:%d\n', err.message, err.stack(1).file, err.stack(1).line);
end
% Reset the font and line colors
set(black_text_handles, 'Color', [0 0 0]);
set(white_text_handles, 'Color', [1 1 1]);
set(white_line_handles, 'Color', [1 1 1]);
% Reset paper size
set(fig, 'PaperPositionMode', old_pos_mode, 'PaperOrientation', old_orientation);
% Reset the font names in the figure
if ~isempty(font_swap)
    for a = update
        set(font_handles(a), 'FontName', fonts{a}, 'FontSize', fonts_size(a));
    end
end
% Bail out if EPS post-processing is not possible
if isempty(fstrm)
    warning('Loading EPS file failed, so unable to perform post-processing. This is usually because the figure contains a large number of patch objects. Consider exporting to a bitmap format in this case.');
    return
end
% Replace the font names
if ~isempty(font_swap)
    for a = 1:size(font_swap, 2)
        %fstrm = regexprep(fstrm, [font_swap{1,a} '-?[a-zA-Z]*\>'], font_swap{3,a}(~isspace(font_swap{3,a})));
        fstrm = regexprep(fstrm, font_swap{2,a}, font_swap{3,a}(~isspace(font_swap{3,a})));
    end
end
if using_hg2(fig)
    % Convert miter joins to line joins
    fstrm = regexprep(fstrm, '10.0 ML\n', '1 LJ\n');
    % Move the bounding box to the top of the file
    [s, e] = regexp(fstrm, '%%BoundingBox: [^%]*%%');
    if numel(s) == 2
        fstrm = fstrm([1:s(1)-1 s(2):e(2)-2 e(1)-1:s(2)-1 e(2)-1:end]);
    end
else
    % Fix the line styles
    fstrm = fix_lines(fstrm);
end
% Apply the bounding box padding & cropping, replacing Matlab's print()'s bounding box
if bb_crop
    % Calculate a new bounding box based on a bitmap print using crop_border.m
    % 1. Determine the Matlab BoundingBox and PageBoundingBox
    [s,e] = regexp(fstrm, '%%BoundingBox: [^%]*%%'); % location BB in eps file
    if numel(s)==2, s=s(2); e=e(2); end
    aa = fstrm(s+15:e-3); % dimensions bb - STEP1
    bb_matlab = cell2mat(textscan(aa,'%f32%f32%f32%f32'));  % dimensions bb - STEP2   

    [s,e] = regexp(fstrm, '%%PageBoundingBox: [^%]*%%'); % location bb in eps file
    if numel(s)==2, s=s(2); e=e(2); end
    aa = fstrm(s+19:e-3); % dimensions bb - STEP1
    pagebb_matlab = cell2mat(textscan(aa,'%f32%f32%f32%f32'));  % dimensions bb - STEP2   

    % 2. Create a bitmap image and use crop_borders to create the relative
    %    bb with respect to the PageBoundingBox
    [A, bcol] = print2array(fig, 1, '-opengl');
    [aa, aa, aa, bb_rel] = crop_borders(A, bcol, bb_padding);

    % 3. Calculate the new Bounding Box
    pagew = pagebb_matlab(3)-pagebb_matlab(1);
    pageh = pagebb_matlab(4)-pagebb_matlab(2);
    bb_new = [pagebb_matlab(1)+pagew*bb_rel(1) pagebb_matlab(2)+pageh*bb_rel(2) ...
              pagebb_matlab(1)+pagew*bb_rel(3) pagebb_matlab(2)+pageh*bb_rel(4)];
    bb_offset = (bb_new-bb_matlab);
    
    % Apply the bounding box padding
    if bb_padding
        if abs(bb_padding)<1
            bb_padding = round((mean([bb_new(3)-bb_new(1) bb_new(4)-bb_new(2)])*bb_padding)/0.5)*0.5; % ADJUST BB_PADDING
        end
        add_padding = @(n1, n2, n3, n4) sprintf(' %d', str2double({n1, n2, n3, n4}) + [-bb_padding -bb_padding bb_padding bb_padding] + bb_offset);
    else
        add_padding = @(n1, n2, n3, n4) sprintf(' %d', str2double({n1, n2, n3, n4}) + bb_offset); % fix small but noticeable bounding box shift
    end
    fstrm = regexprep(fstrm, '%%BoundingBox:[ ]+([-]?\d+)[ ]+([-]?\d+)[ ]+([-]?\d+)[ ]+([-]?\d+)', '%%BoundingBox:${add_padding($1, $2, $3, $4)}');
end
% Write out the fixed eps file
read_write_entire_textfile(name, fstrm);
end
