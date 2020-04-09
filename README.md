[![Build Status](https://travis-ci.com/milankl/LogFixPoint16s.jl.svg?branch=master)](https://travis-ci.com/milankl/LogFixPoint16s.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/milankl/LogFixPoint16s.jl?svg=true)](https://ci.appveyor.com/project/milankl/LogFixPoint16s-jl)

# LogFixPoint16s.jl

Exports LogFixPoint16 - a 16bit [logarithmic fixed-point number](https://en.wikipedia.org/wiki/Logarithmic_number_system) format with 1 sign bit, 7 signed integer bits, and 8 fraction bits.

### Example use

```julia
julia> using LogFixPoint16s
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

```julia
julia> bitstring(LogFixPoint16(3),:split)
"0 1000001 10010110"
```
The sign bit is `0`, the sign bit of the signed integer is `1` (meaning +, [excess-8](https://en.wikipedia.org/wiki/Signed_number_representations#Comparison_table) representation) such that the integer bits equal to `1`. The fraction bits are 1/2 + 1/16 + 1/64 + 1/128. Together this is

```
0 1000001 10010110 = +2^(1 + 1/2 + 1/16 + 1/64 + 1/128) = 2^1.5859375 ≈ 3
```
The only exceptions are the bitpatterns `0x0000` (zero) and `0x8000` (Not-a-Real, NaR). The smallest/largest representable numbers are

```julia
julia> floatmin(LogFixPoint16)
LogFixPoint16(5.435709e-20)

julia> floatmax(LogFixPoint16)
LogFixPoint16(1.8396865e19)
```
 
### Decimal precision

Logarithmic fixed-point numbers are placed equi-distantly on a log-scale. Consequently, their decimal precision is perfectly flat throughout the dynamic range of representable numbers. In contrast, floating-point numbers are only equi-distant on a log-scale when the significand is held fixed; the significant bits, however, are placed equi-distant on a non-log scale.

As a consequence there is no rounding error for logarithmic fixed-point numbers in multiplication, division or power/root - similarly as there is no rounding error for fixed-point numbers for addition and subtraction.

![decimal precision](figs/decimal_precision.png?raw=true "decimal precision")

### Benchmarks

`LogFixPoint16` is considerably faster than `Float16` for addition (x1.5) and multiplication (x20)

```julia
julia> using LogFixPoint16s, BenchmarkTools
julia> A = rand(Float32,1000,1000);
julia> B = Float16.(A);
julia> C = LogFixPoint16.(A);
julia> @btime +($A,$A);       # Float32
  478.892 μs (2 allocations: 3.81 MiB)

julia> @btime +($B,$B);       # Float16
  9.966 ms (2 allocations: 1.91 MiB)

julia> @btime +($C,$C);       # LogFixPoint16
  6.127 ms (2 allocations: 1.91 MiB)
  
julia> @btime .*($A,$A);      # Float32
  390.930 μs (2 allocations: 3.81 MiB)

julia> @btime .*($B,$B);      # Float16
  18.753 ms (2 allocations: 1.91 MiB)

julia> @btime .*($C,$C);      # LogFixPoint16
  801.077 μs (2 allocations: 1.91 MiB)
```


### Installation

```julia
julia> ] add https://github.com/milankl/LogFixPoints.jl
```
