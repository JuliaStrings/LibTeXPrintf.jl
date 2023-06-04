# LibTeXPrintf

[![Build Status](https://github.com/Suavesito-Olimpiada/LibTeXPrintf.jl/workflows/CI/badge.svg)](https://github.com/Suavesito-Olimpiada/LibTeXPrintf.jl/actions)
[![Coverage](https://codecov.io/gh/Suavesito-Olimpiada/LibTeXPrintf.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Suavesito-Olimpiada/LibTeXPrintf.jl)


Wrapper of the library
[bartp5/libtexprintf](https://github.com/bartp5/libtexprintf) for
printing rendered LaTeX code in the terminal.

Given that libtexprintf is licensed under the GPL-3.0 and this library links
dynamically with it, the full work must be GPL-3.0. The LICENCE was changed to
make clear that using this library implies using GPLed code.

## Installation

To install LibTeXPrintf.jl, in the Julia REPL

```julia
julia> using Pkg
julia> Pkg.add("LibTeXPrintf")
```

# Documentation

LibTeXPrintf.jl export nine functions

```julia
texfonts()::Vector{String}
texgetfont()::String
texsetfont!(font::String)::String # modifies global state, doesn't modify its argument

texsymbols()::ImmutableDict{String, String}

texstring(tex::String; [lw])::String

texprint(tex::String; [lw])::String
texprintln(tex::String; [lw])::String

texsetascii()
texsetunicode()
textogglesupersub()
```

The documentation of every one of these can be consulted in help mode in the
REPL (press `?` to change to help mode, `backspace` to exit).

**Note**
:   Newline character is not supported by libtexprintf. If you use it, it will not work or
    errors will appear.

## Examples

```julia
julia> using LibTeXPrintf

julia> using LaTeXStrings

julia> texstring("\\frac{1}{2}")
"1\n─\n2"

julia> texprintln("\\sum_{i=0}^{10}{i}^2")
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0

julia> texgetfont()
"text"

julia> texsetfont!("mathbb")
"mathbb"

julia> texprintln("This is a LaTeX string.")
𝕋𝕙𝕚𝕤 𝕚𝕤 𝕒 𝕃𝕒𝕋𝕖𝕏 𝕤𝕥𝕣𝕚𝕟𝕘.

julia> texsetfont!("text")
"text"

julia> texprint("This is a LaTeX string.")
"This is a LaTeX string."
```

