\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tex2img}[2024-01-04 Compile document to images]

% import package to process key-value options
\RequirePackage{kvoptions}
\SetupKeyvalOptions{
    family=tti,
    prefix=tti@
}

% define option to use `article` (default) or `standalone` as base class
\newif\iftti@standalone
\def\tti@baseclass{article}
\DeclareVoidOption{exportimgs}{
    \tti@standalonetrue
    \gdef\tti@baseclass{standalone}
}

% define option to customize name of export environment
\DeclareStringOption[exportimg]{exportenv}

% define options to control quality and size of images
\DeclareStringOption[2]{exportsupersample}
\DeclareStringOption[1.5]{exportscale}

% pass all other options to base class
\DeclareDefaultOption{
    \expandafter\PassOptionsToClass\expandafter{\CurrentOption}{\tti@baseclass}
}

% evaluate all options (within the family defined by `\SetupKeyvalOptions`)
\ProcessKeyvalOptions*

% define export environment if it doesn't exist (regardless of base class)
\ifcsname\tti@exportenv\endcsname\else
    \newenvironment\tti@exportenv\empty\empty
\fi

% If we use `\%` in the command definition below, the backslash never disappears from the command
% (possibly due to a `\detokenize` somewhere). Therefore, we:
%  1. temporarily categorize the percent sign as a "letter",
%  2. define a command that inserts a percent sign,
%  3. restore the percent sign as a "comment character".
\catcode`\%=11
\newcommand\percent{%}
\catcode`\%=14

\iftti@standalone
    % compute density and scale arguments
    \def\tti@density{\fpeval{72 * \tti@exportsupersample * \tti@exportscale}}
    \def\tti@scale{\fpeval{100 / \tti@exportsupersample}\percent}

    % define ImageMagick command to convert pdf to png
    \def\tti@command{
        magick
            -units PixelsPerInch
            -density \tti@density\space
            \noexpand\infile\space
            -scale \tti@scale\space
            -density 72                 % set density of png to 72 dpi (metadata)
            -trim
            \noexpand\outfile
    }

    % configure `standalone` such that the content of each export environment is cropped on a
    % separate page and then converted to a png using ImageMagick
    \PassOptionsToClass{
        preview,                % automatically ignores content outside export environments
        border=1mm,             % solves https://tex.stackexchange.com/q/53220; trimmed off later
        multi=\tti@exportenv,
        varwidth,               % not always perfect, but further trimmed by ImageMagick
        convert={
            command=\noexpand\tti@command
        }
    }{standalone}
\fi

% load base class
\LoadClass{\tti@baseclass}
