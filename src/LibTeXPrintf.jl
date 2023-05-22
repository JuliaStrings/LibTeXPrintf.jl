module LibTeXPrintf

using Base: ImmutableDict
using Printf: Format, argmismatch
using LaTeXStrings

include("wrapper.jl")
using .libtexprintf

include("capture.jl")


export stexprintf, texprintf, texsymbols, texfonts, texsetfont, texgetfont

function __init__()
    # this is a workaround so `stdout` can work correctly and be captured by Suppressor
    # libtexprintf.texprintf("")
    TEXSYMBOLS[] = ImmutableDict([
        if length(line) == 4
            String(line[2] * line[3]) => String(line[4])
        else
            String(line[2]) => String(line[3])
        end for line in split.(split(strip(capture_out() do
                    libtexprintf.texlistsymbols()
                end, '\n'), '\n'))
    ]...)
end

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
const TEXFONTS =
    (
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
        "text"
    )

"""
    texfonts()

Returns a `Tuple` with all the LaTeX fonts that the library supports.

See also [`texsetfont`](@ref), [`texgetfont`](@ref).

# Examples
```jldoctest
julia> texfonts()
("mathsfbfit", "mathsfbf", "mathfrak", "mathbfit", "mathsfit", "mathcal", "mathscr", "mathbf", "mathbb", "mathsf", "mathtt", "mathnormal", "text")
```
"""
texfonts() = TEXFONTS

"""
    texsetfont(font::String)

Set the text font to use in the functions `texprintf` and `stexprintf`. It only
accepts fonts specified in `texfonts()`.

Return `font` if successful, throws an `ArgumentError` if failed.

See also [`texgetfont`](@ref), [`texfonts`](@ref).

# Examples
```jldoctest
julia> texprintf("This is a LaTeX string.")
This is a LaTeX string.

julia> texsetfont("text")
"text"

julia> texsetfont("mathbb")
"mathbb"

julia> texprintf("This is a LaTeX string.")
𝕋𝕙𝕚𝕤 𝕚𝕤 𝕒 𝕃𝕒𝕋𝕖𝕏 𝕤𝕥𝕣𝕚𝕟𝕘.

julia> texsetfont("text")
"text"

julia> texprintf("This is a LaTeX string.")
This is a LaTeX string.

julia> try
           texsetfont("not_a_font")
       catch (e)
           println(e isa ArgumentError)
           println(e)
       end
true
ArgumentError("\"not_a_font\" not in (\"mathsfbfit\", \"mathsfbf\", \"mathfrak\", \"mathbfit\", \"mathsfit\", \"mathcal\", \"mathscr\", \"mathbf\", \"mathbb\", \"mathsf\", \"mathtt\", \"mathnormal\", \"text\")")
```
"""
function texsetfont(font::String)
    idx = findfirst(==(font), TEXFONTS)
    if isnothing(idx)
        throw(ArgumentError("\"$font\" not in $(texfonts())"))
    end
    libtexprintf.TEXPRINTF_FONT[] = pointer(TEXFONTS[idx])
    return font
end

"""
    texgetfont()

Get the text font set to use in the functions `texprintf` and `stexprintf`.

Return a `String` of the specified in `texfonts()`.

See also [`texsetfont`](@ref), [`texfonts`](@ref).

# Examples
```jldoctest
julia> texgetfont()
"text"

julia> texsetfont("mathbb")

julia> texgetfont()
"mathbb"
```
"""
texgetfont() = unsafe_string(libtexprintf.TEXPRINTF_FONT[])

"""
    texerrors()

Returns a string of errors occurred using the library. The error queue is
cleaned every time this function is called.

It is used only for internal handling of the library, for the construction of
the error messages thrown by [`texprintf`](@ref) and [`stexprintf`](@ref).

# Examples
```jldoctest
julia> texerrors() # no errors
""

julia> LibTeXPrintf.libtexprintf.texprintf("\\frac{1}") # force an error internally

1

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


"""
    stexprintf(format::String, args...)
    stexprintf(format::LaTeXString, args...; clean=true)

Write in a string rendered LaTeX from `format`, and format `args` values using
the same format specifiers as macro `@printf` (or the `printf` function of the
language C).

