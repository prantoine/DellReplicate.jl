module DellReplicate

    using CSV
    using DataFrames
    using ShiftedArrays: lag
    using Statistics
    using Impute
    using BenchmarkTools
    using Plots
    using StatsPlots
    using Logging
    using PrettyTables
    using StatsModels
    using GLM
    using LinearAlgebra
    

    """
        gen_vars_fig1!(df::DataFrame)

    Generates the necessary mean temperature and pDegreeirecipitation variables for the two graphs of `Figure 1`, given the climate panel data.
    Returns the modified version of input `df`.
    """
    function gen_vars_fig1!(df)

        
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

    function figure1_visualise_graph2(df_name::String)
        
        df_ready_for_fig = figure1_data_cleaner(df_name)
        println(names(df_ready_for_fig))
        p1 = @df df_ready_for_fig plot(size=(800,600),titlefont=font(18, :red, :left, :bold, 1.1))
        sub_df_array = [ collect(df_ready_for_fig[row_ind, [:wpremin, :wpremax, :lngdp2000, :country_code]]) for (row_ind, row) in enumerate(eachrow(df_ready_for_fig))]
        
        mins = [ row[1] for row in sub_df_array ]
        maxs = [row[2] for row in sub_df_array ]
        lngdp2000 = [ row[3] for row in sub_df_array ]
        countries = [ row[4] for row in sub_df_array ]

        for i in 1:size(sub_df_array)[1]
            if !ismissing(lngdp2000[i])
            plot!(p1, [lngdp2000[i], lngdp2000[i]], [mins[i], maxs[i]], color=:grey, linewidth=1.3, label="")
            end
        end

        @df df_ready_for_fig scatter!(p1, :lngdp2000, :wpre00s, marker=:star5, color=:red, label="Mean 1996-2005")
        @df df_ready_for_fig scatter!(p1, :lngdp2000, :wpre50s, marker=:cross, color=:blue, label="Mean 1950-1959")
        @df df_ready_for_fig xlims!(minimum(skipmissing(:lngdp2000))-0.5, maximum(skipmissing(:lngdp2000))+0.5) 
        ylims!(-10, 60) 
        xticks!(1:10) 

        for i in eachindex(countries)
            x = lngdp2000[i]
            y = (mins[i] + maxs[i]) / 2
            annotate!(x + 0.15, y, text(countries[i], 5))
        end

        ylabel!("100s mm/year") 
        xlabel!("Log per-capita GDP in 2000")
        title!("Precipitation\nWeighted by population", )

        display(p1)
    end

    """
        figure1_visualise_graph1(df::String)

    Plots `Figure 1` from Dell (2012) by calling the data cleaning function `figure1_data_cleaner` with the `climate_panel_csv.csv`
    dataset. The figure is a combination of 128 line plots (one for each country) showing the temperature range and two scatter plots showing the mean temperature
    values for the periods 1950-1959 and 1996-2005.
    """
    function figure1_visualise_graph1(df_name::String)
        
        
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
        title!("Temperature\nWeighted by population", )
        #display(p1)
        figure1_visualise_graph2(df_name)

    end

    """
        growth_var!(df::DataFrames.DataFrame, g_var_name::Symbol, var_name::Symbol)
    Adds a new column to `df` with the name `g_var_name` computing the growth of `var_name`.
    """
    function growth_var!(df::DataFrame, var_name::Symbol)

        temp_var = ":$(var_name)_temp"
        g_var = "g_$(var_name)"
        transform!(groupby(df, :fips60_06), var_name => lag => temp_var)
        df[!, g_var] .= ( df[:, var_name] .- df[:, temp_var] ) .* 100
        select!(df, Not(temp_var))
    
    end

    function keep_20yrs_gdp(df::DataFrames.DataFrame)
        
        df[!, :nonmissing] .= ifelse.(ismissing.(df.g_lngdpwdi), 0, 1)
        transform!(groupby(df, :fips60_06), :nonmissing => sum∘skipmissing)
        filter!(:nonmissing_sum_skipmissing => >=(20), df)
        return df

    end

    """
        filter_transform!(df::DataFrames.DataFrame, pred, args)
    Transforms the data on a filtered subset using a predicate function (a function that returns true or false).
    """
    function filter_transform!(df::DataFrames.DataFrame, pred, args)
        fdf = filter(pred, df, view = true)
        fdf .= transform(copy(fdf), args)
    end

    """
        gen_lag_vars(df::DataFrames.DataFrame)
    Generates all the variables necessary for figure 2 and others.
    """
    function gen_lag_vars(df::DataFrames.DataFrame)
        
        lag_df = df[:, [:year, :fips60_06, :wtem, :wpre, :wtem50, :wpre50]]

        for var in [ "wtem", "wpre" ]
            lag_df[!, "$(var)Xlnrgdpl_t0"] .= df[:, var] .* df[:, :lnrgdpl_t0]

            for bin_var in [ "initxtileagshare1", "initxtileagshare2", "initxtilegdp1", "initxtilegdp2", "initxtilewtem1", "initxtilewtem2"]
                lag_df[!, "$(var)_$(bin_var)"] .= df[:, var] .* df[:, bin_var]
            end

        end
        
        vars_to_lag = [ var for var in names(lag_df) if var[1:4] in [ "wtem", "wpre" ]]

        for var in vars_to_lag
            transform!(groupby(lag_df, :fips60_06), var => lag => "L1$(var)") 
            lag_df[!, Symbol(:fd,var)] .= lag_df[:, var] .- lag_df[:, "L1$(var)"]
            for n_lag in 2:10
                transform!(groupby(lag_df, :fips60_06), "L$(n_lag-1)$(var)" => lag => "L$(n_lag)$(var)")
            end
        end
        #we should be at line 137 in the do file here !

        return outerjoin(df, lag_df, on=[:fips60_06, :year], makeunique=true)

    end

    function gen_year_vars(df::DataFrames.DataFrame)
        
        numyears = maximum([ size(subfd)[1] for subfd in groupby(df, :fips60_06)] ) - 1
        unique_years = [year for year in range(1,numyears+1)]
        
        region_vars = ["_MENA", "_SSAF", "_LAC", "_WEOFF", "_EECA", "_SEAS"]
        temp_df = df[:, [Symbol(col) for col in names(df) if (col in region_vars) | (col in ["initxtilegdp1", "year", "fips60_06"]) | (col[1:2] == "yr")]]

        #dummies: 1 for each year
        transform!(groupby(temp_df, [:fips60_06, :year]), @. :year => ByRow(isequal(1949+unique_years)) .=> Symbol(:yr_, unique_years))

        for year in unique_years
            if year != 54
                for region in region_vars
                    temp_df[!, Symbol(:RY, year, "X", region)] .= temp_df[:, Symbol(:yr_,year)] .* temp_df[:, region]
                end
                temp_df[!, Symbol(:RY, "PX", year)] .= temp_df[:, Symbol(:yr_,year)] .* temp_df.initxtilegdp1
            end
        end
        

        return outerjoin(df, temp_df, on=[:fips60_06, :year], makeunique=true)

    end

    function gen_xtile_vars(climate_panel::DataFrames.DataFrame)

        temp1 = copy(climate_panel)
        filter!(:lnrgdpl_t0 => (x -> !ismissing.(x)), temp1)
        transform!(groupby(temp1, :fips60_06), eachindex => :countrows)
        filter!(:countrows => ==(1), temp1)
        temp1[!, :initgdpbin] .= log.(temp1.lnrgdpl_t0) / size(temp1)[1]
        # CAREFUL ABOUT THE SORTING
        sort!(temp1, :initgdpbin)
        temp1[!, :initgdpbin] .= ifelse.(temp1.initgdpbin .<= temp1[Int(round(size(temp1)[1] / 2)), :initgdpbin], 1 ,2)
        select!(temp1, [:fips60_06, :initgdpbin])
        merged_1 = outerjoin(climate_panel, temp1, on=[:fips60_06]) 
        merged_1[:, :initgdpbin] .= ifelse.(ismissing.(merged_1.initgdpbin), 999, merged_1.initgdpbin)
        merged_1[!, :initxtilegdp1] .= ifelse.(merged_1.initgdpbin .== 1, 1, ifelse.(merged_1.initgdpbin .== 2, 0, missing))
        merged_1[!, :initxtilegdp2] .= ifelse.(merged_1.initgdpbin .== 2, 1, ifelse.(merged_1.initgdpbin .== 1, 0, missing))
        climate_panel = merged_1

        temp2 = copy(climate_panel)
        filter!(:wtem50 => (x -> !ismissing.(x)), temp2)
        transform!(groupby(temp2, :fips60_06), eachindex => :countrows)
        filter!(:countrows => ==(1), temp2)
        temp2[!, :initwtem50bin] .= temp2.wtem50 / size(temp2)[1]
        sort!(temp2, :initwtem50bin)
        temp2[!, :initwtem50bin] .= ifelse.(temp2.initwtem50bin .<= temp2[Int(round(size(temp2)[1] / 2)), :initwtem50bin], 1, 2)
        select!(temp2, [:fips60_06, :initwtem50bin])
        merged_2 = outerjoin(climate_panel, temp2, on=[:fips60_06])
        merged_2[:, :initwtem50bin] .= ifelse.(ismissing.(merged_2.initwtem50bin), 999, merged_2.initwtem50bin)
        merged_2[!, :initxtilewtem1] .= ifelse.(merged_2.initwtem50bin .== 1, 1, ifelse.(merged_2.initwtem50bin .== 2, 0, missing))
        merged_2[!, :initxtilewtem2] .= ifelse.(merged_2.initwtem50bin .== 2, 1, ifelse.(merged_2.initwtem50bin .== 1, 0, missing))
        climate_panel = merged_2

        temp3 = copy(climate_panel)
        filter!(:year => ==(1995), temp3)
        sort!(temp3, [:fips60_06, :year])
        temp3[!, :initagshare1995] .= log.(temp3.gdpSHAREAG) / size(temp3)[1]
        non_missings_t3 = size(temp3)[1] - count(ismissing.(temp3.initagshare1995))
        sort!(temp3, :initagshare1995)
        temp3[!, :initagshare1995] .= ifelse.(ismissing.(temp3.initagshare1995), 999, temp3.initagshare1995)
        temp3[:, :initagshare1995] .= ifelse.((temp3.initagshare1995 .<= temp3[Int(round(non_missings_t3/2)), :initagshare1995]), 1 ,2)
        temp3[:, :initagshare1995] .= ifelse.(ismissing.(temp3.gdpSHAREAG), 999, temp3.initagshare1995)
        select!(temp3, [:fips60_06, :initagshare1995])
        merged_3 = outerjoin(climate_panel, temp3, on=[:fips60_06])
        merged_3[:, :initagshare1995] .= ifelse.(ismissing.(merged_3.initagshare1995), 999, merged_3.initagshare1995)
        merged_3[!, :initxtileagshare1] .= ifelse.(merged_3.initagshare1995 .== 1, 1, ifelse.(merged_3.initagshare1995 .== 2, 0, missing))
        merged_3[!, :initxtileagshare2] .= ifelse.(merged_3.initagshare1995 .== 2, 1, ifelse.(merged_3.initagshare1995 .== 1, 0, missing))
         
        return merged_3
    end

    function figure2_visualise(df_name::String)

        climate_panel = read_csv(df_name)
        filter!(:year => <=(2003), climate_panel)

        sort!(climate_panel, [:fips60_06, :year])
        
        # Direct broadcast is faster
        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        climate_panel[!, :lngdppwt] .= log.(climate_panel.rgdpl)
        growth_var!(climate_panel, :lngdpwdi)
        growth_var!(climate_panel, :lngdppwt)

        climate_panel[!, :lnag] .= log.(climate_panel.gdpWDIGDPAGR)
        climate_panel[!, :lnind] .= log.(climate_panel.gdpWDIGDPIND)
        climate_panel[!, :lninvest] .= log.( ( climate_panel.rgdpl .* climate_panel.ki ) ./ 100)

       # growth Lags for lnag lnind lngdpwdi lninvest 
        transform!(groupby(climate_panel, :fips60_06), [ :lnag, :lnind, :lngdpwdi, :lninvest ] .=> lag)

        for var in [ :ag, :ind, :gdpwdi, :invest ]
            climate_panel[!, "g$(var)"] .= ( climate_panel[:,"ln$var"] .- climate_panel[:,"ln$(var)_lag"] ) .* 100
        end

        # Drop if less than 20 years of GDP values
        climate_panel = keep_20yrs_gdp(climate_panel)
        #climate_panel = climate_panel[(climate_panel[!, :nonmissing_sum_skipmissing] .>= 20), :]       
        climate_panel = gen_xtile_vars(climate_panel)
        climate_panel = gen_lag_vars(climate_panel)
        climate_panel = gen_year_vars(climate_panel)
        
        #a few duplicates are created here.

        #CODES: 999 IF MISSING BIN

    end

    #figure2_visualise("climate_panel_csv.csv")

    """
        make_table_1(raw_df_name::String)
    
    Create summary statistics of the Data.

    """
    function make_table1(raw_df_name::String)

        climate_panel = read_csv(raw_df_name)

        filter!(:year => <=(2003), climate_panel)

        

        sort!(climate_panel, [:fips60_06, :year])

        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        climate_panel[!, :lngdppwt] .= log.(climate_panel.rgdpl)
        transform!(groupby(climate_panel, :fips60_06), :lngdpwdi => lag => :temp_lag_gdp_WDI,
                                                          :lngdppwt => lag => :temp_lag_gdp_PWT)

        climate_panel[!, :gg] .= ( climate_panel.lngdpwdi .- climate_panel.temp_lag_gdp_WDI ) .* 100
        climate_panel[!, :gpwt] .= ( climate_panel.lngdppwt .- climate_panel.temp_lag_gdp_PWT ) .* 100
        select!(climate_panel, Not(:temp_lag_gdp_WDI))
        select!(climate_panel , Not(:temp_lag_gdp_PWT))

        climate_panel[!, :lnag] .= log.(climate_panel.gdpWDIGDPAGR)
        climate_panel[!, :lnind] .= log.(climate_panel.gdpWDIGDPIND)
        climate_panel[!, :lninvest] .= log.( ( climate_panel.rgdpl .* climate_panel.ki ) ./ 100)
        # Compute the growth rate for each value 
        for var in [:lnag, :lnind, :lngdpwdi, :lninvest]
            growth_var!(climate_panel, var)        
        end

        # Drop if less than 20 years of GDP values
        climate_panel[!, :nonmissing] .= ifelse.(ismissing.(climate_panel.gg), 0, 1)
        transform!(groupby(climate_panel, :fips60_06), :nonmissing => sum∘skipmissing)
        filter!(:nonmissing_sum_skipmissing => >=(20), climate_panel)

        #Make sure all subcomponents are non-missing in a given year
        climate_panel[!, :misdum] .= 0
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,var => ismissing, :misdum => (b -> (b=1)) => :misdum)
        end
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,:misdum => ==(1), var => (b -> (b=missing)) => var)
        end
        
        # temp1 = copy(climate_panel)
        # temp1 = dropmissing(temp1, :lnrgdpl_t0)
        # sort!(temp1, :fips60_06)
        # temp1 = combine(first, groupby(temp1, :fips60_06))
        # temp1[!, :initgdpbin] .= log.(temp1.lnrgdpl_t0) / size(temp1)[1]
        # #CAREFUL ABOUT THE SORTING
        # sort!(temp1, :initgdpbin)
        # temp1[!, :initgdpbin] .= ifelse.(temp1.initgdpbin .< temp1[Int(round(size(temp1)[1] / 2)), :initgdpbin], 1 ,2)
        # select!(temp1, [:fips60_06, :initgdpbin])
        # println(temp1[!,[:fips60_06, :initgdpbin]])
        climate_panel = gen_xtile_vars(climate_panel)
        
        for var in ["wtem", "wpre"]
            climate_panel[!, "$(var)Xlnrgdpl_t0"] .= climate_panel[!, var] .* climate_panel[!, "lnrgdpl_t0"]
            for name in ["initxtilegdp1", "initxtilegdp2", "initxtilewtem1", "initxtilewtem2", "initxtileagshare1", "initxtileagshare2"]
                climate_panel[!, "$(var)_$name"] .= climate_panel[!, var] .* climate_panel[!, name]
            end
        end
        
        climate_panel = gen_year_vars(climate_panel)
        for var in [:wtem,:wpre]
            transform!(groupby(climate_panel, :fips60_06), var => mean => Symbol(var, "countrymean"))
            climate_panel[!,Symbol(var, "_withoutcountrymean")] .= climate_panel[!,var] .- climate_panel[!,Symbol(var, "countrymean")]
            transform!(groupby(climate_panel, :year), Symbol(var, "_withoutcountrymean") => mean => Symbol(var, "temp", "_yr") )
            climate_panel[!,Symbol(var, "_withoutcountryyr")] .= climate_panel[!,Symbol(var, "_withoutcountrymean")] .- climate_panel[!,Symbol(var, "temp", "_yr")]
        end
        
        #println(count(x -> isequal(x,true), climate_panel[!,:wtem] .> climate_panel[!, :wtemcountrymean])/size(climate_panel[!,:wtem])[1])
        function neighborhood(t, x)
            if abs(x) >= t 
                return true
            else
                return false
            end
        end
        Res = []
        # for var in [:wtem, :wpre]
        #     for t in [0.25, 0.5, 0.75, 1, 1.25, 1.5]
        #         println("The percentage of $var $t below/above countrymean is $(count(x -> neighborhood(t,x), climate_panel[!,Symbol(var, "_withoutcountrymean")])/size(climate_panel[!,var])[1])")
        #         println("The percentage of $var $t below/above countrymean without year fixed effect is $(count(x -> neighborhood(t,x), climate_panel[!,Symbol(var, "_withoutcountryyr")])/size(climate_panel[!,var])[1])")
        #     end
        # end
        
        a = Float64[]
        b = Float64[]
        for t in [0.25, 0.5, 0.75, 1, 1.25, 1.5]
            
                push!(a,round(count(x -> neighborhood(t,x), climate_panel[!,:wtem_withoutcountrymean])/size(climate_panel[!,:wtem])[1], digits = 3))
                push!(b,round(count(x -> neighborhood(t,x), climate_panel[!,:wtem_withoutcountryyr])/size(climate_panel[!,:wtem])[1], digits = 3))
        end
        # println(a, b)
        table1 = DataFrame(Statistic= ["Raw Data","Without year FE"], Quarter = [a[1], b[1]], Half = [a[2], b[2]], ThreeQuarter = [a[3], b[3]], One = [a[4], b[4]], One_and_quarter = [a[5],b[5]], One_and_half=[a[6], b[6]])
        pretty_table(table1)

        c = Float64[]
        d = Float64[]
        for t in [1, 2, 3, 4, 5, 6]
            
                push!(c, round(count(x -> neighborhood(t,x), climate_panel[!,:wpre_withoutcountrymean])/size(climate_panel[!,:wpre])[1], digits = 3))
                push!(d, round(count(x -> neighborhood(t,x), climate_panel[!,:wpre_withoutcountryyr])/size(climate_panel[!,:wpre])[1], digits = 3))
        end
        #println(c, d)
        table2 = DataFrame(Statistic= ["Raw Data","Without year FE"], One = [c[1], d[1]], Two = [c[2], d[2]], Three = [c[3], d[3]], Four = [c[4], d[4]], Five = [c[5],d[5]], Six=[c[6], d[6]])
        pretty_table(table2)
    end

    function make_table2(raw_df_name::String)
        climate_panel = read_csv(raw_df_name)

        filter!(:year => <=(2003), climate_panel)

        transform!(climate_panel, :rgdpl => (x -> log.(x)) => :lgdp)
        sort!(climate_panel, [:fips60_06, :year])

        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        climate_panel[!, :lngdppwt] .= log.(climate_panel.rgdpl)
        growth_var!(climate_panel, :lngdpwdi)

        climate_panel[!, :lnag] .= log.(climate_panel.gdpWDIGDPAGR)
        climate_panel[!, :lnind] .= log.(climate_panel.gdpWDIGDPIND)
        climate_panel[!, :lninvest] .= log.( ( climate_panel.rgdpl .* climate_panel.ki ) ./ 100)

        #Compute the growth rate for each value 
        for var in [:lnag, :lnind, :lngdpwdi, :lninvest]
            growth_var!(climate_panel, var)        
        end
        
        climate_panel = keep_20yrs_gdp(climate_panel)

        #Make sure all subcomponents are non-missing in a given year
        climate_panel[!, :misdum] .= 0
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,var => ismissing, :misdum => (b -> (b=1)) => :misdum)
        end
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,:misdum => ==(1), var => (b -> (b=missing)) => var)
        end

        climate_panel = gen_xtile_vars(climate_panel)
        climate_panel = gen_lag_vars(climate_panel)
        climate_panel = gen_year_vars(climate_panel)

        climate_panel[!, :region] .= ""
        for var in ["_MENA", "_SSAF", "_LAC", "_WEOFF", "_EECA", "_SEAS" ]
            filter_transform!(climate_panel, Symbol(var) => ==(1), :region => (b -> (b = var)) => :region )
        end
        
        climate_panel[!, :regionyear] .= climate_panel.region .* string.(climate_panel.year)

        #dummies: 1 for each country
        countries = unique(climate_panel[:, :fips60_06])
        transform!(groupby(climate_panel, [:fips60_06, :year]), @. :fips60_06 => ByRow(isequal(countries)) .=> Symbol(:cntry_, countries)) 

        #climate_panel_b4reg is the state of the data in stata right before running the first regression
        climate_panel2 = read_csv("climate_panel_b4reg.csv")
        transform!(groupby(climate_panel2, [:fips60_06, :year]), @. :fips60_06 => ByRow(isequal(countries)) .=> Symbol(:cntry_, countries))

        #first column
        col1 = check_coeffs_table2(climate_panel, climate_panel2, other_regressors= [])

        #second column
        col2 = check_coeffs_table2(climate_panel, climate_panel2, other_regressors = ["wtem_initxtilegdp1"])

        #third column
        col3 = check_coeffs_table2(climate_panel, climate_panel2, other_regressors = ["wtem_initxtilegdp1", "wpre", "wpre_initxtilegdp1"])

        #fourth column
        col4 = check_coeffs_table2(climate_panel, climate_panel2, other_regressors = ["wtem_initxtilegdp1", "wpre", "wpre_initxtilegdp1", "wtem_initxtilewtem2", "wpre_initxtilewtem2"])

        #fifth column (to drop: country BF)
        col5 = check_coeffs_table2(climate_panel, climate_panel2, other_regressors = ["wtem_initxtilegdp1", "wpre", "wpre_initxtilegdp1", "wtem_initxtileagshare2", "wpre_initxtileagshare2"])
        println("Coeff for wpre is $(col5["julia"]["wtem_initxtilegdp1"]) for julia and $(col5["stata"]["wtem_initxtilegdp1"]) for stata")
    end


    """
        qr_method(X::Matrix; columns::Dict)
    Returns a new matrix of regressors free of collinearity issues (i.e. full rank matrix) using the QR method as described by Engler (1997).
    Also returns a dictionnary with the name of the regressor as a key and its new position in the regressors matrix as a value.
    """
    function qr_method(X::Matrix; columns::Dict)

        x_pivot = qr(X, ColumnNorm())
        
        #info on the reordering of the columns: x_pivot.p (vector !)
        columns_to_keep = x_pivot.p[1: rank(X)]
        noncoli_regs = X[:, columns_to_keep]

        #iterate over a dict which maps each old position to the new one
        # the new_correspondance takes a regressor name as a key, and returns its new position in the non-collinear regressors Matrix as a value.
        new_correspondance = Dict(columns[old_pos] => new_pos for (old_pos,new_pos) in Dict(value => index for (index,value) in enumerate(columns_to_keep)))
        #println(columns_to_keep)

        return noncoli_regs, new_correspondance

    end

    """
        check_coeffs_table2(df_julia::DataFrames.DataFrame, df_stata::DataFrames.DataFrame; other_regressors)
    Given a `DataFrame` and the base specification of `Table 2`, this function prints the OLS coefficients for the reported regressors.
    """
    function check_coeffs_table2(df_julia::DataFrames.DataFrame, df_stata::DataFrames.DataFrame; other_regressors)

        RY_vars = names(df_julia[:, r"RY"])
        CNTRY_vars = names(df_julia[:, r"cntry_"])
        all_varsJ = select(df_julia, vcat(["wtem", "g_lngdpwdi"],RY_vars, CNTRY_vars, other_regressors))
        dropmissing!(all_varsJ)
        all_varsJ[!, :const] .= 1

        #assign each regressor column to a name
        col_corr = Dict(index => value for (index, value) in enumerate([var for var in names(all_varsJ) if var != "g_lngdpwdi"]))

        #create a matrix of regressors
        x_colli = Matrix(select(all_varsJ, vcat([var for var in names(all_varsJ) if var != "g_lngdpwdi"])))
        XJ, find_regressor_pos = qr_method(x_colli, columns = col_corr)
        YJ = Vector(all_varsJ.g_lngdpwdi) 

        #element 1 of coeffsJ corresponds to column 1 of regressors matrix. therefore we can access a specific coeff like so, for wtem: coeffsJ[find_regressor_pos["wtem]]
        coeffsJ = inv(XJ'*XJ)*XJ'*YJ
        #not entirely sure this works.
        coeffs_dictJ = Dict( value => coeffsJ[find_regressor_pos[value]] for value in keys(find_regressor_pos) )

        all_varsS = select(df_stata, vcat(["wtem", "g"], RY_vars, CNTRY_vars, other_regressors))
        dropmissing!(all_varsS)
        all_varsS[!, :const] .= 1

        col_corrS = Dict(index => value for (index, value) in enumerate([var for var in names(all_varsS) if var != "g"]))

        xs_colli = Matrix(select(all_varsS, vcat([var for var in names(all_varsS) if var != "g"])))
        XS, find_regressor_posS = qr_method(xs_colli, columns = col_corrS)
        YS = Vector(all_varsS.g)

        coeffsS = inv(XS'*XS)*XS'*YS
        coeffs_dictS = Dict( value => coeffsS[find_regressor_posS[value]] for value in keys(find_regressor_posS) )

        for (dataset, info) in Dict("Julia" => ["climate_panel_csv.csv", coeffs_dictJ],
                                        "Stata" => ["climate_panel_b4reg.csv", coeffs_dictS])
            for var in ["wtem", "const", "RY13X_SEAS"]
                println("DATASET: $dataset (full name: $(info[1])) => The OLS for var $var is $(info[2]["$var"])")
            end
        end
        println("\n")
        return Dict("julia" => coeffs_dictJ, "stata" => coeffs_dictS)

    end

        #figure2_visualise("climate_panel_csv.csv")                     
        #figure1_visualise_graph1("climate_panel_csv.csv")
        make_table2("climate_panel_csv.csv")

end


