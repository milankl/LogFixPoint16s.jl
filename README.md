[![Build Status](https://travis-ci.com/milankl/LogFixPoints.jl.svg?branch=master)](https://travis-ci.com/milankl/LogFixPoints.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/milankl/LogFixPoints.jl?svg=true)](https://ci.appveyor.com/project/milankl/LogFixPoints-jl)

# LogFixPoints.jl

Exports LogFixPoint16 - a 16bit logarithmic fixed-point number format with 1 sign bit, 7 signed integer bits, with its signbit (=bit 15) flipped (i.e. excess-8) and 8 fraction bits.

### Example use

```julia
julia> using LogFixPoints
julia> v = LogFixPoint16.(rand(Float32,5))
5-element Array{LogFixPoint16,1}:
 LogFixPoint16(0.04741747)
 LogFixPoint16(0.82287776)
 LogFixPoint16(0.989228)
 LogFixPoint16(0.25409457)
 LogFixPoint16(0.37525353)

julia> sum(v)
LogFixPoint16(2.4837155)
```

### Features

Exports `LogFixPoint16, iszero, isnan, signbit, zero, nan, floatmin, floatmax, one, -, inv, *, / , +, -, sqrt, nextfloat, prevfloat, ==, <=, >, >=, show, bitstring` as well as conversions to and from `Float64, Float32, Float16, Int`. 

### Installation

```julia
julia> ] add https://github.com/milankl/LogFixPoints.jl
```
