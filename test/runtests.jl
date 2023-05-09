using DellReplicate
using Test

@testset "DellReplicate.jl" begin
    # Write your tests here.

    df = "climate_panel_csv.csv"
    @test size(DellReplicate.read_csv(df)) == (9296,23)
end
