function eps2pdf(source, dest, crop, append, gray, quality, gs_options)
%EPS2PDF  Convert an eps file to pdf format using ghostscript
%
% Examples:
%   eps2pdf source dest
%   eps2pdf(source, dest, crop)
%   eps2pdf(source, dest, crop, append)
%   eps2pdf(source, dest, crop, append, gray)
%   eps2pdf(source, dest, crop, append, gray, quality)
%   eps2pdf(source, dest, crop, append, gray, quality, gs_options)
%
% This function converts an eps file to pdf format. The output can be
% optionally cropped and also converted to grayscale. If the output pdf
% file already exists then the eps file can optionally be appended as a new
% page on the end of the eps file. The level of bitmap compression can also
% optionally be set.
%
% This function requires that you have ghostscript installed on your system.
% Ghostscript can be downloaded from: http://www.ghostscript.com
%
% Inputs:
%   source  - filename of the source eps file to convert. The filename is
%             assumed to already have the extension ".eps".
%   dest    - filename of the destination pdf file. The filename is assumed
%             to already have the extension ".pdf".
%   crop    - boolean indicating whether to crop the borders off the pdf.
%             Default: true.
%   append  - boolean indicating whether the eps should be appended to the
%             end of the pdf as a new page (if the pdf exists already).
%             Default: false.
%   gray    - boolean indicating whether the output pdf should be grayscale
%             or not. Default: false.
%   quality - scalar indicating the level of image bitmap quality to
%             output. A larger value gives a higher quality. quality > 100
%             gives lossless output. Default: ghostscript prepress default.
%   gs_options - optional ghostscript options (e.g.: '-dNoOutputFonts'). If
%                multiple options are needed, enclose in call array: {'-a','-b'}

% Copyright (C) Oliver Woodford 2009-2014, Yair Altman 2015-

% Suggestion of appending pdf files provided by Matt C at:
% http://www.mathworks.com/matlabcentral/fileexchange/23629

% Thank you Fabio Viola for pointing out compression artifacts, leading to the quality setting.
% Thank you Scott for pointing out the subsampling of very small images, which was fixed for lossless compression settings.

