using Test
using LogFixPoint16s

# test for 7-11 fraction bits
LogFixPoint16s.set_nfrac(7)
include("logfixpoint16.jl")

LogFixPoint16s.set_nfrac(8)
include("logfixpoint16.jl")

LogFixPoint16s.set_nfrac(9)
include("logfixpoint16.jl")

LogFixPoint16s.set_nfrac(10)
include("logfixpoint16.jl")

LogFixPoint16s.set_nfrac(11)
include("logfixpoint16.jl")
