using Test
using LogFixPoint

@test iszero(Approx16(0))
@test iszero(Approx16(-0))
