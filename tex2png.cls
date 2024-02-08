\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tex2png}[2024-02-08 Compile document to images]

\RequirePackage{kvoptions}  % to process key-value options
\RequirePackage{shellesc}   % to run system commands

\SetupKeyvalOptions{
    family=ttp,
    prefix=ttp@
}

% define option to use `article` (default) or `standalone` as base class
\newif\ifexportimgs
\def\ttp@baseclass{article}
\DeclareVoidOption{exportimgs}{
    \exportimgstrue
    \gdef\ttp@baseclass{standalone}
}

% define option to set output directory for images (default: current folder)
\DeclareStringOption[.]{exportdir}

% define option to customize name of export environment (default: `exportimg`)
\DeclareStringOption[exportimg]{exportenv}

% define options to control quality and size of images
\DeclareStringOption[2]{exportsupersample}
\DeclareStringOption[1.5]{exportscale}

% define option to set background color, instead of transparent (default)
% this is also used as border color
\DeclareStringOption{exportbg}[white]

% define option to set border width (default: 5px all sides)
\DeclareStringOption[5]{exportborder}

% pass all other options to base class
\DeclareDefaultOption{
    \expandafter\PassOptionsToClass\expandafter{\CurrentOption}{\ttp@baseclass}
}

% evaluate all options (within the family defined by `\SetupKeyvalOptions`)
\ProcessKeyvalOptions*

% define export environment if it doesn't exist (regardless of base class)
\ifcsname\ttp@exportenv\endcsname\else
    \newenvironment\ttp@exportenv\empty\empty
\fi

% If we use `\%` in the command definition below, the backslash never disappears from the command
% (possibly due to a `\detokenize` somewhere). Therefore, we:
%  1. temporarily categorize the percent sign as a "letter",
%  2. define a command that inserts a percent sign,
%  3. restore the percent sign as a "comment character".
\catcode`\%=11
\newcommand\percent{%}
\catcode`\%=14

\ifexportimgs
    % compute density and scale arguments
    \def\ttp@density{\fpeval{72 * \ttp@exportsupersample * \ttp@exportscale}}
    \def\ttp@scale{\fpeval{100 / \ttp@exportsupersample}\percent}

    % define ImageMagick command to convert pdf to png
    % for gm see: https://sourceforge.net/p/graphicsmagick/discussion/250738/thread/8643b1af/#0fdf
    \def\ttp@command{
        magick
            -units PixelsPerInch
            -density \ttp@density\space
            \noexpand\infile\space
            -scale \ttp@scale\space
            -density 72                         % set density of png to 72 dpi (metadata only)
            -trim
          \ifx\ttp@exportbg\empty
            -bordercolor transparent
          \else
            -background \ttp@exportbg\space
            -bordercolor \ttp@exportbg\space
            -alpha remove
          \fi
          \ifx\ttp@exportborder\empty\else
            -border \ttp@exportborder\space
          \fi
            +adjoin                             % force separate output files (required for gm)
            \ttp@exportdir/\noexpand\outfile
    }

    % create image output directory
    \ShellEscape{mkdir \ttp@exportdir}

    % configure standalone such that the content of each export environment is cropped on a separate
    % page and then converted to a png using ImageMagick
    \PassOptionsToClass{
        preview,                % automatically ignores content outside export environments
        border=1cm,             % solves https://tex.stackexchange.com/q/53220; trimmed off later
        multi=\ttp@exportenv,
        varwidth,               % not always perfect, but further trimmed by ImageMagick
        convert={
            command=\noexpand\ttp@command
        }
    }{standalone}
\fi

% load base class
\LoadClass{\ttp@baseclass}
