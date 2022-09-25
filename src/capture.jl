# taken from Suppressor, but flush stdio from libc

function capture_out(cb)
    if ccall(:jl_generating_output, Cint, ()) == 0
        original_stdout = stdout
        out_rd, out_wr = redirect_stdout()
        out_reader = @async read(out_rd, String)
    end
    try
        cb()
        Base.Libc.flush_cstdio()
    finally
        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stdout(original_stdout)
            close(out_wr)
        end
    end
    if ccall(:jl_generating_output, Cint, ()) == 0
        fetch(out_reader)
    else
        ""
    end
end

function capture_err(cb)
    if ccall(:jl_generating_output, Cint, ()) == 0
        original_stderr = stderr
        err_rd, err_wr = redirect_stderr()
        err_reader = @async read(err_rd, String)
    end
    try
        cb()
        Base.Libc.flush_cstdio()
    finally
        if ccall(:jl_generating_output, Cint, ()) == 0
            redirect_stderr(original_stderr)
            close(err_wr)
        end
    end
    if ccall(:jl_generating_output, Cint, ()) == 0
        fetch(err_reader)
    else
        ""
    end
end