If `format isa LaTeXString`, then the keyword `clean` is present. When
`clean=true` then `format` is  changed for `strip(format, '\$')`, stripping of
the initial and ending `'\$'`.

Returns a `String` that when printed displays as rendered LaTeX.

See also [`texprintf`](@ref).

!!! note
    If you try to print a new line character in (`'\\n'`) inside a
    `LaTeXString`, it will error saying `ERROR: ArgumentError: Unknown command
    (1x)`. This is because LaTeXStrings.jl escapes the string from `"\\n"` to
    `"\\\\n"` and when libtexprintf sees it, it looks like a LaTeX command, just
    not one that it knows about.

    There is also the problem that libtexprintf will actually just **ignore**
    all the new line characters (`'\\n'`).

# Examples
```jldoctest
julia> out = stexprintf("\\\\frac{1}{%d}", 2)
"1\\n─\\n2"

julia> println(out)
1
─
2

julia> out = stexprintf("\\\\sum_{i=0}^{10}{%c}^2", 'i')
"10\\n⎯⎯\\n╲   2\\n╱  i\\n⎺⎺\\ni=0"

julia> println(out)
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0

julia> using LaTeXStrings

julia> out = stexprintf(L"\\sum_{i=0}^{10}{%c}^2", 'i')
"10\\n⎯⎯\\n╲   2\\n╱  i\\n⎺⎺\\ni=0"
```
"""
function stexprintf(format::String, args...)
    if !iszero(length(format))
        f = Format(format)
        length(f.formats) == length(args) || argmismatch(length(f.formats), length(args))
    else
        length(args) == 0 || argmismatch(0, length(args))
    end
    cstr = libtexprintf.stexprintf(format, args...)
    if !iszero(libtexprintf.TEXPRINTF_ERR[])
        error = texerrors()
        throw(ArgumentError(error))
    end
    out = unsafe_string(cstr)
    libtexprintf.texfree(cstr)
    out
end
function stexprintf(format::LaTeXString, args...; clean=true)
    if clean
        stexprintf(String(strip(format.s, '$')), args...)
    else
        stexprintf(format.s, args...)
    end
end

"""
    texprintf([io::IO], format::String, args...)
    texprintf([io::IO], format::LaTeXString, args...; clean=true)

Prints rendered LaTeX from `format`, and format `args` values using the same
format specifiers as the macro `@printf` (or the `printf` function of the
language C).

If `format isa LaTeXString`, then the keyword `clean` is present. When
`clean=true` then `format` is  changed for `strip(format, '\$')`, stripping of
the initial and ending `'\$'`.

Returns nothing.

See also [`stexprintf`](@ref).

!!! note
    If you try to print a new line character in (`'\\n'`) inside a
    `LaTeXString`, it will error saying `ERROR: ArgumentError: Unknown command
    (1x)`. This is because LaTeXStrings.jl escapes the string from `"\\n"` to
    `"\\\\n"` and when libtexprintf sees it, it looks like a LaTeX command, just
    not one that it knows about.

    There is also the problem that libtexprintf will actually just **ignore**
    all the new line characters (`'\\n'`).

# Examples
```jldoctest
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

julia> using LaTeXStrings

julia> texprintf("\\\\sum_{i=0}^{10}{%c}^2", 'i')
10
⎯⎯
╲   2
╱  i
⎺⎺
i=0
```
"""
function texprintf(io::IO, format::String, args...)
    if !iszero(length(format))
        f = Format(format)
        length(f.formats) == length(args) || argmismatch(length(f.formats), length(args))
    else
        length(args) == 0 || argmismatch(0, length(args))
    end
    out = capture_out() do
        libtexprintf.texprintf(format, args...)
    end
    if !iszero(libtexprintf.TEXPRINTF_ERR[])
        error = texerrors()
        throw(ArgumentError(error))
    end
    print(io, out)
end
texprintf(format::String, args...) = texprintf(stdout, format::String, args...)

function texprintf(io::IO, format::LaTeXString, args...; clean=true)
    if clean
        texprintf(String(strip(format.s, '$')), args...)
    else
        texprintf(format.s, args...)
    end
end
texprintf(format::LaTeXString, args...) = texprintf(stdout, format, args...)

end
