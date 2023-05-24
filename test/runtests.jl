using LibTeXPrintf
using LaTeXStrings
using Test

import LibTeXPrintf: texerrors, libtexprintf, stexprint


@testset "LibTeXPrintf.jl" begin
    @test texerrors() == ""
    @test texfonts() == sort!([
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
    @test texgetfont() == "text"

    @test texsetfont!("mathbb") == "mathbb"
    @test texgetfont() == "mathbb"
    @test stexprintf("string") == "𝕤𝕥𝕣𝕚𝕟𝕘"

    @test texsetfont!("text") == "text"
    @test texgetfont() == "text"
    @test stexprintf("string") == "string"

    @test_throws ArgumentError texsetfont!("not_a_font")

    @test stexprintf(L"") == "\$\$"

    tex_basel = L"The Basel problem (find if $\sum_{n\in\mathbb{R}}\left(\frac{1}{n^2}\right)$ converge and, if so, to what value) was solved by Leonhard Euler in 1734, yielding that the serie converge to $\sqrt{\frac{1}{\pi}}$. Hint: Euler used the next Taylor series $$ \frac{\sin(x)}{x} = x^{%d} - \frac{x^%d}{%d!} + \frac{x^%d}{%d!} - \frac{x^%d}{%d!} + ...$$"
    basel_out = "                            ⎯⎯\n                            ╲  ⎛1 ⎞\nThe Basel problem (find if \$╱  ⎜──⎟\$ converge and, if so, to what value) was\n                            ⎺⎺ ⎜ 2⎟\n                            n∈ℝ⎝n ⎠\n                                                                         ┌─┐\n                                                                         │1\nsolved by Leonhard Euler in 1734, yielding that the serie converge to \$╲ │─ \$.\n                                                                        ╲│π\n                                                          2    4    6\n                                           sin(x)    1   x    x    x\nHint: Euler used the next Taylor series \$\$ ────── = x  - ── + ── - ── + ...\$\$\n                                             x           3!   5!   7!"
    if Sys.iswindows()
        # TODO: @test_logs (?)
        @info stexprintf(tex_basel, 1:7...; lw=80, fail=false)
        @test_broken stexprintf(tex_basel, 1:7...; lw=80) == basel_out
    else
        @test stexprintf(tex_basel, 1:7...; lw=80) == basel_out
    end

    # println(basel)
    #
    ####################################################################################
    #                              ⎯⎯                                                  #
    #                              ╲  ⎛1 ⎞                                             #
    #  The Basel problem (find if $╱  ⎜──⎟$ converge and, if so, to what value) was    #
    #                              ⎺⎺ ⎜ 2⎟                                             #
    #                              n∈ℝ⎝n ⎠                                             #
    #                                                                           ┌─┐    #
    #                                                                           │1     #
    #  solved by Leonhard Euler in 1734, yielding that the serie converge to $╲ │─ $.  #
    #                                                                          ╲│π     #
    #                                                           2    4    6            #
    #                                             sin(x)       x    x    x             #
    #  Hint: Euler used the next Taylor series $$ ────── = x - ── + ── - ── + ...$$    #
    #                                               x          3!   5!   7!            #
    #                                                                                  #
    ####################################################################################

    if Sys.islinux()
        @test stexprint("\\frac{1}{%%d}") == " 1\n───\n%%d"
    else
        @info stexprint("\\frac{1}{%%d}"; fail=false)
        @test_broken stexprint("\\frac{1}{%%d}") == " 1\n───\n%%d"
    end

    @test_throws ArgumentError stexprint("\$\\frac{1}\$")
    # @test stexprint("\$\\frac{1}\$", fail=false) == "\$"

    if Sys.islinux()
        @test stexprint("\\\\%") == "{%}"
    else
        @info stexprint("\\\\%"; fail=false)
        @test_broken stexprint("\\\\%") == "{%}"
    end
end
