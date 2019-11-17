using FStrings
using Test


@testset "FStrings.jl" begin
    x = 2
    y = 3
    @test f"{y}, {x}, {x+y}," == "3, 2, 5,"
    @test f"x={x:.2f}" == "x=2.00"
    @test f"π = {π:.2f}" == "π = 3.14"
    @test f"π = {π:.4f}" == "π = 3.1416"
    @test f"10π ≈ 0x{31:04x}" == "10π ≈ 0x001f"
end
