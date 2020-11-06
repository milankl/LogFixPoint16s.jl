import Base: Float64, Float32, Float16, Int

abstract type AbstractLogFixPoint <: AbstractFloat end

""" LogFixPoint16 is a logarithmic fixed-point number format with

1 sign bit
7 signed integer bits, with its signbit (=bit 15) flipped (i.e. excess-8)
8 fraction bits.

Exceptions
0x0000      = zero
0x8000      = Not-a-Real (NaR)."""
primitive type LogFixPoint16 <: AbstractLogFixPoint 16 end

Base.iszero(x::LogFixPoint16) = reinterpret(UInt16,x) == 0x0000
Base.isnan(x::LogFixPoint16) = reinterpret(UInt16,x) == 0x8000
Base.signbit(x::LogFixPoint16) = (reinterpret(UInt16,x) & 0x8000) == 0x8000

Base.zero(::Type{LogFixPoint16}) = reinterpret(LogFixPoint16,0x0000)
nan(::Type{LogFixPoint16}) = reinterpret(LogFixPoint16,0x8000)

Base.floatmin(::Type{LogFixPoint16}) = reinterpret(LogFixPoint16,0x0001)
Base.floatmax(::Type{LogFixPoint16}) = reinterpret(LogFixPoint16,0x7fff)

# In the absence of -Inf,Inf define typemin,typemax as floatmin,floatmax
Base.typemin(::Type{LogFixPoint16}) = floatmin(LogFixPoint16)
Base.typemax(::Type{LogFixPoint16}) = floatmax(LogFixPoint16)

Base.one(::Type{LogFixPoint16}) = reinterpret(LogFixPoint16,0x4000)

function Base.:(-)(x::LogFixPoint16)
    iszero(x) && return zero(LogFixPoint16)
    isnan(x) && return nan(LogFixPoint16)
    return reinterpret(LogFixPoint16,reinterpret(UInt16,x) ⊻ 0x8000)
end

function Base.inv(x::LogFixPoint16)
    iszero(x) && return nan(LogFixPoint16)
    ui = reinterpret(UInt16,x)
    sign = ui & 0x8000
    val = -ui & 0x7fff		# two's complement of all except sign bit
    return reinterpret(LogFixPoint16,sign | val)
end

# Default number of fraction bits
const nfrac = Ref{Int}(9)
const nint = Ref{Int}(15-nfrac[])
const scale = Ref{Int}(2^nfrac[])
const scale_over_logof2 = Ref{Float32}(scale[]/log(2f0))
const max_nfrac_supported = 11

""" 32-bit value of floatmax/min are derived from

    Int32(round(scale[]*(-(2^i-2^-j)-1))) + bit15flip

where i=nint-1, j=nfrac."""
const logfixpoint16_max = Int32(2^15-1)             # val of floatmax
const logfixpoint16_halfmin = Int32(-2^nfrac[]+1)   # val of half floatmin
const bit15flip = Int32(2^14)    # flip the meaning of the sign bit of integers
const bit14flip = UInt16(2^13)
const uintbit15flip = UInt16(2^14)    # used for power2

"""Constant to convert from round-to-nearest in log to linear space.

Let
    1 = s*log2(f1)
    1.5 = s*log2(f2)
    2 = s*log2(f3)

With some scale s. Now f2 is not the arithmetic mean of f1,f3. Let f2* be that mean

    f2* = 2^(1/s-1) + s^(2/s-1)

Then we find a constant c_b to be added before rounding by

    1.5 = c_b + 2*log2(f2*)
    => c_b = 1.5 - s*log2(f2*)"""
const c_b = Ref{Float32}(Float32(1.5-scale[]*log2(2^(1/scale[]-1) + 2^(2/scale[]-1))))

