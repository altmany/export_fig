Syntax:
  [imageData, alpha] = export_fig(filename, [handle], options...)

Examples:
  imageData = export_fig
  [imageData, alpha] = export_fig
  export_fig filename
  export_fig filename -format1 -format2
  export_fig ... -nocrop
  export_fig ... -c[<val>,<val>,<val>,<val>]
  export_fig ... -transparent
  export_fig ... -native
  export_fig ... -m<val>
  export_fig ... -r<val>
  export_fig ... -a<val>
  export_fig ... -q<val>
  export_fig ... -p<val>
  export_fig ... -n<val>   or:  -n<val>,<val>
  export_fig ... -x<val>   or:  -x<val>,<val>
  export_fig ... -s<val>   or:  -s<val>,<val>
  export_fig ... -d<gs_option>
  export_fig ... -depsc
  export_fig ... -metadata <metaDataInfo>
  export_fig ... -<renderer>
  export_fig ... -<colorspace>
  export_fig ... -append
  export_fig ... -bookmark
  export_fig ... -clipboard<:format>
  export_fig ... -update
  export_fig ... -version
  export_fig ... -nofontswap
  export_fig ... -font_space <char>
  export_fig ... -linecaps
  export_fig ... -noinvert
  export_fig ... -preserve_size
  export_fig ... -options <optionsStruct>
  export_fig ... -silent
  export_fig ... -notify
  export_fig ... -regexprep <pattern> <replace>
  export_fig ... -toolbar
  export_fig ... -menubar
  export_fig ... -contextmenu
  export_fig(..., handle)
  export_fig(..., figName)

