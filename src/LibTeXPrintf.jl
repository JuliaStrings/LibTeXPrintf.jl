module LibTeXPrintf

using Base: ImmutableDict
using Printf: Format, format
using LaTeXStrings

include("wrapper.jl")
using .libtexprintf

include("capture.jl")


export stexprintf, texsymbols, texfonts, texsetfont!, texgetfont, texsetascii, texsetunicode

function __init__()
    texsetfont!("text")
    TEXSYMBOLS[] = ImmutableDict([
        if length(line) == 4
            String(line[2] * line[3]) => String(line[4])
        else
            String(line[2]) => String(line[3])
        end for line in split.(split(strip(capture_out() do
                    libtexprintf.texlistsymbols()
                    # this is a workaround so `stdout` can work correctly and be captured by
                    # Suppressor, this work by forcing a fflush on Libc using texerrors()
                    libtexprintf.texerrors()
                end, '\n'), '\n'))
    ]...)
end

# set line width
texsetlw!(lw) = libtexprintf.TEXPRINTF_LW[] = lw

"""
    TEXSYMBOLS::Ref{ImmutableDict{String, String}}

Dictionary with all the symbols that the library supports.
"""
const TEXSYMBOLS = Ref{ImmutableDict{String,String}}()

"""
    texsymbols()

Returns an immutable dictionary with all the LaTeX symbols that the library supports.
"""
texsymbols() = TEXSYMBOLS[]

"""
    TEXFONTS::Vector{String}

Dictionary with all the symbols that the library supports.
"""
const TEXFONTS = sort!([
    "mathsfbfit",
    "mathsfbf",
    "mathfrak",
    "mathbfit",
    "mathsfit",
    "mathcal",
    "mathscr",
    "mathbf",
    "mathbb",
    "mathsf",
    "mathtt",
    "mathnormal",
    "text",
])

"""
    texfonts()

Returns a `Vector` with all the LaTeX fonts that the library supports.

See also [`texsetfont!`](@ref), [`texgetfont`](@ref).

# Examples
```jldoctest
julia> texfonts()
13-element Vector{String}:
 "mathbb"
 "mathbf"
 "mathbfit"
 "mathcal"
 "mathfrak"
 "mathnormal"
 "mathscr"
 "mathsf"
 "mathsfbf"
 "mathsfbfit"
 "mathsfit"
 "mathtt"
 "text"
```
"""
texfonts() = TEXFONTS

"""
    texsetfont!(font::String)

Set the text font to use for `stexprintf`. It only accepts fonts from `texfonts()`.

Return `font` if successful, throws an `ArgumentError` if failed.

See also [`texgetfont`](@ref), [`texfonts`](@ref).

# Examples
```jldoctest
julia> texprintf("This is a LaTeX string.")
This is a LaTeX string.

julia> texgetfont()
"text"

julia> texsetfont!("mathbb")
"mathbb"

julia> texprintf("This is a LaTeX string.")
𝕋𝕙𝕚𝕤 𝕚𝕤 𝕒 𝕃𝕒𝕋𝕖𝕏 𝕤𝕥𝕣𝕚𝕟𝕘.

julia> texsetfont!("text")
"text"

julia> texprintf("This is a LaTeX string.")
This is a LaTeX string.

julia> try
           texsetfont!("not_a_font")
       catch (e)
           println(e isa ArgumentError)
           println(e)
       end
true
ArgumentError("\"not_a_font\" not in [\"mathbb\", \"mathbf\", \"mathbfit\", \"mathcal\", \"mathfrak\", \"mathnormal\", \"mathscr\", \"mathsf\", \"mathsfbf\", \"mathsfbfit\", \"mathsfit\", \"mathtt\", \"text\"]")
```
"""
function texsetfont!(font::String)
    idx = searchsorted(TEXFONTS, font)
    if isempty(idx)
        throw(ArgumentError("\"$font\" not in $(TEXFONTS)"))
    end
    libtexprintf.TEXPRINTF_FONT[] = pointer(TEXFONTS[first(idx)])
    return font
end

"""
    texgetfont()

Get the text font set to use for `stexprintf`.

Return a `String` of the specified in `texfonts()`.

See also [`texsetfont!`](@ref), [`texfonts`](@ref).

# Examples
```jldoctest
julia> texgetfont()
"text"

julia> texsetfont!("mathbb")
"mathbb"

julia> texgetfont()
"mathbb"
```
"""
texgetfont() = unsafe_string(libtexprintf.TEXPRINTF_FONT[])