"""Convert a Float32 to LogFixPoint16 via the base-2 logarithm and rounding.
Round to nearest is applied in lin-space due to the addition of c_b."""
function LogFixPoint16(f::Float32)
    iszero(f) && return zero(LogFixPoint16)
    ~isfinite(f) && return nan(LogFixPoint16)

    # scale_over_logof2 = scale/log(2) to scale by nfrac fraction bits
    # use log instead of log2 as it's faster and include 1/log(2) in the constant
    val = Int32(round(c_b[] + scale_over_logof2[]*log(abs(f)))) + bit15flip
    sign = ((reinterpret(UInt32,f) & 0x8000_0000) >> 16) % UInt16

    sign,val = under_overflow_check(sign,val)
    result = sign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end

"""Check for under or overflow:

    - Any result beyond floatmax returns floatmax. (No-overflow rounding mode)
    - Any result smaller than floatmin/2 returns 0, any result between
        floatmin and floatmin/2 returns floatmin."""
function under_overflow_check(sign::UInt16,val::Int32)

    underflow = val < logfixpoint16_halfmin
    overflow = val > logfixpoint16_max

    val, sign = underflow ? (zero(Int32), 0x0000) : (max(val,one(Int32)), sign)
    val = overflow ? logfixpoint16_max : val

    return sign,val
end

"""Pre-calcualte look-up table for conversion from LogFixPoint16 to Float32."""
function createF32LookupTable(nint::Int,nfrac::Int)

    N = 2^(nint+nfrac)      # length of the table
    table = Array{UInt32,1}(undef,N)
    s = 2^nfrac             # scale
    bias = 2^(nint+nfrac-1) # exponent bias (=bit15flip)

    for i in 1:N
        # convert index to signed integer, with signbit flipped
        si = i-bias
        # store float32s as UInt32 for bitwise operations
        table[i] = reinterpret(UInt32,Float32(2.0 ^ (si/s)))
    end

    return table
end

const f32lookup = createF32LookupTable(nint[],nfrac[])

"""Conversion function from LogFixPoint16 to Float32 via table lookup
after branching off the special cases 0,NaR."""
function Float32(x::LogFixPoint16)
    iszero(x) && return 0f0
    isnan(x) && return NaN32

    ui = reinterpret(UInt16,x)
    val = ui & 0x7fff     # set the signbit to zero

    # set all except sign bit to zero
    # sign = either 0x8000_0000 or 0x0000_0000
    sign = ((ui & 0x8000) % UInt32) << 16

    # combine sign and table lookup
    @inbounds f = sign | f32lookup[val]
    return reinterpret(Float32,f)
end

# conversion between LogFixPoint16 and various floats
Float64(x::LogFixPoint16) = Float64(Float32(x))
Float16(x::LogFixPoint16) = Float16(Float32(x))
LogFixPoint16(x::Float64) = LogFixPoint16(Float32(x))
LogFixPoint16(x::Float16) = LogFixPoint16(Float32(x))
Int(x::LogFixPoint16) = Int(Float32(x))
LogFixPoint16(x::Int) = LogFixPoint16(Float32(x))