% 09/12/11: Pass font path to ghostscript
% 26/02/15: If temp dir is not writable, use the dest folder for temp destination files (Javier Paredes)
% 28/02/15: Enable users to specify optional ghostscript options (issue #36)
% 01/03/15: Upon GS error, retry without the -sFONTPATH= option (this might solve
%           some /findfont errors according to James Rankin, FEX Comment 23/01/15)
% 23/06/15: Added extra debug info in case of ghostscript error; code indentation
% 04/10/15: Suggest a workaround for issue #41 (missing font path; thanks Mariia Fedotenkova)
% 22/02/16: Bug fix from latest release of this file (workaround for issue #41)
% 20/03/17: Added informational message in case of GS croak (issue #186)
% 16/01/18: Improved appending of multiple EPS files into single PDF (issue #233; thanks @shartjen)
% 18/10/19: Workaround for GS 9.51+ .setpdfwrite removal problem (issue #285)
% 18/10/19: Warn when ignoring GS fontpath or quality options; clarified error messages
% 15/01/20: Added information about the GS/destination filepath in case of error (issue #294)
% 20/01/20: Attempted fix for issue #285: unsupported patch transparency in some Ghostscript versions
% 12/02/20: Improved fix for issue #285: add -dNOSAFER and -dALLOWPSTRANSPARENCY (thanks @linasstonys)
% 26/08/21: Added GS version to error message; fixed some problems with PDF append (issue #339)

    % Intialise the options string for ghostscript
    options = ['-q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="' dest '"'];

    % Set crop option
    if nargin < 3 || crop
        options = [options ' -dEPSCrop'];
    end

    % Set the font path
    fp = font_path();
    if ~isempty(fp)
        options = [options ' -sFONTPATH="' fp '"'];
    end

    % Set the grayscale option
    if nargin > 4 && gray
        options = [options ' -sColorConversionStrategy=Gray -dProcessColorModel=/DeviceGray'];
    end

    % Set the bitmap quality
    qualityOptions = '';
    if nargin > 5 && ~isempty(quality)
        qualityOptions = ' -dAutoFilterColorImages=false -dAutoFilterGrayImages=false';
        if quality > 100
            qualityOptions = [qualityOptions ' -dColorImageFilter=/FlateEncode -dGrayImageFilter=/FlateEncode'];
            qualityOptions = [qualityOptions ' -c ".setpdfwrite << /ColorImageDownsampleThreshold 10 /GrayImageDownsampleThreshold 10 >> setdistillerparams"'];
        else
            qualityOptions = [qualityOptions ' -dColorImageFilter=/DCTEncode -dGrayImageFilter=/DCTEncode'];
            v = 1 + (quality < 80);
            quality = 1 - quality / 100;
            s = sprintf('<< /QFactor %.2f /Blend 1 /HSample [%d 1 1 %d] /VSample [%d 1 1 %d] >>', quality, v, v, v, v);
            qualityOptions = [qualityOptions ' -c ".setpdfwrite << /ColorImageDict ' s ' /GrayImageDict ' s ' >> setdistillerparams"'];
        end
        options = [options qualityOptions];
    end

    % Enable users to specify optional ghostscript options (issue #36)
    if nargin > 6 && ~isempty(gs_options)
        if iscell(gs_options)
            gs_options = sprintf(' %s',gs_options{:});
        elseif ~ischar(gs_options)
            error('gs_options input argument must be a string or cell-array of strings');
        else
            gs_options = [' ' gs_options];
        end
        options = [options gs_options];
    end

    % Check if the output file exists
    if nargin > 3 && append && exist(dest, 'file') == 2
        % Store the original filesize for later use below
        try
            file_info = dir(dest);
            orig_bytes = file_info.bytes;
        catch
            orig_bytes = [];
        end
        % File exists - append current figure to the end
        tmp_nam = [tempname '.pdf'];
        [fpath,fname,fext] = fileparts(tmp_nam);
        try
            % Ensure that the temp dir is writable (Javier Paredes 26/2/15)
            fid = fopen(tmp_nam,'w');
            fwrite(fid,1);
            fclose(fid);
            delete(tmp_nam);
        catch
            % Temp dir is not writable, so use the dest folder
            fpath = fileparts(dest);
            tmp_nam = fullfile(fpath,[fname fext]);
        end
        % Copy the original (dest) pdf file to temporary folder
        copyfile(dest, tmp_nam);
        % Produce an interim pdf of the source eps, rather than adding the eps directly (issue #233)
        % this will override the original (dest) pdf file
        orig_options = options;
        ghostscript([options ' -f "' source '"']);
        [~,fname] = fileparts(tempname);
        tmp_nam2 = fullfile(fpath,[fname fext]); % ensure using a writable folder (not necessarily tempdir)
        copyfile(dest, tmp_nam2);
        % Add the original pdf (tmp_nam) and interim pdf (dest=>tmp_nam2) as inputs to ghostscript
        %options = [options ' -f "' tmp_nam '" "' source '"'];  % append the source eps to dest pdf
        options = [options ' -f "' tmp_nam '" "' tmp_nam2 '"']; % append the interim pdf to dest pdf
        try
            % Convert to pdf using ghostscript
            [status, message] = ghostscript(options);
            % The output pdf should now be in dest

            % If the returned message is non-empty, a possible error may have
            % occured, so check the file size to ensure whether the file grew
            if ~isempty(message) && ~isempty(orig_bytes)
                file_info = dir(dest);
                new_bytes = file_info.bytes;
                if new_bytes < orig_bytes + 100
                    % Looks like nothing substantial (if anything) was appended to
                    % the original pdf, so try adding the eps file directly (issue #339)
                    options = [orig_options ' -f "' tmp_nam '" "' source '"'];  % append the source eps to dest pdf
                    [status, message] = ghostscript(options);
                end
            end

            % Delete the intermediate (temporary) files
            delete(tmp_nam);
            delete(tmp_nam2);
        catch me
            % Delete the intermediate files and rethrow the error
            delete(tmp_nam);
            delete(tmp_nam2);
            rethrow(me);
        end
    else
        % File doesn't exist or should be over-written
        % Add the source eps file as input to ghostscript
        options = [options ' -f "' source '"'];
        % Convert to pdf using ghostscript
        [status, message] = ghostscript(options);
    end

    % Check for error
    if status
        % Catch and correct undefined .setopacityalpha errors (issue #285)
        % (see explanation inside print2eps.m)
        if ~isempty(regexpi(message,'undefined in .setopacityalpha'))
            % First try with -dNOSAFER and -dALLOWPSTRANSPARENCY  (thanks @linasstonys)
            new_options = [options ' -dNOSAFER -dALLOWPSTRANSPARENCY'];
            [status, message] = ghostscript(new_options);
            if ~status  % hurray! (no error)
                return
            elseif isempty(regexpi(message,'undefined in .setopacityalpha'))  % still some other error
                options = new_options;
            else  % we still get a .setopacityalpha error
                % Remove the transparency and retry
                fstrm = read_write_entire_textfile(source);
                fstrm = regexprep(fstrm, '0?\.\d+ .setopacityalpha \w+\n', '');
                read_write_entire_textfile(source, fstrm);
                [status, message] = ghostscript(options);
                if ~status % hurray! (no error)
                    % Alert the user that transparency is not supported
                    warning('export_fig:GS:quality','Export_fig Face/Edge alpha transparancy is ignored - not supported by your Ghostscript version')
                    return
                end
            end
        end

        % Retry without the -sFONTPATH= option (this might solve some GS
        % /findfont errors according to James Rankin, FEX Comment 23/01/15)
        orig_options = options;
        if ~isempty(fp)
            options = regexprep(options, ' -sFONTPATH=[^ ]+ ',' ');
            [status, message] = ghostscript(options);
            if ~status % hurray! (no error)
                warning('export_fig:GS:fontpath','Export_fig font option is ignored - not supported by your Ghostscript version')
                return
            end
        end

        % Retry without quality options (may solve problems with GS 9.51+, issue #285)
        if ~isempty(qualityOptions)
            options = strrep(orig_options, qualityOptions, '');
            [status, message] = ghostscript(options);
            if ~status % hurray! (no error)
                warning('export_fig:GS:quality','Export_fig quality option is ignored - not supported by your Ghostscript version')
                return
            end
        end

        % Report error
        if isempty(message)
            error(['Unable to generate pdf. Ensure that the destination folder (' fileparts(dest) ') is writable.']);
        elseif ~isempty(strfind(message,'/typecheck in /findfont')) %#ok<STREMP>
            % Suggest a workaround for issue #41 (missing font path)
            font_name = strtrim(regexprep(message,'.*Operand stack:\s*(.*)\s*Execution.*','$1'));
            fprintf(2, 'Ghostscript error: could not find the following font(s): %s\n', font_name);
            %fpath = fileparts(mfilename('fullpath'));
            %gs_fonts_file = fullfile(fpath, '.ignore', 'gs_font_path.txt');
            [unused, gs_fonts_file] = user_string('gs_font_path'); %#ok<ASGLU>
            fprintf(2, '  try to add the font''s folder to your %s file\n\n', gs_fonts_file);
            error('export_fig error');
        else
            gs_options = strtrim(gs_options);
            fprintf(2, '\nGhostscript error: ');
            msg = regexprep(message, '^Error: /([^\n]+).*', '$1');
            if ~isempty(msg) && ~strcmp(msg,message)
                fprintf(2,'%s',msg);
            end
            fprintf(2, '\n * perhaps %s is open by another application\n', dest);
            try gs_version = str2num(evalc('ghostscript(''--version'');')); catch, gs_version = ''; end %#ok<ST2NM>
            if ~isempty(gs_version), gs_version = [' ' num2str(gs_version)]; end
            if ~isempty(gs_options)
                fprintf(2, ' * or maybe your Ghostscript version%s does not accept the extra "%s" option(s) that you requested\n', gs_version, gs_options);
            end
            fprintf(2, ' * or maybe you have another gs executable in your system''s path\n\n');
            fprintf(2, 'Ghostscript path: %s\n', user_string('ghostscript'));
            fprintf(2, 'Ghostscript options: %s\n\n', orig_options);
            error(message);
        end
    end
end

% Function to return (and create, where necessary) the font path
function fp = font_path()
    fp = user_string('gs_font_path');
    if ~isempty(fp)
        return
    end
    % Create the path
    % Start with the default path
    fp = getenv('GS_FONTPATH');
    % Add on the typical directories for a given OS
    if ispc
        if ~isempty(fp)
            fp = [fp ';'];
        end
        fp = [fp getenv('WINDIR') filesep 'Fonts'];
    else
        if ~isempty(fp)
            fp = [fp ':'];
        end
        fp = [fp '/usr/share/fonts:/usr/local/share/fonts:/usr/share/fonts/X11:/usr/local/share/fonts/X11:/usr/share/fonts/truetype:/usr/local/share/fonts/truetype'];
    end
    user_string('gs_font_path', fp);
end
