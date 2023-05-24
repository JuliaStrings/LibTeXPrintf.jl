module LibTeXPrintf

using Base: ImmutableDict

include("wrapper.jl")
using .libtexprintf

export texstring, texprint, texprintln, texsymbols, texfonts, texsetfont!, texgetfont, texsetascii, texsetunicode

# set line width
texsetlw!(lw) = libtexprintf.TEXPRINTF_LW[] = lw

function _texsymbols()
    i = 1
    symbols = Vector{Pair{String,Char}}()
    table = LibTeXPrintf.libtexprintf.TEXPRINTF_SYMBOLS[]
    sym = unsafe_load(table, i)
    while sym.name != C_NULL
        push!(symbols, unsafe_string(sym.name) => Char(sym.unicode))
        sym = unsafe_load(table, i)
        i += 1
    end
    return symbols
end

"""
    TEXSYMBOLS::ImmutableDict{String, Char}

Dictionary with all the symbols that the library supports.
"""
const TEXSYMBOLS = ImmutableDict(_texsymbols()...)

"""
    texsymbols()

Returns an immutable dictionary with all the LaTeX symbols that the library supports.
"""
texsymbols() = TEXSYMBOLS

"""
    TEXFONTS::NTuple{String}

Tuple with all the font types that the library supports.
"""
const TEXFONTS = (
    "mathbb",
    "mathbf",
    "mathbfit",
    "mathcal",
    "mathfrak",
    "mathnormal",
    "mathscr",
    "mathsf",
    "mathsfbf",
    "mathsfbfit",
    "mathsfit",
    "mathtt",
    "text",
)

"""
    texfonts()

Returns a `Vector` with all the LaTeX fonts that the library supports.

See also [`texsetfont!`](@ref), [`texgetfont`](@ref).

# Examples
```jldoctest
julia> texfonts()
("mathbb", "mathbf", "mathbfit", "mathcal", "mathfrak", "mathnormal", "mathscr", "mathsf", "mathsfbf", "mathsfbfit", "mathsfit", "mathtt", "text")
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
ArgumentError("\"not_a_font\" not in (\"mathbb\", \"mathbf\", \"mathbfit\", \"mathcal\", \"mathfrak\", \"mathnormal\", \"mathscr\", \"mathsf\", \"mathsfbf\", \"mathsfbfit\", \"mathsfit\", \"mathtt\", \"text\")")
```
"""
function texsetfont!(font::String)
    idx = findfirst(==(font), TEXFONTS)
    if isnothing(idx)
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
    c_str = libtexprintf.texerrors_str()
    if c_str == C_NULL
        throw(ArgumentError("Returned Cstring pointer is C_NULL"))
    end
    errors = unsafe_string(c_str)
    libtexprintf.texfree(c_str)
    return errors
end

@doc raw"""
   texstring(str::String; [lw=0], [fail=true])

Write in a string rendered LaTeX from `str`. The keywork `lw` determines the linewidth used
to render the text boxes, a linewidth of 0 means no linewidth limit.

Returns a `String` that when displayed shows as rendered LaTeX.

See also [`texprint`](@ref), [`texprintln`](@ref).

!!! note
    Newline character is not supported by libtexprintf. You can insert a line jump with
    `\\`, as in LaTeX. If you use `'\n'`, it will not work or errors will appear.

# Examples
```jldoctest
julia> out = texstring("\\frac{1}{2}")
"1\n─\n2"

julia> println(out)
1
─
2

julia> println(texstring("tiny cute box for me"; lw=10))
tiny cute
box for me
```
"""
function texstring(tex::String; lw=0, #= debug =# fail=true)
    texsetlw!(lw) # set the linewidth for rendering
    c_str = libtexprintf.texstring(tex) # can be C_NULL
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

@doc raw"""
   texprint([io::IO=stdout], str::String; [lw=0], [fail=true])

Printf to `io` a string rendered LaTeX from `str` without trailing newline. The keywork `lw`
determines the linewidth used to render the text boxes, a linewidth of 0 means no linewidth
limit.

See also [`texstring`](@ref), [`texprintln`](@ref).

!!! note
    Newline character is not supported by libtexprintf. You can insert a line jump with
    `\\`, as in LaTeX. If you use `'\n'`, it will not work or errors will appear.

# Examples
```jldoctest
julia> texprint("\\frac{1}{2}")
1
─
2
julia> texprint(texstring("tiny cute box for me"; lw=10))
tiny cute
box for me
```
"""
texprint(tex::String; lw=0, #= debug =# fail=true) = texprint(stdout, tex; lw, fail)
texprint(io::IO, tex::String; lw=0, #= debug =# fail=true) = print(io, texstring(tex; lw, fail))

@doc raw"""
   texprintln([io::IO=stdout], str::String; [lw=0], [fail=true])

Same as [texprint](@ref) with a trailing newline.

See also [`texstring`](@ref), [`texprint`](@ref).

# Examples
```jldoctest
julia> texprintln("\\frac{1}{2}")
1
─
2

julia> texprintln(texstring("tiny cute box for me"; lw=10))
tiny cute
box for me

```
"""
texprintln(tex::String; lw=0, #= debug =# fail=true) = texprintln(stdout, tex; lw, fail)
texprintln(io::IO, tex::String; lw=0, #= debug =# fail=true) = println(io, texstring(tex; lw, fail))

end
