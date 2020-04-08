function representable_ints(nbits)
    return 1:(2^(nbits-1)-1)
end

function representable_floats(nbits,ebits)
    #= returns an array of all representable positive floats exclusive 0 and ComplexInfinity.
    nbits is the total number of bits (sign,exponent,significand)
    ebits is the number of exponent bits
    =#

    # derived constants
    bias = 2^(ebits-1) - 1
    sbits = nbits-ebits-1     # number of significand bits (minus one for sign bit)

    repr_floats = []           # represented as 000...0000

    # subnormal numbers (exponent is 0)
    for f = 1:2^sbits-1
        append!(repr_floats,2.0^(1-bias)*(f/2^sbits))
    end

    # all other numbers
    for e = 1:2^ebits-2     # the exponent cannot be 11...111 this represents NaN
        for f = 0:2^sbits-1
            append!(repr_floats,2.0^(e-bias)*(1.0 + f/2^sbits))
        end
    end

    return Float64.(repr_floats)
end

function wcdp_posit(plist)
    p_am = (plist[1:end-1]+plist[2:end])/2.
    p_wda = -log10.(abs.(log10.(p_am./plist[1:end-1])))

    # extend first and last point, taking no overflow/underflow into account
    p0 = plist[1]/16    # something much smaller than minpos
    pinf = plist[end]*16    # something much bigger than maxpos

    p_wda_0 = -log10.(abs.(log10.(p0/plist[2]))) # worst-case decimal accuracy for these extreme values
    p_wda_inf = -log10.(abs.(log10.(pinf/plist[end])))

    # worst-case decimal accuracy of interpolated on minpos/maxpos
    p_wda_minpos = p_wda_0 + log10(plist[1]/p0)/log10(p0/p_am[1])*(p_wda_0-p_wda[1])
    p_wda_maxpos = p_wda_inf + log10(plist[end]/pinf)/log10(pinf/p_am[end])*(p_wda_inf-p_wda[end])

    p_wda = vcat(p_wda_0,p_wda_minpos,p_wda,p_wda_maxpos,p_wda_inf)
    p_am = vcat(p0,plist[1],p_am,plist[end],pinf)

    return p_am,p_wda,plist
end

function wcdp_float(flist)

    f_am = (flist[1:end-1]+flist[2:end])/2.
    f_wda = -log10.(abs.(log10.(f_am./flist[1:end-1])))

    # extend with zeros due to overflow
    f_wda = vcat(0.55,f_wda)        # extrapolate somehow
    f_am = vcat(flist[1],f_am)

    return f_am,f_wda
end

function wcdp_approx(flist)

    f_am = (flist[1:end-1]+flist[2:end])/2.
    f_wda = -log10.(abs.(log10.(f_am./flist[1:end-1])))

    return f_am,f_wda
end

function wc_dec_acc_int(nbits)

    # assume rounding mode down
    # somehow interpolate with 0.13 onto the smallest representable number 1...

    i_am = [1.,2.,2^(nbits-1)-1]
    i_wda = [0.13,-log10(abs(log10(2))),-log10(abs(log10((2^(nbits-1)-1)/(2^(nbits-1)-2))))]

    return i_am,i_wda
end

decprec(xe,xr) = -log10.(abs.(log10.(xe./xr)))
