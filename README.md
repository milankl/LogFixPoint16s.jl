[![Build Status](https://travis-ci.com/milankl/LogFixPoints.jl.svg?branch=master)](https://travis-ci.com/milankl/LogFixPoints.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/milankl/LogFixPoints.jl?svg=true)](https://ci.appveyor.com/project/milankl/LogFixPoints-jl)

# LogFixPoints.jl

Exports LogFixPoint16 - a 16bit [logarithmic fixed-point number](https://en.wikipedia.org/wiki/Logarithmic_number_system) format with 1 sign bit, 7 signed integer bits, with its signbit (=bit 15) flipped (i.e. excess-8) and 8 fraction bits.

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

### Theory

A number `X` is encoded as LogFixPoint16 as

```
X = (-1)^s * 2^x
```
with `s` being the sign bit and `x` the fixed-point number in the exponent. E.g. the number `3` is encoded as

```
julia> bitstring(LogFixPoint16(3),:split)
"0 1000001 10010110"
```
The sign bit is `0`, the sign bit of the signed integer is `1` (meaning +, [excess-8](https://en.wikipedia.org/wiki/Signed_number_representations#Comparison_table) representation) such that the integer bits equal to `1`. The fraction bits are 1/2 + 1/16 + 1/64 + 1/128. Together this is

```
0 1000001 10010110 = +2^(1 + 1/2 + 1/16 + 1/64 + 1/128) = 2^1.5859375 ≈ 3
```
The only exceptions are the bitpatterns `0x0000` (zero) and `0x8000` (Not-a-Real, NaR).

### Installation

```julia
julia> ] add https://github.com/milankl/LogFixPoints.jl
```
