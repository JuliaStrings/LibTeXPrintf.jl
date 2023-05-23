using LibTeXPrintf
using LaTeXStrings
using Test

import LibTeXPrintf: texerrors, libtexprintf


@testset "LibTeXPrintf.jl" begin
    @test texerrors() == ""
    @test texfonts() ==
    sort!([
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
    ])
    @test texgetfont() == "text"

    @test texsetfont("mathbb") == "mathbb"
    @test texgetfont() == "mathbb"
    @test stexprintf("string") == "𝕤𝕥𝕣𝕚𝕟𝕘"

    @test texsetfont("text") == "text"
    @test texgetfont() == "text"
    @test stexprintf("string") == "string"

    @test stexprintf(L"") == ""
end
