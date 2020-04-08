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

const fbit_scale = 256  # 2^n_frac with n_frac = 8 fraction bits
const two56_over_logof2 = fbit_scale/log(2f0)
const logfixpoint16_max = Int32(2^15)
const bit15flip = Int32(2^14)    # flip the meaning of the sign bit of integers
const bit14flip = UInt16(2^13)

function LogFixPoint16(f::Float32)
    iszero(f) && return zero(LogFixPoint16)
    ~isfinite(f) && return nan(LogFixPoint16)

    # two56_logof2 = 256/log(2) to shift by 8 fraction bits, 256=2^8
    # use log instead of log2 as it's faster and include 1/log(2) in the constant
    val = Int32(round(two56_over_logof2*log(abs(f)))) + bit15flip
    sign = ((reinterpret(UInt32,f) & 0x8000_0000) >> 16) % UInt16

    # check for over or underflow
    underflow = val < zero(Int32)
    overflow = val > logfixpoint16_max

    # overflow returns 0x8000 (NaR) underflow returns 0x0000 (zero)
    # both have val = 0
    val = underflow | overflow ? zero(Int32) : val
    sign = underflow ? 0x0000 : sign
    sign = overflow ? 0x8000 : sign

    result = sign | (val % UInt16)

    return reinterpret(LogFixPoint16,result)
end

function createF32LookupTable(nint::Int,nfrac::Int)

    table = Array{UInt32,1}(undef,2^(nint+nfrac))

    c = Float32(2^nfrac)        # use f32 to avoid a promotion to f64 in the loop
    bias = 2^(nint+nfrac-1)	    # exponent bias for signed integers

    for i in 1:2^(nint+nfrac)
        # convert index to signed integer, with signbit flipped
        si = i-bias
        # store floats as UInt32 for bitwise operations
        table[i] = reinterpret(UInt32,2f0^(si/c))
    end

    return table
end

# for 7 integer bits and 8 fraction bits
const f32lookup = createF32LookupTable(7,8)

function Float32(x::LogFixPoint16)
    iszero(x) && return 0f0
    isnan(x) && return NaN32

    ui = reinterpret(UInt16,x)
    val = ui & 0x7fff     # set the signbit to zero

    # set all except sign bit to zero
    # sign = either 0x8000_0000 or 0x0000_0000
    sign = ((ui & 0x8000) % UInt32) << 16

    @inbounds f = sign | f32lookup[val]
    return reinterpret(Float32,f)
end

Float64(x::LogFixPoint16) = Float64(Float32(x))
Float16(x::LogFixPoint16) = Float16(Float32(x))
LogFixPoint16(x::Float64) = LogFixPoint16(Float32(x))
LogFixPoint16(x::Float16) = LogFixPoint16(Float32(x))
Int(x::LogFixPoint16) = Int(Float32(x))
LogFixPoint16(x::Int) = LogFixPoint16(Float32(x))

function Base.:(*)(x::LogFixPoint16,y::LogFixPoint16)
    iszero(x) | iszero(y) && return zero(LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    sign = xsign ⊻ ysign
	# xval and yval both contain the bias bit15flip
	# so subtract bit15flip, such that the result is again
	# biased with (a single) + bit15flip
    val = xval + yval - bit15flip

    # check for over or underflow
    underflow = val < zero(Int32)
    overflow = val > logfixpoint16_max

    # overflow returns 0x8000 (NaR) underflow returns 0x0000 (zero)
    # both have val = 0
    val = underflow | overflow ? zero(Int32) : val
    sign = underflow ? 0x0000 : sign
    sign = overflow ? 0x8000 : sign

    result = sign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end

function Base.:(/)(x::LogFixPoint16,y::LogFixPoint16)
    iszero(x) | iszero(y) && return zero(LogFixPoint16)
    isnan(x) | isnan(y) && return nan(LogFixPoint16)

    uix = reinterpret(UInt16,x)
    uiy = reinterpret(UInt16,y)

    xsign = uix & 0x8000
    ysign = uiy & 0x8000

    xval = (uix & 0x7fff) % Int32
    yval = (uiy & 0x7fff) % Int32

    sign = xsign ⊻ ysign
    # xval and yval both contain the bias bit15flip
    # so add bit15flip, such that the result is again
    # biased with (a single) + bit15flip
    val = xval - yval + bit15flip

    # check for over or underflow
    underflow = val < zero(Int32)
    overflow = val > logfixpoint16_max

    # overflow returns 0x8000 (NaR) underflow returns 0x0000 (zero)
    # both have val = 0
    val = underflow | overflow ? zero(Int32) : val
    sign = underflow ? 0x0000 : sign
    sign = overflow ? 0x8000 : sign

    result = sign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end

function Base.sqrt(x::LogFixPoint16)
	iszero(x) && return zero(LogFixPoint16)
	signbit(x) && return nan(LogFixPoint16) #TODO throw DomainError?

	uix = reinterpret(UInt16,x)
	uix = (uix >> 1) + bit14flip
	return reinterpret(LogFixPoint16,uix)
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
function createAddLookup(a::Int,n::Integer)
	tab = Array{Int32,1}(undef,n)

	for i in 0:n-1
		tab[i+1] = Int32(round(-i+a*log2(1+2^(i/a))))
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
function createSubLookup(a::Int,n::Integer)
	tab = Array{Int32,1}(undef,n)

    tab[1] = -logfixpoint16_max

	for i in 1:n-1
		tab[i+1] = -max(-Int32(round(-i+a*log2(abs(1-2^(i/a))))) -1,0)
	end

	return tab
end

const max_diff_resolvable = Int32(2440)     # table indices higher than that are 0
const addTable = createAddLookup(fbit_scale,max_diff_resolvable)
const subTable = createSubLookup(fbit_scale,max_diff_resolvable)

function Base.:(+)(x::LogFixPoint16,y::LogFixPoint16)
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

    # pull Gaussian logarithms from addTable
	@inbounds increment = diff < max_diff_resolvable ?
            (xsign == ysign ? addTable[diff+1] : subTable[diff+1]) : zero(Int32)
	val = yval + increment

	# check for over or underflow
    underflow = val < zero(Int32)
    overflow = val > logfixpoint16_max

    # overflow returns 0x8000 (NaR) underflow returns 0x0000 (zero)
    # both have val = 0
    val = underflow | overflow ? zero(Int32) : val
    ysign = underflow ? 0x0000 : ysign
    ysign = overflow ? 0x8000 : ysign

    result = ysign | (val % UInt16)
    return reinterpret(LogFixPoint16,result)
end


function Base.:(-)(x::LogFixPoint16,y::LogFixPoint16)
	return x + (-y)
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

function Base.prevfloat(x::LogFixPoint16,n::Int)
	for i in 1:n
		x = prevfloat(x)
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

function Base.log2(x::LogFixPoint16)
	signbit(x) | iszero(x) && return nan(LogFixPoint16)
	ui =  reinterpret(UInt16,x) % Int
	ui -= Int(bit15flip)
	ui /= 2^8
	return ui
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
		return "$(s[1]) $(s[2:8]) $(s[9:end])"
    else
        return bitstring(x)
    end
end
