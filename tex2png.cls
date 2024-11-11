\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tex2png}[2024-02-12 v1.0.0 Compile document to images]

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
\DeclareStringOption[2]{exportscale}

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

\ifexportimgs
    % compute density and scale arguments
    \def\ttp@densityout{\fpeval{72 * \ttp@exportscale}}
    \def\ttp@densityin{\fpeval{\ttp@densityout * \ttp@exportsupersample}}
    \def\ttp@scale{\fpeval{100 / \ttp@exportsupersample}\@percentchar}

    % define ImageMagick command to convert pdf to png
    \def\ttp@command{
        magick
            -units PixelsPerInch
            -density \ttp@densityin\space
            \noexpand\infile\space
            -scale \ttp@scale\space
            -density \ttp@densityout\space    % metadata only
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
\else
    % define export environment if it doesn't exist
    \AtBeginDocument{
        \ifcsname\ttp@exportenv\endcsname\else
            \newenvironment\ttp@exportenv\empty\empty
        \fi
    }
\fi

% load base class
\LoadClass{\ttp@baseclass}
