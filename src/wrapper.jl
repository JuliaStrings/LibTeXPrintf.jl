module libtexprintf

import LibTeXPrintf_jll


mutable struct Global{T}
    x::Ptr{T}
    Global{T}() where {T} = new{T}(C_NULL)
end

Base.eltype(::Global{T}) where {T} = T

@inline function Base.getindex(g::Global{T}) where {T}
    @boundscheck g.x == C_NULL && throw(BoundsError(C_NULL))
    unsafe_load(g.x)
end

@inline function Base.setindex!(g::Global{T}, v) where {T}
    @boundscheck g.x == C_NULL && throw(BoundsError(C_NULL))
    unsafe_store!(g.x, v)
end

const TEXPRINTF_LW = Global{Cint}()
const TEXPRINTF_FONT = Global{Cstring}()
const TEXPRINTF_FCW = Global{Cint}()
const TEXPRINTF_WCW = Global{Cint}()
const TEXPRINTF_ERR = Global{Cint}()

macro load!(symbol)
    :(
        $symbol.x = Core.Intrinsics.cglobal(($(esc(QuoteNode(symbol))), $(QuoteNode(LibTeXPrintf_jll.libtexprintf))), eltype($symbol));
        $symbol
    )
end

function __init__()
    @load! TEXPRINTF_LW
    @load! TEXPRINTF_FONT
    @load! TEXPRINTF_FCW
    @load! TEXPRINTF_WCW
    @load! TEXPRINTF_ERR
end

# *name*          : *signature (type(type1,type2,...))*   -> *side effect*                        |
# ----------------+---------------------------------------++--------------------------------------+
# texprintf       : int(const char *format, ...)          -> c_stdout // (ignored)                |
# stexprintf      : char*(const char *format, ...)        -> memory associated to output (char*)  +-->+
# ftexprintf      : int(FILE *f, const char *format, ...) -> f        // (ignored)                |   |
# texboxtree      : void(const char *format, ...)         -> c_stdout // for debugging            |   |
# texlistsymbols  : void()                                -> c_stdout // called from __init__     |   |
# texerrors       : void()                                -> c_stderr // does a fflush!           |   v
# texfree         : void(void *ptr)                       -> ptr-associated memory  // to release +<--+
# SetStyleASCII   : void()                                -> STYLE_UNI // Not exported global     |
# SetStyleUNICODE : void()                                -> STYLE_ASC // Not exported global     |

# we ignore the fact that it can be formated with C style format specifiers, as we only pass
# "%"-escaped strings that will not need vararg
stexprintf(str) = @ccall LibTeXPrintf_jll.libtexprintf.stexprintf(str::Cstring)::Cstring

# we will capture stdout later
texlistsymbols() = @ccall LibTeXPrintf_jll.libtexprintf.texlistsymbols()::Cvoid

# we will capture stderr later
texerrors() = @ccall LibTeXPrintf_jll.libtexprintf.texerrors()::Cvoid

texfree(ptr) = @ccall LibTeXPrintf_jll.libtexprintf.texfree(convert(Ptr{Cvoid}, ptr)::Ptr{Cvoid})::Cvoid

SetStyleASCII() = @ccall LibTeXPrintf_jll.libtexprintf.SetStyleUNICODE()::Cvoid

SetStyleUNICODE() = @ccall LibTeXPrintf_jll.libtexprintf.SetStyleUNICODE()::Cvoid

end
