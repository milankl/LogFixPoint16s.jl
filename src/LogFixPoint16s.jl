module LogFixPoint16s

    export LogFixPoint16, nan

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
end