Description:
  This function saves a figure or single axes to one or more vector and/or
  bitmap file formats, and/or outputs a rasterized version to the workspace,
  with the following properties:
    - Figure/axes reproduced as it appears on screen
    - Cropped/padded borders (optional)
    - Embedded fonts (vector formats)
    - Improved line and grid line styles
    - Anti-aliased graphics (bitmap formats)
    - Render images at native resolution (optional for bitmap formats)
    - Transparent background supported (pdf, eps, png, tif, gif)
    - Semi-transparent patch objects supported (png, tif)
    - RGB, CMYK or grayscale output (CMYK only with pdf, eps, tif)
    - Variable image compression, including lossless (pdf, eps, jpg)
    - Optional rounded line-caps (pdf, eps)
    - Optionally append to file (pdf, tif, gif)
    - Vector formats: pdf, eps, emf, svg
    - Bitmap formats: png, tif, jpg, bmp, gif, clipboard, export to workspace

  This function is especially suited to exporting figures for use in
  publications and presentations, because of the high quality and
  portability of media produced.

  Note that the background color and figure dimensions are reproduced
  (the latter approximately, and ignoring cropping & magnification) in the
  output file. For transparent background (and semi-transparent patch
  objects), use the -transparent option or set the figure 'Color' property
  to 'none'. To make axes transparent set the axes 'Color' property to
  'none'. PDF, EPS, TIF & PNG are the only formats that support a transparent
  background; only TIF & PNG formats support transparency of patch objects.

  The choice of renderer (opengl/zbuffer/painters) has a large impact on the
  output quality. The default value (opengl for bitmaps, painters for vector
  formats) generally gives good results, but if you aren't satisfied
  then try another renderer.  Notes:
    1) For vector formats (EPS,PDF), only painters generates vector graphics
    2) For bitmap formats, only opengl correctly renders transparent patches
    3) For bitmap formats, only painters correctly scales line dash and dot
       lengths when magnifying or anti-aliasing
    4) Fonts may be substitued with Courier when using painters

  When exporting to vector format (PDF & EPS) and bitmap format using the
  painters renderer, this function requires that ghostscript is installed
  on your system. You can download this from: http://www.ghostscript.com
  When exporting to EPS it additionally requires pdftops, from the Xpdf
  suite of functions. You can download this from: http://xpdfreader.com

  SVG output uses Matlab's built-in SVG export if available, or otherwise the
  fig2svg (https://github.com/kupiqu/fig2svg) or plot2svg 
  (https://github.com/jschwizer99/plot2svg) utilities, if available.
  Note: cropping/padding are not supported in export_fig's SVG and EMF output.

Inputs:
  filename - string containing the name (optionally including full or
            relative path) of the file the figure is to be saved as. If
            no path is specified, the figure is saved in the current folder.
            If no name and no output arguments are specified, the figure's
            FileName property is used. If this property is empty, then the
            default name 'export_fig_out' is used. If neither file extension
            nor a format parameter are specified, a ".png" is added to the
            filename and the figure saved in PNG format.
  -<format> - string(s) containing the output file extension(s). Options:
            '-pdf','-eps','emf','-svg','-png','-tif','-jpg','-gif' and '-bmp'.
            Multiple formats can be specified, without restriction.
            For example: export_fig('-jpg', '-pdf', '-png', ...)
            Note: '-tif','-tiff' are equivalent, and so are '-jpg','-jpeg'.
  -transparent - option indicating that the figure background is to be made
            transparent (PNG,PDF,TIF,EPS,EMF formats only). Implies -noinvert.
  -nocrop - option indicating that empty margins should not be cropped.
  -c[<val>,<val>,<val>,<val>] - option indicating crop amounts. Must be
            a 4-element vector of numeric values: [top,right,bottom,left]
            where NaN/Inf indicates auto-cropping, 0 means no cropping, any
            other value means cropping in pixel amounts. e.g. '-c7,15,0,NaN'
            Note: this option is not supported by SVG and EMF formats.
  -p<val> - option to pad a border of width val to exported files, where
            val is either a relative size with respect to cropped image
            size (i.e. p=0.01 adds a 1% border). For EPS & PDF formats,
            val can also be integer in units of 1/72" points (abs(val)>1).
            val can be positive (padding) or negative (extra cropping).
            If used, the -nocrop flag will be ignored, i.e. the image will
            always be cropped and then padded. Default: 0 (i.e. no padding).
            Note: this option is not supported by SVG and EMF formats.
  -m<val> - option val indicates the factor to magnify the figure dimensions
            when generating bitmap outputs (does not affect vector formats).
            Default: '-m1' (i.e. val=1). Note: val~=1 slows down export_fig.
  -r<val> - option val indicates the resolution (in pixels per inch) to
            export bitmap and vector outputs, without changing dimensions of
            the on-screen figure. Default: '-r864' (for vector output only).
            Note: -m option overides -r option for bitmap exports only.
  -native - option indicating that the output resolution (when outputting
            a bitmap format) should be such that the vertical resolution
            of the first suitable image found in the figure is at the
            native resolution of that image. To specify a particular
            image to use, give it the tag 'export_fig_native'. 
            Notes: This overrides any value set with the -m and -r options.
            It also assumes that the image is displayed front-to-parallel
            with the screen. The output resolution is approximate and
            should not be relied upon. Anti-aliasing can have adverse
            effects on image quality (disable with the -a1 option).
  -a1, -a2, -a3, -a4 - option indicating the amount of anti-aliasing (AA) to
            use for bitmap outputs, when GraphicsSmoothing is not available.
            '-a1'=no AA; '-a4'=max. Default: 3 for HG1, 1 for HG2.
  -<renderer> - option to force a particular renderer (painters, opengl or
            [in R2014a or older] zbuffer). Default value: opengl for bitmap
            formats or figures with patches and/or transparent annotations;
            painters for vector formats without patches/transparencies.
  -<colorspace> - option indicating which colorspace color figures should
            be saved in: RGB (default), CMYK or gray. Usage example: '-gray'.
            Note: CMYK is only supported in PDF, EPS and TIF formats.
  -q<val> - option to vary bitmap image quality (PDF, EPS, JPG formats only).
            A larger val, in the range 0-100, produces higher quality and
            lower compression. val > 100 results in lossless compression.
            Default: '-q95' for JPG, ghostscript prepress default for PDF,EPS.
            Note: lossless compression can sometimes give a smaller file size
            than the default lossy compression, depending on the image type.
  -n<val> - option to set minimum output image size (bitmap formats only).
            The output size can be specified as a single value (for both rows
            & cols, e.g. -n200) or comma-separated values (e.g. -n300,400).
            Use an Inf value to keep a dimension unchanged (e.g. -n50,inf).
            Use a NaN value to keep aspect ratio unchanged (e.g. -n50,nan).
  -x<val> - option to set maximum output image size (bitmap formats only).
            The output size can be specified as a single value (for both rows
            & cols, e.g. -x200) or comma-separated values (e.g. -x300,400).
            Use an Inf value to keep a dimension unchanged (e.g. -x50,inf).
            Use a NaN value to keep aspect ratio unchanged (e.g. -x50,nan).
  -s<val> - option to scale output image to specific size (bitmap formats only).
            The fixed size can be specified as a single value (for rows=cols) or
            comma-separated values (e.g. -s300,400). Each value can be a scalar
            integer (signifying pixels) or percentage (e.g. -s125%). The scaling
            is done last, after any other cropping/rescaling due to other params.
  -append - option indicating that if the file already exists the figure is to
            be appended as a new page, instead of being overwritten (default).
            PDF, TIF & GIF output formats only (multi-image GIF = animated).
  -bookmark - option to indicate that a bookmark with the name of the
            figure is to be created in the output file (PDF format only).
  -clipboard - option to save output as an image on the system clipboard.
  -clipboard<:format> - copies to clipboard in the specified format:
            image (default), bitmap, emf, or pdf.
            Notes: Only -clipboard (or -clipboard:image, which is the same)
                   applies export_fig parameters such as cropping, padding etc.
            -clipboard:image  create a bitmap image using export_fig processing
            -clipboard:bitmap create a bitmap image as-is (no auto-cropping etc.)
            -clipboard:emf is vector format without auto-cropping; Windows-only
            -clipboard:pdf is vector format without cropping; not universally supported
  -d<gs_option> - option to indicate a ghostscript setting. For example,
            -dMaxBitmap=0 or -dNoOutputFonts (Ghostscript 9.15+).
  -depsc -  option to use EPS level-3 rather than the default level-2 print
            device. This solves some bugs with Matlab's default -depsc2 device
            such as discolored subplot lines on images (vector formats only).
  -metadata <metaDataInfo> - adds the specified meta-data information to the
            exported file (PDF format only). metaDataInfo must be either a struct
            or a cell array with pairs of values: {'fieldName',fieldValue, ...}.
            Common metadata fields: Title,Author,Creator,Producer,Subject,Keywords
  -update - option to download and install the latest version of export_fig
  -version - return the current export_fig version, without any figure export
  -nofontswap - option to avoid font swapping. Font swapping is automatically
            done in vector formats (only): 11 standard Matlab fonts are
            replaced by the original figure fonts. This option prevents this.
  -font_space <char> - option to set a spacer character for font-names that
            contain spaces, used by EPS/PDF. Default: ''
  -linecaps - option to create rounded line-caps (vector formats only).
  -noinvert - option to avoid setting figure's InvertHardcopy property to
            'off' during output (this solves some problems of empty outputs).
  -preserve_size - option to preserve the figure's PaperSize property in output
            file (PDF/EPS formats only; default is to not preserve it).
  -options <optionsStruct> - format-specific parameters as defined in Matlab's
            documentation of the imwrite function, contained in a struct under
            the format name. For example to specify the JPG Comment parameter,
            pass a struct such as this: options.JPG.Comment='abc'. Similarly,
            options.PNG.BitDepth=4. Only used by PNG,TIF,JPG,GIF output formats.
            Options can also be specified as a cell array of name-value pairs,
            e.g. {'BitDepth',4, 'Author','Yair'} - these options will be used
            by all supported output formats of the export_fig command.
  -silent - option to avoid various warning and informational messages, such
            as version update checks, transparency or renderer issues, etc.
  -notify - option to notify the user when export is done, in both a console
            message and a popup dialog (allow opening the exported file/folder).
  -regexprep <old> <new> - replaces all occurances of <old> (a regular expression
            string or array of strings; case-sensitive), with the corresponding
            <new> string(s), in EPS/PDF files (only). See regexp function's doc.
            Warning: invalid replacement can make your EPS/PDF file unreadable!
  -toolbar - adds an interactive export button to the figure's toolbar
  -menubar - adds an interactive export menu to the figure's menubar
  -contextmenu - adds interactive export menu to figure context-menu (right-click)
  handle -  handle of the figure, axes or uipanels (can be an array of handles
            but all the objects must be in the same figure) to be exported.
            Default: gcf (handle of current figure).
  figName - name (title) of the figure to export (e.g. 'Figure 1' or 'My fig').
            Overriden by handle (if specified); Default: current figure

Outputs:
  imageData - MxNxC uint8 image array of the exported image.
  alpha     - MxN single array of alphamatte values in the range [0,1],
              for the case when the background is transparent.

Some helpful examples/tips are listed at: https://github.com/altmany/export_fig

See also PRINT, SAVEAS, ScreenCapture (on the Matlab File Exchange)

Copyright (C) Oliver Woodford 2008-2014, Yair Altman 2015-
