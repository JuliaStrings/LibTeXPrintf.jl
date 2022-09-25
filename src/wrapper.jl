module libtexprintf

using LibTeXPrintf_jll
using CBinding

let
    incdir = joinpath(LibTeXPrintf_jll.artifact_dir, "include")
    libdir = dirname(LibTeXPrintf_jll.libtexprintf_path)

    if Sys.iswindows()
        c`-std=c99 -I$(incdir) -L$(libdir) -ltexprintf-1`
    else
        c`-std=c99 -I$(incdir) -L$(libdir) -ltexprintf`
    end
end

const c"size_t"  = Csize_t
# const c"FILE"    = Cvoid
c"typedef void FILE;"
const c"va_list" = Cvoid

c"""
    #include <texprintf.h>
"""j

end
