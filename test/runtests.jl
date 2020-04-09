using Test
using LogFixPoint16s

@testset "Zero" begin
    @test iszero(LogFixPoint16(0))
    @test iszero(LogFixPoint16(-0))
    @test LogFixPoint16(0) == LogFixPoint16(-0)

    @test LogFixPoint16(0) == zero(LogFixPoint16)
    @test 0x0000 == reinterpret(UInt16,zero(LogFixPoint16))
    @test 0x0000 == reinterpret(UInt16,-zero(LogFixPoint16))

    @test iszero(zero(LogFixPoint16))
end

@testset "NaR" begin
    @test reinterpret(UInt16,nan(LogFixPoint16)) == 0x8000
    @test isnan(nan(LogFixPoint16))
end

@testset "signbit" begin
    @test signbit(LogFixPoint16(-1))
    @test signbit(LogFixPoint16(-10))
    @test ~signbit(LogFixPoint16(0))
    @test ~signbit(LogFixPoint16(1))
    @test ~signbit(floatmax(LogFixPoint16))
    @test ~signbit(floatmin(LogFixPoint16))
end

@testset "floatmin/max" begin
    @test floatmin(LogFixPoint16) < floatmax(LogFixPoint16)
    @test zero(LogFixPoint16) < floatmin(LogFixPoint16)
    @test prevfloat(floatmin(LogFixPoint16)) == zero(LogFixPoint16)
    @test isnan(nextfloat(floatmax(LogFixPoint16)))
end

@testset "one" begin
    @test one(LogFixPoint16) == LogFixPoint16(1)
    @test reinterpret(UInt16,one(LogFixPoint16)) == 0x4000
end

@testset "negation" begin
    @test -(-(one(LogFixPoint16))) == one(LogFixPoint16)
    @test -zero(LogFixPoint16) == zero(LogFixPoint16)
    @test -nan(LogFixPoint16) != nan(LogFixPoint16)
    @test -LogFixPoint16(1) == LogFixPoint16(-1)
end

@testset "inverse" begin
    @test inv(one(LogFixPoint16)) == one(LogFixPoint16)
    @test isnan(inv(zero(LogFixPoint16)))
    @test inv(LogFixPoint16(2)) == LogFixPoint16(0.5)
    @test inv(LogFixPoint16(-2)) == LogFixPoint16(-0.5)
    @test inv(LogFixPoint16(4)) == LogFixPoint16(0.25)
    @test isnan(inv(nan(LogFixPoint16)))
end

@testset "conversion" begin
    @test Float32(LogFixPoint16(1)) == 1f0
    @test Float32(LogFixPoint16(1f0)) == 1f0
    @test Float32(LogFixPoint16(1.0)) == 1f0

    @test Float64(LogFixPoint16(1)) == 1.0
    @test Float64(LogFixPoint16(1f0)) == 1.0
    @test Float64(LogFixPoint16(1.0)) == 1.0

    @test Float32(LogFixPoint16(0)) == 0f0
    @test Float32(LogFixPoint16(-0)) == 0f0
    @test Float32(LogFixPoint16(-1)) == -1f0
    @test Float32(LogFixPoint16(-8)) == -8f0
    @test Float32(LogFixPoint16(-0.125)) == -0.125f0

    @test Int(LogFixPoint16(4)) == 4
    @test Int(LogFixPoint16(-2)) == -2

    @test isnan(LogFixPoint16(NaN32))
    @test isnan(LogFixPoint16(NaN))
    @test isnan(LogFixPoint16(Inf))
    @test isnan(LogFixPoint16(-Inf))
end

@testset "multiplication" begin
    @test LogFixPoint16(1)*LogFixPoint16(2) == LogFixPoint16(2)
    @test LogFixPoint16(123)*inv(LogFixPoint16(123)) == one(LogFixPoint16)
    @test Float32(LogFixPoint16(-8)*LogFixPoint16(8)) == -64f0
    @test Float32(LogFixPoint16(-8)*LogFixPoint16(-0.125)) == 1f0
    @test iszero(LogFixPoint16(0)*LogFixPoint16(12.1234))
    @test iszero(LogFixPoint16(0)*LogFixPoint16(-12.1234))
end

@testset "division" begin
    @test one(LogFixPoint16) / one(LogFixPoint16) == one(LogFixPoint16)
    @test LogFixPoint16(-0.1273) / LogFixPoint16(0.1273) == -one(LogFixPoint16)
    @test LogFixPoint16(4) / LogFixPoint16(2) == LogFixPoint16(2)
    @test isnan(LogFixPoint16(3)/zero(LogFixPoint16))
    @test LogFixPoint16(3.123)/LogFixPoint16(0.1232) ==
            LogFixPoint16(3.123)*inv(LogFixPoint16(0.1232))
end

@testset "sqrt" begin
    @test sqrt(LogFixPoint16(4)) == LogFixPoint16(2)
    @test sqrt(LogFixPoint16(12.56))^2 == prevfloat(LogFixPoint16(12.56))
    @test isnan(sqrt(LogFixPoint16(-1)))
    @test iszero(sqrt(LogFixPoint16(0)))
end

@testset "addition" begin
    a,b,c,d,e = LogFixPoint16.([-8,-4,-2,0,1])

    @test a+b == b+a
    @test a+d == a
    @test e+e == -c
    @test -(c+c) == -b
    @test d+e == e+d
end

@testset "subtraction" begin
    a,b,c,d,e = LogFixPoint16.([-8,-4,-2,0,1])

    @test a-b == -(b-a)
    @test c-a == -(a-c)
    @test d-a == -a
    @test a-a == d
    @test (a+b-c) == prevfloat(a-c+b)
    @test (a+b-c) == prevfloat(a-(c-b))
end

@testset "nextfloat prevfloat" begin
    a = floatmin(LogFixPoint16)
    b = floatmax(LogFixPoint16)
    c = LogFixPoint16(123)

    @test nextfloat(prevfloat(c)) == c
    @test prevfloat(nextfloat(c)) == c
    @test prevfloat(c) < c
    @test prevfloat(-c) > -c
    @test nextfloat(c) > c
    @test nextfloat(-c) < -c

    @test iszero(prevfloat(a))
    @test iszero(nextfloat(-a))
    @test isnan(nextfloat(b))
    @test isnan(prevfloat(-b))

    @test nextfloat(nextfloat(c)) == nextfloat(c,2)
    @test prevfloat(prevfloat(c)) == prevfloat(c,2)
end
