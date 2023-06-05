using LibTeXPrintf
using LaTeXStrings
using Test

import LibTeXPrintf: texerrors, libtexprintf, texstring


@testset "LibTeXPrintf.jl" begin
    @test texerrors() == ""
    @test texfonts() == ("mathbb", "mathbf", "mathbfit", "mathcal", "mathfrak", "mathnormal", "mathscr", "mathsf", "mathsfbf", "mathsfbfit", "mathsfit", "mathtt", "text")
    @test texgetfont() == "text"

    @test texsetfont!("mathbb") == "mathbb"
    @test texgetfont() == "mathbb"
    @test texstring("string") == "𝕤𝕥𝕣𝕚𝕟𝕘"

    @test texsetfont!("text") == "text"
    @test texgetfont() == "text"
    @test texstring("string") == "string"

    @test_throws ArgumentError texsetfont!("not_a_font")

    @test texstring(L"".s) == "\$\$"

    tex_basel = L"The Basel problem (find if $\sum_{n\in\mathbb{R}}\left(\frac{1}{n^2}\right)$ converge and, if so, to what value) was solved by Leonhard Euler in 1734, yielding that the serie converge to $\sqrt{\frac{1}{\pi}}$. Hint: Euler used the next Taylor series $$ \frac{\sin(x)}{x} = x^{1} - \frac{x^2}{3!} + \frac{x^4}{5!} - \frac{x^6}{7!} + ...$$"
    # basel_out = "                            ⎯⎯\n                            ╲  ⎛1 ⎞\nThe Basel problem (find if \$╱  ⎜──⎟\$ converge and, if so, to what value) was\n                            ⎺⎺ ⎜ 2⎟\n                            n∈ℝ⎝n ⎠\n                                                                         ┌─┐\n                                                                         │1\nsolved by Leonhard Euler in 1734, yielding that the serie converge to \$╲ │─ \$.\n                                                                        ╲│π\n                                                          2    4    6\n                                           sin(x)    1   x    x    x\nHint: Euler used the next Taylor series \$\$ ────── = x  - ── + ── - ── + ...\$\$\n                                             x           3!   5!   7!"
    basel_out = "                             ⎲ ⎛1 ⎞\nThe Basel problem (find if \$ ⎳ ⎜──⎟\$ converge and, if so, to what value) was\n                            n∈ℝ⎝n²⎠\n                                                                         ┌─┐\n                                                                         │1\nsolved by Leonhard Euler in 1734, yielding that the serie converge to \$╲ │─ \$.\n                                                                        ╲│π\n                                           sin(x)        x²   x⁴   x⁶\nHint: Euler used the next Taylor series \$\$ ────── = x¹ - ── + ── - ── + ...\$\$\n                                             x           3!   5!   7!"
    @test texstring(tex_basel.s; lw=80) == basel_out

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
    #                                                                                  #
    #                              ⎲ ⎛1 ⎞                                              #
    # The Basel problem (find if $ ⎳ ⎜──⎟$ converge and, if so, to what value) was     #
    #                             n∈ℝ⎝n²⎠                                              #
    #                                                                          ┌─┐     #
    #                                                                          │1      #
    # solved by Leonhard Euler in 1734, yielding that the serie converge to $╲ │─ $.   #
    #                                                                         ╲│π      #
    #                                            sin(x)        x²   x⁴   x⁶            #
    # Hint: Euler used the next Taylor series $$ ────── = x¹ - ── + ── - ── + ...$$    #
    #                                              x           3!   5!   7!            #
    #                                                                                  #
    ####################################################################################

    @test texstring("\\frac{1}{%%d}") == " 1\n───\n%d" # expected " 1\n───\n%%d"

    @test_throws ArgumentError texstring("\$\\frac{1}\$")
    @test_logs (:error, ArgumentError("Too few mandatory arguments to command (1x)")) texstring("\$\\frac{1}\$", fail=false) == "\$"
end
