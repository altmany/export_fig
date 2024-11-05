function xkcd_Axes = xkcdify(hAxesOrFig, render_Axes_Lines)
%XKCDIFY redraw an existing axes in an XKCD style
%
% XKCDIFY() without any input arguments, renders the current axes using XKCD
% hand-drawn cartoon style (see http://xkcd.com).
%
% XKCDIFY(AX_HANDLES) renders the specified AX_HANDLES objects using XKCD style.
% AX_HANDLES can be a single axes, figure, or a vector of axes/figures.
%
% XKCDIFY(AX_HANDLES, RENDER_AXES_LINES) renders the axes ruler lines (axles)
% as wobbly lines, if RENDER_AXES_LINES is missing or true or 1 (default).
% If RENDER_AXES_LINES is false or 0 axes lines are not redrawn, only plot lines
%
% XKCD_AXES = XKCDIFY(...) returns an array of new XKCD axes handles, one for
% each rendered input axes. Whenever one of the new XKCD axes is deleted, its
% corresponding original axes is reverted back to its original state.
%
% NOTE: Only 2D plots of type LINE, BAR and PATCH are re-rendered.
% This should be sufficient for most 2D plots such as: plot, line, bar, boxplot
%
% NOTE: possible side effect: the z-stack ordering of rendered axes plots may
% be different from the original.
%
% The original version of this code by Stuart Layton can be found at:
% https://github.com/slayton/matlab-xkcdify
%
% Stuart's original code was adapted by Yair Altman for use in export_fig:
%   - Added license info at top of file, as specified by Stuart on GitHub
%   - Support for HG2 bar plots
%   - Support for xcdify undo, by deleting the output axes handles
%   - Support for figure handles and default inputs
%   - Improved rendering of axes ruler lines
%   - Multiple other code fixes
%
% See also: http://xkcd.com
%
% Copyright (c) 2012,2024, Stuart Layton
% All rights reserved.

% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution.
% 
% * Neither the name of the {organization} nor the names of its
%   contributors may be used to endorse or promote products derived from
%   this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% Revision History
%   2012/10/04 - Initial Release
%   2015/08/12 - Remove dependency on randsample() by mullerj
%   2024/05/08 - License info and code changes by Yair Altman

    if nargin==0
        %error('axHandle must be specified');
        hAxesOrFig = gca;
    elseif ~all( ishandle(hAxesOrFig) )
        error('axHandle must be a valid axes or figure handle(s)');
    else
        handleTypes = get(hAxesOrFig, 'type');
        if ~all( contains(handleTypes, {'axes','figure'}) )
            error('axHandle must be a valid axes or figure handle(s)');
        end
    end

    render_Axes_Lines = nargin < 2 || render_Axes_Lines;

    drawnow;  % ensure that all axes are fully rendered

    if numel(hAxesOrFig) > 1
        hAxesOrFig = unique(hAxesOrFig(:));  % matrix => vector
    end

    has_nargout = nargout > 0;
    if has_nargout, xkcd_Axes = gobjects(0); end
    while ~isempty(hAxesOrFig)
        axHandle = hAxesOrFig(1);
        hAxesOrFig(1) = [];

        % If this is a figure handle, recursively render all its contained axes
        if strcmpi(get(axHandle,'type'),'figure')
            hAxes = findall(axHandle,'type','axes');
            try
                hAxesOrFig = [hAxes, hAxesOrFig];
            catch
                hAxesOrFig = [hAxes; hAxesOrFig];
            end
            hAxesOrFig = unique(hAxesOrFig(:));
            continue
        end

        % Skip re-rendering of previously-rendered axes
        if strcmpi(get(axHandle,'tag'),'xkcd') || ~isempty(getappdata(axHandle,'xkcd_Box'))
            continue
        end

        %TODO 3D axes are not [yet] supported by xkcdify
        if ~is2D(axHandle)
            continue
        end

        pixPerX = [];
        pixPerY = [];
        renderAxes(axHandle)
    end

function renderChildren(C, ax)
    % iterate on the individual children but in reverse order
    % also ensure that C is treated as a row vector
    hasWarned = false;
    if nargin < 2, ax = C; end
    for c = fliplr( C(:)' )
    %for i = 1:nCh
        % we want to
        %   c = C(nCh - i + 1);
        cType = get(c,'Type');
        switch cType
            case 'line'
                if cartoonifyLine(c, ax)
                    restack(); %uistack(c,'top');
                end
            case 'patch'
                if cartoonifyPatch(c, ax)
                    restack(); %uistack(c,'top');
                end
            case 'bar'
                if cartoonifyBar(c, ax)
                    %don't restack, because this reverts the bar vertices!
                end
            case 'axes'
                renderChildren(allchild(c), ax);
            case 'hggroup'
                % if not a line or patch operate on the children of the
                % hggroup child, plot-ception!
                renderChildren(allchild(c), ax);
                restack(); %uistack(c,'top');
            otherwise
                if ~hasWarned
                    warning('xkcdify:bad_child','xkcdify does not supportd %s objects', cType);
                    hasWarned = true; %don't warn again for this axes
                end
                continue
        end
    end

    function restack()  % faster alternative to uistack(c,'top')
        try
            hParent = get(c,'Parent');
            allAxChildren = allchild(hParent);
            allAxChildren(allAxChildren==c) = [];
            set(hParent,'Children',[c; allAxChildren]);
        catch %just in case the simpler code above fails for some reason...
            uistack(c,'top');
        end
    end
end

function renderAxes(ax)
    axBox = get(ax,'Box');
    isBoxOn = strcmpi(axBox,'on');
    setappdata(ax, 'xkcd_Box',axBox);
    set(ax,'Box','off');

    % Store the axes limits for later use
    xLims = get(ax,'XLim');
    yLims = get(ax,'YLim');
    setappdata(ax, 'xkcd_XLim',xLims);
    setappdata(ax, 'xkcd_YLim',yLims);

    % Use large comic font
    fontName = get(ax,'FontName');
    fontSize = get(ax,'FontSize');
    setappdata(ax, 'xkcd_FontName',fontName);
    setappdata(ax, 'xkcd_FontSize',fontSize);
    set(ax, 'FontName','Comic Sans MS', 'FontSize',max(14,fontSize));
    drawnow  %this is required because the FontSize change updates axes position

    % Hide the axle lines (show only the wide axLines below)
    xAxle = ax.XRuler.Axle;
    yAxle = ax.YRuler.Axle;
    setappdata(ax, 'xkcd_XAxle',get(xAxle,'Visible'));
    setappdata(ax, 'xkcd_YAxle',get(yAxle,'Visible'));
    set(xAxle, 'Visible','off');
    set(yAxle, 'Visible','off');

    % Get the correct location for the next axes
    nAxPixOffset = 10;
    pos = getAxesPositionInUnits(ax,'Pixels');
    pos(1:2) = pos(1:2) - nAxPixOffset;
    if isBoxOn
        pos(3:4) = pos(3:4) + nAxPixOffset*2;
    else
        pos(3:4) = pos(3:4) + nAxPixOffset;
    end

    % Create the new (invisible) overlapping xkcdify axes
    hParent = get(ax,'Parent');
    axProps = {'Parent',hParent, 'Units','pixels', 'Position',pos, ...
               'Visible','off', 'Color','none', 'HitTest','off', ...
               'Tag','xkcd'}; %,'XTick',[],'YTick',[]};
    try ax.Interactions; axProps = [axProps, 'Interactions',{[]}]; catch, end
    newAxes = axes(axProps{:});
    if has_nargout, xkcd_Axes(end+1) = newAxes; end

    % Create overlapping wobbly axle lines in the new axes, if requested by user
    if render_Axes_Lines
        axLine = gobjects(0);
        drawAxisLines();
        %axis(newAxes, 'off');

        % Resize the new axes with the parent
        set(newAxes,'Units','norm');
        % listener to update axLine positions when ax position changes (xkcdify_example #4)
        axPosListener = addlistener(ax,'MarkedClean',@updateXkcdAxes);
        setappdata(ax, 'xkcd_posListener',axPosListener);
    end

    % Attach listener to revert original axes style when XKCD axes is deleted
    addlistener(newAxes,'ObjectBeingDestroyed',@(h,e)revertAxes(ax));

    % Now render all axes children
    [pixPerX, pixPerY] = getPixelsPerUnitForAxes(ax);
    renderChildren(ax);

    function drawAxisLines()
        %[pixPerX, pixPerY] = getPixelsPerUnitForAxes(newAxes);
        pixPerX = pos(3); pixPerY = pos(4); %faster than getPixelsPerUnitForAxes
        dx = nAxPixOffset / pixPerX;
        dy = nAxPixOffset / pixPerY;

        xlim = [0,1]; %=get(newAxes,'XLim');
        ylim = [0,1]; %=get(newAxes,'YLim');

        isXAXisVisible = strcmpi(get(xAxle,'Visible'),'on');
        isYAXisVisible = strcmpi(get(yAxle,'Visible'),'on');

        % Draw thick lines over the axes edges
        lineProps = {'Parent',newAxes, 'Color','k', 'LineWidth',3, 'HitTest','off', ...
                     'XLimInclude','off', 'YLimInclude','off', 'ZLimInclude','off'};
        delete(axLine);
        if isBoxOn
            % Draw all visible axes edges
            if isXAXisVisible
                xs = xlim + [dx,-dx];
                axLine(1) = line(xs, [dy,dy],                lineProps{:}); %bottom
                axLine(2) = line(xs, ylim(2)-[dy,dy]+.00001, lineProps{:}); %top
            end
            if isYAXisVisible
                ys = ylim + [dy,-dy];
                axLine(3) = line([dx,dx],                ys, lineProps{:}); %left
                axLine(4) = line(xlim(2)-[dx,dx]+.00001, ys, lineProps{:}); %right
            end
        else
            % No 'box' - only draw bottom & left axes edge lines (if visible)
            if isXAXisVisible
                axLine(1) = line(xlim+[dx-.001,0], [dy,dy], lineProps{:}); %bottom
            end
            if isYAXisVisible
                axLine(2) = line([dx,dx], ylim+[dy-.001,0], lineProps{:}); %left
            end
        end

        % Jitter the overlapping axle lines
        for i = 1:numel(axLine)
            jitterLine(axLine(i), 3);  % nPxOffset=3
        end

        % Connect the corners of the thick axle lines (only needed if 'Box' on
        if isBoxOn
            try drawnow; set([axLine.Edge],'LineCap','square'); catch, end
        end
    end

    function updateXkcdAxes(varargin)
        newPos = getAxesPositionInUnits(ax,'Pixels');
        if isBoxOn
            newPos = newPos + nAxPixOffset*[-1,-1,2,2];
        else
            newPos = newPos + nAxPixOffset*[-1,-1,1,1];
        end
        if ~isequal(newPos,pos)
            pos = newPos;
            set(newAxes, 'Units','pixels', 'Position',pos);
            set(newAxes, 'Units','norm');
            drawAxisLines();
        end
    end
end

function revertAxes(ax)
    % Restore original axes properties
    try set(ax, 'Box',     getappdata(ax,'xkcd_Box'));      catch, end
    try set(ax, 'FontName',getappdata(ax,'xkcd_FontName')); catch, end
    try set(ax, 'FontSize',getappdata(ax,'xkcd_FontSize')); catch, end

    try set(ax, 'XLim',    getappdata(ax,'xkcd_XLim')); catch, end
    try set(ax, 'YLim',    getappdata(ax,'xkcd_YLim')); catch, end

    try set(ax.XRuler.Axle,'Visible', getappdata(ax,'xkcd_XAxle')); catch, end
    try set(ax.YRuler.Axle,'Visible', getappdata(ax,'xkcd_YAxle')); catch, end

    try delete(getappdata(ax, 'xkcd_posListener')); catch, end
    try rmappdata(ax,'xkcd_Box'); catch, end %important! (avoid axes re-render)

    % Bulk-delete all white background lines
    delete(findall(ax,'Tag','xkcd'));

    % Restore all sub-handles' properties
    hChildren = allchild(ax);
    for idx = 1 : numel(hChildren)
        h = hChildren(idx);
        try
            switch get(h,'Type')
                case 'line'
                    set(h, 'XData',    getappdata(h,'xkcd_XData'), ...
                           'YData',    getappdata(h,'xkcd_YData'), ...
                      ... %'LineStyle',getappdata(h,'xkcd_Style'), ...
                           'LineWidth',getappdata(h,'xkcd_Width'));
                case 'bar'
                    c = h.NodeChildren;
                    set(c,   'VertexData',   getappdata(h,   'xkcd_VData'));
                    set(c(1),'LineWidth',    getappdata(h,   'xkcd_Width'));
                    set(h,   'LineWidth',    getappdata(h,   'xkcd_Width'));
                    set(h,   'ShowBaseLine', getappdata(hBar,'xkcd_Base'));
                case 'patch'
                    set(h, 'XData',          getappdata(h,'xkcd_XData'), ...
                           'YData',          getappdata(h,'xkcd_YData'), ...
                           'CData',          getappdata(h,'xkcd_CData'), ...
                           'LineWidth',      getappdata(h,'xkcd_Width'), ...
                           'FaceVertexCData',getappdata(h,'xkcd_FVCData'), ...
                           'Faces',          getappdata(h,'xkcd_Faces'), ...
                           'Vertices',       getappdata(h,'xkcd_Vertices'), ...
                           'VertexNormals',  getappdata(h,'xkcd_VertexNormals'));
            end
        catch
        end
    end
end

function [x, y] = upSampleAndJitter(x, y, jx, jy, n)
    % we want to upsample the line to have a number of that is proportional
    % to the number of pixels the line occupies on the screen. Long lines
    % will get a lot of samples, short points will get a few
    if nargin == 4 || n == 0
        n = getLineLength(x,y);
        ptsPerPix = 1/4;
        n = ceil(n * ptsPerPix);
    end

    n1 = linspace(0, 1, n);
    x = interp1(linspace(0,1,numel(x)), x, n1);
    y = interp1(linspace(0,1,numel(y)), y, n1);

    x = x + smooth( generateNoise(n) .* rand(n,1) .* jx )';
    y = y + smooth( generateNoise(n) .* rand(n,1) .* jy )';
end

function noise = generateNoise(n)
    noise = zeros(n,1);

    iStart = ceil(n/50);
    iEnd = n - iStart;

    i = iStart;
    while i < iEnd
        if randi(10,1,1) < 2
            upDown = (rand > 0.5)*2 - 1;
            maxDur = max( min(iEnd-i,100), 1);
            duration = randi(maxDur, 1, 1);
            noise(i:i+duration) = upDown;
            i = i + duration;
        end
        i = i +1;
    end
    noise = noise(:);
end

function addBackgroundMask(xpts, ypts, w, ax)
    bg = get(ax, 'color');
    l = line(xpts, ypts, 'linewidth',w, 'color',bg, 'Parent',ax, 'Tag','xkcd');
    set(l, 'XLimInclude','off', 'YLimInclude','off', 'ZLimInclude','off');
end

function pos = getAxesPositionInUnits(ax, units)
    origUnits = get(ax,'Units');
    if strcmpi(origUnits, units)
        pos = get(ax,'Position');
        return
    end

    % if the current axes contains a box plot then we need to create a temporary
    % axes as changing the units on a boxplot causes the pos(4) to be set to 0
    % TODO maybe use hgconvertunits() instead
    axUserData = get(ax,'UserData');
    if ~isempty(axUserData) && iscell(axUserData) && strcmp(axUserData{1},'boxplot')
        origPos = get(ax,'Position');
        axTemp = axes('Units',origUnits, 'Position',origPos);
        set(axTemp,'Units',units);
        pos = get(axTemp,'Position');
        delete(axTemp);
    elseif strncmpi(units,'pixels',5)
        pos = getpixelposition(ax);  %code below is a bit faster but unsupported
        %{
        hFig = ancestor(ax,'figure');
        origPos = get(ax,'Position');
        hParent = get(ax,'Parent');
        pos = hgconvertunits(hFig,origPos,origUnits,'Pixels',hParent);
        %}
    else
        set(ax,'Units',units);
        pos = get(ax,'Position');
        set(ax,'Units',origUnits);
    end
end

function setAxesPositionInUnits(ax, units, pos) %#ok<DEFNU> function unused
    origUnits = get(ax,'Units');
    if strcmp(origUnits, units)
        set(ax,'Position',pos);
        return
    end

    % if the current axes contains a box plot then we need to create a temporary
    % axes as changing the units on a boxplot causes the pos(4) to be set to 0
    % TODO maybe use hgconvertunits() instead
    axUserData = get(ax,'UserData');
    if ~isempty(axUserData) && iscell(axUserData) && strcmp(axUserData{1}, 'boxplot')
        axTemp = axes('Units',units, 'Position',pos);
        set(axTemp, 'Units',origUnits);
        set(ax, 'Position',get(axTemp,'Position'));
        delete(axTemp);
    else
        set(ax, 'Units',units, 'Position', pos);
        set(ax, 'Units',origUnits);
    end
end

% Main function for converting units to pixels, refers to the main drawing axes
function [ppX, ppY] = getPixelsPerUnit()
    if ~isempty(pixPerX) && ~isempty(pixPerY)
        ppX = pixPerX;
        ppY = pixPerY;
    else
        [ppX, ppY] = getPixelsPerUnitForAxes(axHandle);
    end
end

% Worker function for converting units to pixels, can be used with any axes
% allowing it to be used with subsequently created axes that are involved
% in rendering the axes lines
function [px, py] = getPixelsPerUnitForAxes(axH)
    %get the size of the current axes in pixels
    %get the lims of the current axes in plotting units
    %calculate the number of pixels per plotting unit
    persistent prev_ax prev_px prev_py
    if ~isequal(prev_ax,axH)
        pos = getAxesPositionInUnits(axH, 'Pixels');

        xLim = get(axH, 'XLim');
        yLim = get(axH, 'YLim');

        prev_ax = axH;
        prev_px = pos(3) ./ diff(xLim);
        prev_py = pos(4) ./ diff(yLim);
    end
    px = prev_px;
    py = prev_py;
end

function len = getLineLength(x, y)
    % convert x and y to pixels from units
    [pixPerX, pixPerY] = getPixelsPerUnit();
    x = x(:) * pixPerX;
    y = y(:) * pixPerY;

    %compute the length of the line
    len = sum( sqrt( diff( x ).^2 + diff( y ).^2 ) );
end

function v = smooth(v)
    % these values are pretty arbitrary, i should probably come up with a
    % better way to calculate them from the data
    a = 1/2;
    nPad = 10;
    % filter the yValues to smooth the jitter
    v = filtfilt(a, [1 a-1], [ ones(nPad ,1) * v(1); v; ones(nPad,1) * v(end) ]);
    v = filtfilt(a, [1 a-1], v);
    v = v(nPad+1:end-nPad);
    v = v(:);
end

function jitterLine(l, nPixOffset, addBg)
    if ~ishandle(l), return, end  % in case of GraphicsPlaceholder

    xpts = get(l, 'XData')';
    ypts = get(l, 'YData')';

    % Only jitter lines with more than 1 point
    if numel(xpts)>1
        if all(diff(ypts) == 0)
            % if the line is horizontal don't jitter in X
            xJitter = 0;
        else
            % I should figure out a better way to calculate this
            xJitter = nPixOffset / pixPerX;
        end
        if all(diff(xpts) == 0)
            % if the line is vertical don't jitter in y
            yJitter = 0;
        else
            % I should figure out a better way to calculate this
            yJitter = nPixOffset / pixPerY;
        end
        [xpts, ypts] = upSampleAndJitter(xpts, ypts, xJitter, yJitter);
        set(l, 'XData',xpts, 'YData',ypts); %,'linestyle','-'); %line style unmodified!

        if nargin > 2 && addBg
            % Add a white background to the line
            width = get(l, 'LineWidth');
            ax = ancestor(l, 'axes');
            addBackgroundMask(xpts, ypts, width*3, ax);
        end
    end
end

function objectUpdated = cartoonifyLine(l, ax)
    % Bail out (do nothing) if the line is not visible
    if strcmpi(get(l,'Visible'),'off')
        objectUpdated = false;
        return
    else
        objectUpdated = true;
    end

    % Store the original data, to allow undo upon xkcdify axes deletion
    xpts  = get(l, 'XData')';
    ypts  = get(l, 'YData')';
    width = get(l, 'LineWidth');
    %style = get(l, 'LineStyle');  %line style is not modified!

    setappdata(l, 'xkcd_XData',xpts);
    setappdata(l, 'xkcd_YData',ypts);
    setappdata(l, 'xkcd_Width',width);
    %setappdata(l, 'xkcd_Style',style);

    % Store the axes limits for later use
    xLims = get(ax,'XLim');
    yLims = get(ax,'YLim');

    % Make the line thick (LineWidth>=2.5)
    newWidth = max(2.5, width);
    set(l, 'LineWidth',newWidth);

    % Jitter the line
    nPixOffset = 6;
    %[pixPerX, pixPerY] = getPixelsPerUnitForAxes(ax); %done in renderAxes()
    jitterLine(l, nPixOffset, true);  %add white background = true

    % Ensure that the axes limits remain unchanged
    set(ax, 'XLim',xLims, 'YLim',yLims);
end

function objectUpdated = cartoonifyBar(hBar, ax) %#ok<INUSD> ax is not used
    % Bail out (do nothing) if the bars are not visible
    if strcmpi(get(hBar,'Visible'),'off')
        objectUpdated = false;
        return
    else
        objectUpdated = true;
    end

    c = hBar.NodeChildren;

    % Store the original data, to allow undo upon xkcdify axes deletion
    vData = get(c(1), 'VertexData');  %3xN matrix
    width = get(hBar, 'LineWidth');

    setappdata(hBar, 'xkcd_VData',vData);
    setappdata(hBar, 'xkcd_Width',width);

    try
        % Remove the bars baseline, if shown
        baseV = get(hBar, 'ShowBaseLine');
        set(hBar,'ShowBaseLine','off');
        setappdata(hBar, 'xkcd_Base', baseV);
    catch
    end

    %[pixPerX, pixPerY] = getPixelsPerUnitForAxes(ax); %done in renderAxes()
    [pixPerX, pixPerY] = getPixelsPerUnit();

    % I should figure out a better way to calculate this
    nPixOffset = 8;
    xJitter = nPixOffset / pixPerX;
    yJitter = nPixOffset / pixPerY;

    nPts = size(vData,2);
    vData(1,:) = vData(1,:) + xJitter * (rand(1,nPts)*2-1);
    vData(2,:) = vData(2,:) + yJitter * (rand(1,nPts)*2-1);

    % Make the line thick (LineWidth>=2.5)
    newWidth = max(2.5, width);
    updateBar();

    % The bars get reset whenever they are redrawn - workaround this
    %addlistener(ax,'MarkedClean',@updateBar);

    % Ensure that the axes limits remain unchanged
    %set(ax, 'XLim',xLims, 'YLim',yLims);

    function updateBar(varargin)
        set(hBar, 'LineWidth',newWidth); %drawnow; pause(.01)
        set(c(1), 'LineWidth',newWidth); drawnow; %pause(.01)
        set(c,    'VertexData',vData);   %drawnow; pause(.01)
    end
end

% This method is by far the buggiest part of the script. It appears to work,
% however it fails to retain the original patch color, and sets it to blue.
% This doesn't prevent the user from reseting the color after the fact using
% set(barHandle,'FaceColor',color) which IMHO is an acceptable workaround
function objectUpdated = cartoonifyPatch(p, ax)
    % Bail out (do nothing) if the patch is not visible
    if strcmpi(get(p,'Visible'),'off')
        objectUpdated = false;
        return
    else
        objectUpdated = true;
    end

    % Store the original data, to allow undo upon xkcdify axes deletion
    xPts  = get(p, 'XData');
    yPts  = get(p, 'YData');
    cData = get(p, 'CData');

    width = get(p, 'LineWidth');

    oldFaces   = get(p, 'Faces');
    oldFVCData = get(p, 'FaceVertexCData');

    oldVtx     = get(p, 'Vertices');
    oldVtxNorm = get(p, 'VertexNormals');
    hasVtxNorm = ~isempty(oldVtxNorm);

    setappdata(p, 'xkcd_XData',xPts);
    setappdata(p, 'xkcd_YData',yPts);
    setappdata(p, 'xkcd_CData',cData);

    setappdata(p, 'xkcd_Width',width);

    setappdata(p, 'xkcd_FVCData',      oldFVCData);
    setappdata(p, 'xkcd_Faces',        oldFaces);
    setappdata(p, 'xkcd_Vertices',     oldVtx);
    setappdata(p, 'xkcd_VertexNormals',oldVtxNorm);

    % Store the axes limits for later use
    xLims = get(ax,'XLim');
    yLims = get(ax,'YLim');

    nOld = size(xPts,1);

    xNew = [];
    yNew = [];

    nPatch = size(xPts, 2);
    %nVtx  = size(oldVtx,1);

    newVtx = [];
    newVtxNorm = [];

    nPixOffset = 6;
    [pixPerX, pixPerY] = getPixelsPerUnit();
    xJitter = nPixOffset / pixPerX;
    yJitter = nPixOffset / pixPerY;

    nNew = 0;
    cNew = [];
    for i = 1:nPatch
        %newVtx( end+1,:) = oldVtx( 1 + (i-1)*nOld, : );
        [x, y] = upSampleAndJitter(xPts(:,i), yPts(:,i), xJitter, yJitter, nNew);

        xNew(:,i) = x(:); %#ok<*AGROW>
        yNew(:,i) = y(:);
        nNew = numel(x);

        if ~isempty(cData)
            cNew(:,i) = interp1( linspace(0,1,nOld), cData(:,i), linspace(0,1,nNew));
        end

        newVtx(end+1,1:2) = oldVtx( 1 + (i-1)*(nOld+1), 1:2);
        newVtxNorm( end+1, 1:3) = nan;

        % set the first and last vertex for each bar back in its original
        % position so everything lines up
        yNew([1, end], i) = yPts([1,end],i);
        xNew([1, end], i) = xPts([1,end],i);

        newVtx(end + (1:nNew), :) = [xNew(:,i), yNew(:,i)] ;

        if hasVtxNorm
            t = repmat( oldVtxNorm( 1+1 + (i-1)*(nOld+1), : ), nNew, 1);
            newVtxNorm( end+ (1:nNew), : ) = t;
        end

        addBackgroundMask(xNew(:,i), yNew(:,i), 6, ax);
    end

    newVtx(end+1, :) = oldVtx(end,:);
    if hasVtxNorm
        newVtxNorm(end+1, :) = nan;
    else
        newVtxNorm = oldVtxNorm;
    end

    % construct the new vertex data
    newFaces = true(size(newVtx,1),1);
    newFaces(1:nNew+1:end) = false;
    newFaces = find(newFaces);
    newFaces = reshape(newFaces, nNew, nPatch)';

    % I can't seem to get this working correct, so I'll set the color to
    % the default matlab blue not the same as 'color', 'blue'!
    newFaceVtxCData = [ 0 0 .5608 ];

    % Make the patch lines thick (LineWidth>=2.5)
    newWidth = max(2.5, width);

    set(p, 'XData',xNew, 'YData',yNew, 'CData',cNew, 'LineWidth',newWidth, ...
           'FaceVertexCData',newFaceVtxCData, 'Faces',newFaces, ...
           'Vertices',newVtx, 'VertexNormals',newVtxNorm);
    %set(p, 'EdgeColor','none');

    % Ensure that the axes limits remain unchanged
    set(ax, 'XLim',xLims, 'YLim',yLims);
end

end
