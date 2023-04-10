module DellReplicate

# Write your package code here.
    using DataFrames
    using CSV
    using ShiftedArrays: lag
    using Statistics
    using Impute
    using BenchmarkTools

    """
        gen_vars_fig1!(df::DataFrame)
    Generates the necessary mean temperature and precipiation variables for the two graphs of `Figure 1`, given the climate panel data.
    Returns the modified version of input `df`.
    """
    function gen_vars_fig1!(df)

        println(size(df))
        df2 = df[(df[!, :year] .>= 1950) .& (df[!, :year] .<= 1959), :]
        df3 = df[(df[!, :year] .>= 1996) .& (df[!, :year] .<= 2005), :]

        for var in [:wtem, :wpre]
            println("treating $var")

            df = transform(groupby(df, :parent), var => maximum => "$(var)max")
            transform!(groupby(df, :parent), var => minimum => "$(var)min")
            df2 = transform(groupby(df2, :parent), var => (x -> mean(x)) => "$(var)temp50s")
            transform!(groupby(df2, :parent), "$(var)temp50s" => (x -> mean(x)) => "$(var)50s")
            df3 = transform(groupby(df3, :parent), var => (x -> mean(x)) => "$(var)temp00s")
            transform!(groupby(df3, :parent), "$(var)temp00s" => (x -> mean(x)) => "$(var)00s")

        end

        select!(df2, ["year", "parent", "wtemtemp50s", "wtem50s", "wpretemp50s", "wpre50s"])
        select!(df3, ["year", "parent", "wtemtemp00s", "wtem00s", "wpretemp00s", "wpre00s"])
        println(size(df2), size(df3))
        temp_temps = outerjoin(df3, df2, on=[:year, :parent])
        sort!(temp_temps, [:parent, :year])
        
        merged_result = outerjoin(df, temp_temps, on=[:year, :parent])
        sort!(merged_result, [:parent, :year])

        transform!(groupby(merged_result, :parent), :wpretemp00s => mean∘skipmissing => :wpre00s)
        transform!(groupby(merged_result, :parent), :wpretemp50s => mean∘skipmissing => :wpre50s)
        transform!(groupby(merged_result, :parent), :wtemtemp00s => mean∘skipmissing => :wtem00s)
        transform!(groupby(merged_result, :parent), :wtemtemp50s => mean∘skipmissing => :wtem50s)

        println(merged_result[1:128, [:year, :parent, :wpre50s, :wtem50s, :wpre00s, :wtem00s]])
        return merged_result
    end

    function figure1()
        
        if splitdir(pwd())[2] != "assets"
            cd(joinpath(pwd(), "assets"))
        elseif splitdir(pwd())[2] == "assets"
            println("Already in the right dir, can now read the CSV file...")
        else
            println("Wrong path, aborting")
        end

        climate_panel_gdp = CSV.read(joinpath(pwd(), "climate_panel_csv.csv"), DataFrame)
        climate_panel = CSV.read(joinpath(pwd(), "climate_panel_csv.csv"), DataFrame)

        climate_panel_gdp = climate_panel_gdp[(climate_panel_gdp.year .== 2000), :]
        climate_panel_gdp[!, :lngdp2000] .= log.(climate_panel_gdp.rgdpl)
        select!(climate_panel_gdp, [:fips60_06, :parent, :lngdp2000])

        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        merged_climate_panel = outerjoin(climate_panel, climate_panel_gdp, on=:fips60_06, makeunique=true)
        sort!(merged_climate_panel, [:country_code, :year])

        transform!(groupby(merged_climate_panel, :fips60_06), :lngdpwdi => lag)
        merged_climate_panel[!, :g] .= ( merged_climate_panel.lngdpwdi .- merged_climate_panel.lngdpwdi_lag ) .* 100

        select!(merged_climate_panel, Not(:lngdpwdi_lag))

        merged_climate_panel[!, :nonmissing] .= ifelse.(ismissing.(merged_climate_panel.g), 0, 1)
        transform!(groupby(merged_climate_panel, :fips60_06), :nonmissing => sum∘skipmissing)
        merged_climate_panel = merged_climate_panel[(merged_climate_panel[!, :nonmissing_sum_skipmissing] .>= 20), :]
        
        select!(merged_climate_panel, Not(:nonmissing))
        select!(merged_climate_panel, Not(:nonmissing_sum_skipmissing))

        sort!(merged_climate_panel, :parent)

        merged_climate_panel = gen_vars_fig1!(merged_climate_panel)
        
        transform!(groupby(merged_climate_panel, :parent), eachindex => :countrows)
        merged_climate_panel = merged_climate_panel[(merged_climate_panel.countrows .== 1), :]
        println(merged_climate_panel[1:128, [:year, :parent, :wpre50s, :wtem50s, :wpre00s, :wtem00s]])

    end
    figure1()

end
