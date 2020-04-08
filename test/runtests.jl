using Test
using LogFixPoints

@test iszero(LogFixPoint16(0))
@test iszero(LogFixPoint16(-0))
@test LogFixPoint16(0) == LogFixPoint16(-0)
