module DellReplicate

# Write your package code here.

    using CSV
    using DataFrames
    using ShiftedArrays: lag
    using Statistics
    using Impute
    using BenchmarkTools
    using Plots
    using Logging

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
            
            df = transform(groupby(df, :parent), var => maximum => "$(var)max")
            transform!(groupby(df, :parent), var => minimum => "$(var)min")
            df2 = transform(groupby(df2, :parent), var => (x -> mean(x)) => "$(var)temp50s")
            transform!(groupby(df2, :parent), "$(var)temp50s" => (x -> mean(x)) => "$(var)50s")
            df3 = transform(groupby(df3, :parent), var => (x -> mean(x)) => "$(var)temp00s")
            transform!(groupby(df3, :parent), "$(var)temp00s" => (x -> mean(x)) => "$(var)00s")

        end

        select!(df2, ["year", "parent", "wtemtemp50s", "wtem50s", "wpretemp50s", "wpre50s"])
        select!(df3, ["year", "parent", "wtemtemp00s", "wtem00s", "wpretemp00s", "wpre00s"])
        temp_temps = outerjoin(df3, df2, on=[:year, :parent])
        sort!(temp_temps, [:parent, :year])
        
        merged_result = outerjoin(df, temp_temps, on=[:year, :parent])
        sort!(merged_result, [:parent, :year])

        transform!(groupby(merged_result, :parent), :wpretemp00s => mean∘skipmissing => :wpre00s,
                                                    :wpretemp50s => mean∘skipmissing => :wpre50s,
                                                    :wtemtemp00s => mean∘skipmissing => :wtem00s,
                                                    :wtemtemp50s => mean∘skipmissing => :wtem50s)

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
            @warn "Changed the directory to find the data file."
        elseif splitdir(pwd())[2] == "docs"
            cd(joinpath(dirname(pwd()), "assets"))
            @warn "Changed the directory to find the data file."
        elseif splitdir(pwd())[2] == "assets"
            @info "Already in the right dir, can now read the CSV file."
        else
            @error "Wrong path, aborting."
            return nothing
        end

        return CSV.read(joinpath(pwd(), fn), DataFrame)

    end

    """
        figure1_data_cleaner() 

    Loads the `climate_panel_csv` dataset and reproduces Dell's (2012) `makefigure1.do` commands. Returns a `DataFrame` object
    which can be used by `figure1_visualise()`.
    """
    function figure1_data_cleaner(raw_df_name::String)

        climate_panel = read_csv(raw_df_name)
        climate_panel_gdp = read_csv(raw_df_name)
        filter!(:year => ==(2000), climate_panel_gdp)

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
    dataset. The figure is a combination of 128 line plots (one for each country) showing the temperature range and two scatter plots showing the mean temperature
    values for the periods 1950-1959 and 1996-2005.
    """
    function figure1_visualise(df_name::String)
        
        
        clean_df = figure1_data_cleaner(df_name)

        test = [ collect(clean_df[row_ind, [:wtem00s, :wtem50s, :wtemmax, :wtemmin, :lngdp2000, :country_code]]) for (row_ind, row) in enumerate(eachrow(clean_df))]

        # generate some random data for 3 observations
        
        avg_00 = [ row[1] for row in test ]
        avg_50 = [ row[2] for row in test ]
        maxs = [ row[3] for row in test ]
        mins = [ row[4] for row in test ]
        lngdp = [ row[5] for row in test ]
        country = [ row[6] for row in test ]

        # create a scatter plot with vertical ranges
        p1 = plot(size=(800,600),titlefont=font(18, :red, :left, :bold, 1.1))
        for i in 1:size(test)[1]
            if !ismissing(lngdp[i])
            plot!([lngdp[i],lngdp[i]],[mins[i], maxs[i]], color=:grey, linewidth=1.3, label="")
            end
        end
        scatter!(lngdp, avg_00, marker=:star5, color=:red, label="Mean 1996-2005")
        scatter!(lngdp, avg_50, marker=:cross, color=:blue, label="Mean 1950-1959")
        xlims!(minimum(skipmissing(lngdp))-0.5, maximum(skipmissing(lngdp))+0.5) 
        ylims!(-10, 30) 
        xticks!(1:10) 
        
        # annotate the country codes next to each range
        for i in eachindex(country)
            x = lngdp[i]
            y = (mins[i] + maxs[i]) / 2
            annotate!(x + 0.15, y, text(country[i], 5))
        end
        
        ylabel!("Degrees") 
        xlabel!("Log per-capita GDP in 2000")
        title!("Temperature", )
        display(p1)

    end

    function figure2_visualise(df_name::String)

        climate_panel = read_csv(df_name)
        filter!(:year => <=(2003), climate_panel)

        sort!(climate_panel, [:fips60_06, :year])
        
        # Direct broadcast is faster
        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        #println(benchlog_1[1:1,:], benchlog_2[1:1,:])
    
        climate_panel[!, :lngdppwt] .= log.(climate_panel.rgdpl)
        transform!(groupby(climate_panel, :fips60_06), :lngdpwdi => lag => :temp_lag_gdp_WDI,
                                                          :lngdppwt => lag => :temp_lag_gdp_PWT)

        climate_panel[!, :g] .= ( climate_panel.lngdpwdi .- climate_panel.temp_lag_gdp_WDI ) .* 100
        climate_panel[!, :gpwt] .= ( climate_panel.lngdppwt .- climate_panel.temp_lag_gdp_PWT ) .* 100
        select!(climate_panel, Not(:temp_lag_gdp_WDI))
        select!(climate_panel, Not(:temp_lag_gdp_PWT))

        climate_panel[!, :lnag] .= log.(climate_panel.gdpWDIGDPAGR)
        climate_panel[!, :lnind] .= log.(climate_panel.gdpWDIGDPIND)
        climate_panel[!, :lninvest] .= log.( ( climate_panel.rgdpl .* climate_panel.ki ) ./ 100)

       # growth Lags for lnag lnind lngdpwdi lninvest 
        transform!(groupby(climate_panel, :fips60_06), [ :lnag, :lnind, :lngdpwdi, :lninvest ] .=> lag)

        for var in [ :ag, :ind, :gdpwdi, :invest ]
            climate_panel[!, "g$(var)"] .= ( climate_panel[:,"ln$var"] .- climate_panel[:,"ln$(var)_lag"] ) .* 100
        end

        # Drop if less than 20 years of GDP values
        climate_panel[!, :nonmissing] .= ifelse.(ismissing.(climate_panel.g), 0, 1)
        transform!(groupby(climate_panel, :fips60_06), :nonmissing => sum∘skipmissing)
        climate_panel = climate_panel[(climate_panel[!, :nonmissing_sum_skipmissing] .>= 20), :]       

        # Create 3 copies to be merged
        temp1 = copy(climate_panel)
        filter!(:lnrgdpl_t0 => (x -> !ismissing.(x)), temp1)
        transform!(groupby(temp1, :fips60_06), eachindex => :countrows)
        filter!(:countrows => ==(1), temp1)
        temp1[!, :initgdpbin] .= log.(temp1.lnrgdpl_t0) / size(temp1)[1]
        # CAREFUL ABOUT THE SORTING
        sort!(temp1, :initgdpbin)
        temp1[!, :initgdpbin] .= ifelse.(temp1.initgdpbin .< temp1[Int(round(size(temp1)[1] / 2)), :initgdpbin], 1 ,2)
        select!(temp1, [:fips60_06, :initgdpbin])
        
        merged_1 = outerjoin(climate_panel, temp1, on=[:fips60_06]) 
        transform!(merged_1, :initgdpbin .=> (x -> ifelse.(skipmissing.(x) .== 1, 1, 0)) .=> :initgdpxtile1,
                             :initgdpbin .=> (x -> ifelse.(skipmissing.(x) .== 2, 1 ,0)) .=> :initgdpxtile2)
        #merged_1[!, :initgdpxtile2] .= ifelse.(skipmissing.(merged_1.initgdpbin) .!= 2, 0, 1) 
        #merged_1[!, :initgdpxtile2] .= ifelse.(skipmissing.(merged_1.initgdpbin) .== 2, 1, 0)
        println(merged_1[1:200, [:fips60_06, :initgdpbin, :lnag, :initgdpxtile1, :initgdpxtile2,:year]])

        temp2 = copy(climate_panel)

        temp3 = copy(climate_panel)



    end

    #figure2_visualise("climate_panel_csv.csv")

    """
        function make_table_1(raw_df_name::String)
    
    Create summary statistics of the Data.

    """
    function make_table1(raw_df_name::String)

        climate_panel = read_csv(raw_df_name)

        bench_filter = @btime filter!(:year => <=(2003), $climate_panel)
        bench_copy = @btime $climate_panel = $climate_panel[($climate_panel.year .<= 2003), :]
        println(bench_filter[1:1, :], bench_copy[1:1,:])

        test1 = @btime transform!($climate_panel, :rgdpl => (x -> log.(x)) => :lgdp1)
        test2 = @btime transform!($climate_panel, :rgdpl => ByRow(x -> log(x)) => :lgdp2)
        println(test1[1:1, :],test2[1:1, :])

        sort!(climate_panel, [:fips60_06, :year])
        println(climate_panel[1:200, [:fips60_06, :year, :lgdp1, :lgdp2]])

    end
    
    figure2_visualise("climate_panel_csv.csv")
end


