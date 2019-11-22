using FStrings
using Test


@testset "FStrings.jl" begin
    # Standard use cases
    x = 2
    y = 3
    @test f"{y}, {x}, {x+y}," == "3, 2, 5,"
    @test f"x={x:.2f}" == "x=2.00"
    @test f"π = {π:.2f}" == "π = 3.14"
    @test f"π = {π:.4f}" == "π = 3.1416"
    @test f"10π ≈ 0x{31:04x}" == "10π ≈ 0x001f"
    # Use case questionable:
    @test f"{[x^2 for x in 1:3]}" == "[1, 4, 9]"
    z = 11:13
    @test f"{z[2:end]}" == "12:13"
    # Assert that proper errors are thrown, if format specifier is malformed.
    @test_throws ArgumentError f"{0x2:02b}"  # Unfortunately bitfields are not supported
end
