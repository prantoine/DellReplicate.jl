module DellReplicate

# Write your package code here.

    using CSV
    using DataFrames
    using ShiftedArrays: lag
    using Statistics
    using Impute
    using BenchmarkTools
    using Plots

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

        return merged_result
    end

    """
        read_csv(fn::String)

    Creates a `DataFrame` object from a `.csv` file, where `fn` is the file name. May only work if ran from a directory where `assets` if is in the same
    parent directory. 
    """
    function read_csv(fn::String)

        if splitdir(pwd())[2] != "assets" && splitdir(pwd())[2] != "docs"
            cd(joinpath(pwd(), "assets"))
        elseif splitdir(pwd())[2] == "docs"
            cd(joinpath(dirname(pwd()), "assets"))
        elseif splitdir(pwd())[2] == "assets"
            println("Already in the right dir, can now read the CSV file...")
        else
            println("Wrong path, aborting")
            return nothing
        end

        return CSV.read(joinpath(pwd(), fn), DataFrame)

    end

    """
        figure1_data_cleaner() 

    Loads the `climate_panel_csv` dataset and reproduces Dell's (2012) `makefigure1.do` commands. Returns a `DataFrame` object
    which can be used by ???
    """
    function figure1_data_cleaner(raw_df_name::String)

        climate_panel_gdp = read_csv(raw_df_name)
        climate_panel = read_csv(raw_df_name)

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

        return merged_climate_panel
    end

    """
        figure1_visualise(df::String)

    Plots `Figure 1` from Dell (2012) by calling the data cleaning function `figure1_data_cleaner` with the `climate_panel_csv.csv`
    dataset.
    """
    function figure1_visualise(df::String)
        
        
        clean_df = figure1_data_cleaner(df)

        test = [ collect(clean_df[row_ind, [:wtem00s, :wtem50s, :wtemmax, :wtemmin, :lngdp2000]]) for (row_ind, row) in enumerate(eachrow(clean_df))]

        # generate some random data for 3 observations
        
        mins = [ row[4] for row in test ]
        maxs = [ row[3] for row in test ]
        lngdp = [ row[5] for row in test ]
        println(lngdp)

        # create a scatter plot with vertical ranges
        p1 = plot()
        for i in 1:size(test)[1]
            plot!(lngdp, [mins[i], maxs[i]], color=:grey, linewidth=2, label="")
            println(i)
        end
        xlims!(5, 11) # set the x-axis limits
        ylims!(-10, 30) # set the y-axis limits
        xticks!(1:10) # set the ticks and labels for the x-axis
        ylabel!("Vertical Range") # set the label for the y-axis
        
        # annotate the country codes next to each range
        for i in 1:size(test)[1]
            x = i
            y = (mins[i] + maxs[i]) / 2
            #annotate!(data[i, 4], (x + 0.2, y), ha=:left, va=:center, color=:black, fontsize=8)
        end
display(p1)
    end

    figure1_visualise("climate_panel_csv.csv")

end
