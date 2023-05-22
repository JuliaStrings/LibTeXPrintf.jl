# LibTeXPrintf

[![Build Status](https://github.com/Suavesito-Olimpiada/LibTeXPrintf.jl/workflows/CI/badge.svg)](https://github.com/Suavesito-Olimpiada/LibTeXPrintf.jl/actions)
[![Coverage](https://codecov.io/gh/Suavesito-Olimpiada/LibTeXPrintf.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Suavesito-Olimpiada/LibTeXPrintf.jl)


Wrapper of the library
[bartp5/libtexprintf](https://github.com/bartp5/libtexprintf) for
printing rendered LaTeX code in the terminal.

Given that libtexprintf is licensed under the GPL-3.0 and this library link
dynamically with it, the full work must be GPL-3.0. The LICENCE was changed to
make clear that using this library implies using GPLed code.

## Installation

To install LibTeXPrintf.jl, in the Julia REPL

```julia
julia> using Pkg
julia> Pkg.add("LibTeXPrintf")
```

# Documentation

LibTeXPrintf.jl export six three functions

```julia
texfonts()::NTuple(N, String)
texgetfont()::String
texsetfont(font::String)::String

texsymbols()::ImmutableDict{String, String}

stexprintf(format::String, args...)::String
stexprintf(format::LaTeXString, args...; clean=true)::String

texprintf([io::IO], format::String, args...)
texprintf([io::IO], format::LaTeXString, args...; clean=true)
```

The documentation of every one of these can be consulted in help mode in the
REPL (press `?` to change to help mode, `backspace` to exit).

### Format string

The `format` positional argument is interpreted as $\LaTeX$ code, but with the
extra that format specifiers of `@printf` (or the `printf` function in the
C language) are allowed inside.

The argument `format` can also be a `LaTeXString`, from
[LaTeXStrings.jl](https://github.com/stevengj/LaTeXStrings.jl), in which case
the keyword argument `clean` is present (and defaults to `true`). When
`clean=true`, then format is changed into `strip(format, '$')`.

**Note**
:   If you try to print a new line character in (`'\n'`) inside a
    `LaTeXString`, it will error saying `ERROR: ArgumentError: Unknown command
    (1x)`. This is because LaTeXStrings.jl escapes the string from `"\n"` to
    `"\\n"` and when libtexprintf sees it, it looks like a LaTeX command, just
    not one that it knows about.

    There is also the problem that libtexprintf will actually just **ignore**
    all the new line characters (`'\n'`).

## Examples

```julia
julia> using LibTeXPrintf

julia> using LaTeXStrings

julia> texprintf("\\\\frac{1}{%d}", 2)
1
─
2

julia> texprintf("\\\\sum_{i=0}^{10}{%c}^2", 'i')
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0

julia> texsetfont("mathbb")
"mathbb"

julia> texprintf("This is a LaTeX string.")
𝕋𝕙𝕚𝕤 𝕚𝕤 𝕒 𝕃𝕒𝕋𝕖𝕏 𝕤𝕥𝕣𝕚𝕟𝕘.

julia> texsetfont("text")
"text"

julia> texprintf("This is a LaTeX string.")
"This is a LaTeX string."
```