"""Multiplication for LogFixPoint16, equivalent to an addition of the exponents."""
function Base.:(*)(x::LogFixPoint16,y::LogFixPoint16)
    # special cases NaR*y = x*NaR = NaR
    isnan(x) | isnan(y) && return nan(LogFixPoint16)
    # if no NaN present: 0*y = x*0 = 0
    iszero(x) | iszero(y) && return zero(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    # mask exponent
    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    # mask the sign and cast to Int32
    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    # resulting sign
    sign = xsign ⊻ ysign

    # ADD EXPONENTS
    # xval and yval both contain the bias bit15flip
    # so subtract bit15flip, such that the result is again
    # biased with (a single) + bit15flip
    val = xval + yval - bit15flip

    # check for over or underflow
    sign,val = under_overflow_check(sign,val)

    # merge sign and exponent back together
    result = sign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end

"""Division for LogFixPoint16, equivalent to a subtraction of the exponents."""
function Base.:(/)(x::LogFixPoint16,y::LogFixPoint16)
    # special case, if either x,y =NaN, or y=0 return NaR
    isnan(x) | isnan(y) | iszero(y) && return nan(LogFixPoint16)
    # else if x=0 return 0
    iszero(x) && return zero(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    # extract sign
    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    # extract exponent
    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    # combine to obtain the sign of the result
    sign = xsign ⊻ ysign

    # SUBTRACT EXPONENTS
    # xval and yval both contain the bias bit15flip
    # so add bit15flip, such that the result is again
    # biased with (a single) + bit15flip
    val = xval - yval + bit15flip

    sign,val = under_overflow_check(sign,val)

    # merge sign and exponent val
    result = sign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end

function Base.sqrt(x::LogFixPoint16)
    iszero(x) && return zero(LogFixPoint16)
    signbit(x) && return nan(LogFixPoint16) #TODO throw DomainError?

    uix = reinterpret(UInt16,x)
    #TODO is this correct rounding?
    uix = (uix >> 1) + bit14flip
    return reinterpret(LogFixPoint16,uix)
end

function power2(x::LogFixPoint16)
    iszero(x) && return zero(LogFixPoint16)
    isnan(x) && return nan(LogFixPoint16)
    uix = reinterpret(UInt16,x)
    uix = (uix << 1) + uintbit15flip
    return reinterpret(LogFixPoint16,uix & 0x7fff)
end

""" Precomputes the Gaussian Logarithm as a table lookup for addition. Let

X = (-1)^signx * 2^x
Y = (-1)^signy * 2^y
Z = (-1)^signz * 2^z

then additions can be computed via the Gaussian logarithms

z = log2(||X|+|Y||) = x + log2(1+2^(y-x))

For fixed-point number exponents, interpreted as integers
including a bias c, x̂ = ax + c, where a = 2^n_frac the number of fraction bits:

ẑ = x̂ + a*log2(1+2^((ŷ-x̂)/a)     or
ẑ = ŷ - (ŷ-x̂) + a*log2(1+2^((ŷ-x̂)/a)

The last two terms are precomputed into a table lookup."""
function createAddLookup(scale::Int)

    tab = Array{Int32,1}(undef,max_table_size)

    for i in 0:max_table_size-1
        tab[i+1] = -i + Int(round(c_b[] + scale*log2(1+2^(i/scale))))
    end

    return tab
end

""" Precomputes the Gaussian Logarithm as a table lookup for subtraction.
Subtractions can be computed via the Gaussian logarithms

z = log2(||X|-|Y||) = x + log2(abs(1-2^(y-x)))

For fixed-point number exponents, interpreted as integers
including a bias c, x̂ = ax + c, where a = 2^n_frac the number of fraction bits:

ẑ = x̂ + a*log2(abs(1-2^((ŷ-x̂)/a))     or
ẑ = ŷ - (ŷ-x̂) + a*log2(abs(1-2^((ŷ-x̂)/a))

The last two terms are precomputed into a table lookup."""
function createSubLookup(scale::Int)
    tab = Array{Int32,1}(undef,max_table_size)

    # set the first entry manually to avoid -Inf due to the log2(0)
    tab[1] = -logfixpoint16_max-1

    for i in 1:max_table_size-1
        tab[i+1] = -i + Int(round(c_b[] + scale*log2(abs(1-2^(i/scale)))))
    end

    return tab
end

# table indices higher than that are 0
function find_max_diff_res(scale::Int)
    i = 1
    while (-i + round(c_b[] + scale*log2(1+2^(i/scale)))) > 0.0
        i += 1
    end
    return Int32(i)
end

const max_diff_resolvable = Ref{Int32}(find_max_diff_res(scale[]))
const max_table_size = find_max_diff_res(2^max_nfrac_supported)+1
const addTable = createAddLookup(scale[])
const subTable = createSubLookup(scale[])

function Base.:(+)(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    # zero is an exceptional case and not reprsentable as (-1)^s * 2^x
    iszero(x) && return y
    iszero(y) && return x

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    # y is always the larger value
    # resulting sign is always that of y
    # in a-a sign is 1, but case is caught in underflow: sign set to 0
    xval,yval,xsign,ysign = xval > yval ? (yval,xval,ysign,xsign) : (xval,yval,xsign,ysign)
    diff = yval - xval     # diff >= 0

    # pull Gaussian logarithms from addTable, subTable
    # update yval with the increment
    @inbounds increment = diff < max_diff_resolvable[] ?
        (xsign == ysign ? addTable[diff+1] : subTable[diff+1]) : zero(Int32)
    yval += increment

    # check for over or underflow
    ysign,yval = under_overflow_check(ysign,yval)

    result = ysign | (yval % UInt16)
    return reinterpret(LogFixPoint16,result)
end

function diff_val(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    # y is always the larger value
    # resulting sign is always that of y
    # in a-a sign is 1, but case is caught in underflow: sign set to 0
    xval,yval,xsign,ysign = xval > yval ? (yval,xval,ysign,xsign) : (xval,yval,xsign,ysign)
    diff = yval - xval     # diff >= 0
end

"""Subtraction for LogFixPoint16 via sign switch of y as in x-y = x + (-y)."""
Base.:(-)(x::LogFixPoint16,y::LogFixPoint16) = x + (-y)

"""Rounding to integer via conversion to Float32."""
Base.round(x::LogFixPoint16, r::RoundingMode{:Up}) = Int(ceil(Float32(x)))
Base.round(x::LogFixPoint16, r::RoundingMode{:Down}) = Int(floor(Float32(x)))
Base.round(x::LogFixPoint16, r::RoundingMode{:Nearest}) = Int(round(Float32(x)))

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
	@eval Base.promote_rule(::Type{LogFixPoint16}, ::Type{$t}) = LogFixPoint16
end

function Base.nextfloat(x::LogFixPoint16)
    isnan(x) && return nan(LogFixPoint16)
    (x == -floatmin(LogFixPoint16)) && return zero(LogFixPoint16)

    sign = signbit(x)
    ui = reinterpret(UInt16,x)
    sign && return reinterpret(LogFixPoint16,ui - 0x0001)
    return reinterpret(LogFixPoint16,ui + 0x0001)
end

function Base.nextfloat(x::LogFixPoint16,n::Int)
    for i in 1:n
        x = nextfloat(x)
    end
    return x
end

function Base.prevfloat(x::LogFixPoint16)
	# -floatmax is 0xffff and would otherwise prevfloat to 0=0x0000
    isnan(x) | (x == -floatmax(LogFixPoint16)) && return nan(LogFixPoint16)

    sign = signbit(x)
    ui = reinterpret(UInt16,x)
    sign && return reinterpret(LogFixPoint16,ui + 0x0001)
    return reinterpret(LogFixPoint16,ui - 0x0001)
end

function Base.prevfloat(x::LogFixPoint16,n::Int)
    for i in 1:n
        x = prevfloat(x)
    end
    return x
end

function Base.log2(x::LogFixPoint16)
	signbit(x) | iszero(x) && return nan(LogFixPoint16)
	ui =  reinterpret(UInt16,x) % Int
	ui -= Int(bit15flip)
	ui /= scale
	return LogFixPoint16(ui)
end

function Base.:(==)(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return false
    return reinterpret(UInt16,x) == reinterpret(UInt16,y)
end

function Base.:(>)(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xsign > ysign && return false
    xsign < ysign && return true

    return uix > uiy
end

function Base.:(<)(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xsign > ysign && return true
    xsign < ysign && return false

    return uix < uiy
end

function Base.:(<=)(x::LogFixPoint16,y::LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xsign > ysign && return true
    xsign < ysign && return false

    return uix <= uiy
end

# Showing
function Base.show(io::IO, x::LogFixPoint16)
    if isnan(x)
        print(io, "NaR")
    else
		io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"LogFixPoint16("*f*")")
    end
end

Base.bitstring(x::LogFixPoint16) = bitstring(reinterpret(UInt16,x))

function Base.bitstring(x::LogFixPoint16,mode::Symbol)
    if mode == :split	# split into sign, integer, fraction
        s = bitstring(x)
		return "$(s[1]) $(s[2:nint[]+1]) $(s[nint[]+2:end])"
    else
        return bitstring(x)
    end
end
