module LogFixPoint16s

    export LogFixPoint16, nan, power2

    include("logfixpoint16.jl")

    """Reset the constants to allow for arbitrary number of fraction bits."""
    function set_nfrac(n::Int)
        @assert (n > 6) && (n<max_nfrac_supported+1) "Only 6...11 fraction bits supported, $n given."

        # change pointer references based on n
        nfrac[] = n
        nint[] = 15-nfrac[]
        scale[] = 2^nfrac[]
        scale_over_logof2[] = scale[]/log(2f0)
        max_diff_resolvable[] = find_max_diff_res(scale[])

        # change Float32 lookup table for conversion LogFixPoint16 -> Float32
        f32lookup[:] = createF32LookupTable(nint[],nfrac[])

        # change addition and subtraction table
        addTable[:] = createAddLookup(scale[])
        subTable[:] = createSubLookup(scale[])

        @warn "LogFixPoint16 was changed to $(nint[]) integer and $(nfrac[]) fraction bits."

        return nothing
    end

    """Change the rounding mode from round-to-nearest in either linear or logarithmic space."""
    function set_rounding_mode(mode::Symbol=:lin)
        @assert mode in [:lin,:log] "only mode :lin or :log allowed."

        if mode == :log
            c_b[] = 0f0
        else
            c_b[] = Float32(1.5-scale[]*log2(2^(1/scale[]-1) + 2^(2/scale[]-1)))
        end
    
        # recalculate lookup tables
        max_diff_resolvable[] = find_max_diff_res(scale[])
        f32lookup[:] = createF32LookupTable(nint[],nfrac[])
        addTable[:] = createAddLookup(scale[])
        subTable[:] = createSubLookup(scale[])
    
        @warn "LogFixPoint16 rounding mode changed to round to nearest in $(string(mode))-space."
    end

end
