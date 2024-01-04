\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tex2png}[2024-01-04 Compile document to images]

% import package to process key-value options
\RequirePackage{kvoptions}
\SetupKeyvalOptions{
    family=ttp,
    prefix=ttp@
}

% define option to use `article` (default) or `standalone` as base class
\newif\ifttp@standalone
\def\ttp@baseclass{article}
\DeclareVoidOption{exportimgs}{
    \ttp@standalonetrue
    \gdef\ttp@baseclass{standalone}
}

% define option to customize name of export environment
\DeclareStringOption[exportimg]{exportenv}

% define options to control quality and size of images
\DeclareStringOption[2]{exportsupersample}
\DeclareStringOption[1.5]{exportscale}

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

\ifttp@standalone
    % compute density and scale arguments
    \def\ttp@density{\fpeval{72 * \ttp@exportsupersample * \ttp@exportscale}}
    \def\ttp@scale{\fpeval{100 / \ttp@exportsupersample}\percent}

    % define ImageMagick command to convert pdf to png
    \def\ttp@command{
        magick
            -units PixelsPerInch
            -density \ttp@density\space
            \noexpand\infile\space
            -scale \ttp@scale\space
            -density 72                 % set density of png to 72 dpi (metadata)
            -trim
            \noexpand\outfile
    }

    % configure `standalone` such that the content of each export environment is cropped on a
    % separate page and then converted to a png using ImageMagick
    \PassOptionsToClass{
        preview,                % automatically ignores content outside export environments
        border=1mm,             % solves https://tex.stackexchange.com/q/53220; trimmed off later
        multi=\ttp@exportenv,
        varwidth,               % not always perfect, but further trimmed by ImageMagick
        convert={
            command=\noexpand\ttp@command
        }
    }{standalone}
\fi

% load base class
\LoadClass{\ttp@baseclass}
