\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{tex2img}[2024-01-04 Compile document to images]

% import package to process key-value options
\RequirePackage{kvoptions}
\SetupKeyvalOptions{
    family=tti,
    prefix=tti@
}

% define option to use `article' (default) or `standalone' as base class
\newif\iftti@standalone
\def\tti@baseclass{article}
\DeclareVoidOption{exportimgs}{
    \tti@standalonetrue
    \gdef\tti@baseclass{standalone}
}

% pass all other options to base class
\DeclareDefaultOption{
    \expandafter\PassOptionsToClass\expandafter{\CurrentOption}{\tti@baseclass}
}

% evaluate all options (within the family defined by \SetupKeyvalOptions)
\ProcessKeyvalOptions*

% define `exportimg' environment if it does not exist
\ifdefined\exportimg\else
    \newenvironment{exportimg}{}{}
\fi

\iftti@standalone
    % configure `standalone' such that the content of each `exportimg' environment is cropped (as
    % much as possible) on its own page
    \PassOptionsToClass{
        preview,
        border=1mm,
        multi={exportimg},
        varwidth
    }{standalone}
\fi

% load base class
\LoadClass{\tti@baseclass}