texsetascii() = libtexprintf.SetStyleASCII()

texsetunicode() = libtexprintf.SetStyleUNICODE()

@doc raw"""
    texerrors()

Returns a string of errors occurred using the library. The error queue is
cleaned every time this function is called.

It is used only for internal handling of the library, for the construction of the error
messages thrown by [`stexprintf`](@ref).

# Examples
```jldoctest
julia> LibTeXPrintf.texerrors() # no errors
""

julia> LibTeXPrintf.libtexprintf.stexprintf("\$\\frac{1}\$"); # force an error internally

julia> LibTeXPrintf.texerrors()
"Too few mandatory arguments to command (1x)"

julia> LibTeXPrintf.texerrors() # queue cleaned
""
```
"""
function texerrors()
    error = capture_err() do
        libtexprintf.texerrors()
    end
    if iszero(length(error))
        return ""
    end
    return error[8:end-1]
end


@doc raw"""
    stexprintf(format::String, args...; [lw=0])
    stexprintf(format::LaTeXString, args...; [lw=0])

Write in a string rendered LaTeX from `format`, and format `args` values using the same
format specifiers as macro `@printf` (or the `printf` function of the language C). The
keywork `lw` determines the linewidth used to render the text boxes, a linewidth of 0 means
no linewidth limit.

If `format isa LaTeXString`, then it only is passed as `format.s`.

Returns a `String` that when displayed shows as rendered LaTeX.

!!! note
    Newline character is not supported by libtexprintf. You can insert a line jump with
    `\\`, as in LaTeX. If you use `'\n'`, it will not work or errors will appear.

# Examples
```jldoctest
julia> out = stexprintf("\\frac{1}{%d}", 2)
"1\n─\n2"

julia> println(out)
1
─
2

julia> out = stexprintf("\\sum_{i=0}^{10}{%c}^2", 'i')
"10\n⎯⎯\n╲   2\n╱  i\n⎺⎺\ni=0"

julia> println(out)
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0

julia> using LaTeXStrings

julia> out = stexprintf(L"\sum_{i=0}^{10}{%c}^2", 'i')
" 10\n ⎯⎯\n ╲   2\n\$╱  i \$\n ⎺⎺\n i=0"

julia> println(out)
 10
 ⎯⎯
 ╲   2
$╱  i $
 ⎺⎺
 i=0

```
"""
stexprintf(fmt::String, args...; lw=0, #= debug =# fail=true) = stexprint(format(Format(fmt), args...); lw, fail)
stexprintf(fmt::LaTeXString, args...; lw=0, #= debug =# fail=true) = stexprint(format(Format(fmt.s), args...); lw, fail)

@doc raw"""
   stexprint(str::String; [lw=0])

Write in a string rendered LaTeX from `str`. The keywork `lw` determines the linewidth used
to render the text boxes, a linewidth of 0 means no linewidth limit.

Returns a `String` that when displayed shows as rendered LaTeX.

!!! note
    Newline character is not supported by libtexprintf. You can insert a line jump with
    `\\`, as in LaTeX. If you use `'\n'`, it will not work or errors will appear.

# Examples
```jldoctest
julia> out = stexprint("\\frac{1}{%d}", 2)
"1\n─\n2"

julia> println(out)
1
─
2

julia> out = stexprint("\\sum_{i=0}^{10}{%c}^2", 'i')
"10\n⎯⎯\n╲   2\n╱  i\n⎺⎺\ni=0"

julia> println(out)
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0

julia> println(stexprint("tiny cute box for me"; lw=5))
tiny
cute
box
for
me

julia> println(stexprint("tiny cute box for me"; lw=10))
tiny cute
box for me
```
"""
function stexprint(tex::String; lw=0, #= debug =# fail=true, escape=true)
    esctex = escape ? replace(tex, '%' => "{\\%%}") : tex # escape '%' for C-printf style format and latex
    texsetlw!(lw) # set the linewidth for rendering
    c_str = libtexprintf.stexprintf(esctex) # can be C_NULL
    if c_str == C_NULL
        throw(ArgumentError("Returned Cstring pointer is C_NULL"))
    end
    render = unsafe_string(c_str)
    libtexprintf.texfree(c_str)
    if !iszero(libtexprintf.TEXPRINTF_ERR[])
        error = texerrors()
        if fail
            throw(ArgumentError(error))
        else
            @error ArgumentError(error)
        end
    end
    render
end

end
