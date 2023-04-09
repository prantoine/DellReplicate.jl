module DellReplicate

# Write your package code here.
    using DataFrames
    using CSV
    using ShiftedArrays: lag
    using Statistics

    function gen_vars_fig1!(df)

        df2 = df[(df[!, :year] .>= 1950) .& (df[!, :year] .<= 1959), :]
        df3 = df[(df[!, :year] .>= 1996) .& (df[!, :year] .<= 2006), :]

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
        test = outerjoin(df3, df2, on=[:year, :parent])
        sort!(test, [:parent, :year])
        println(test)

        #test = outerjoin(df, df2, on=[:year, :parent])
        return df
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
        #println(merged_climate_panel[70:100,:])

    end

    figure1()

end
