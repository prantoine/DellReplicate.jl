module DellReplicate

    using CSV
    using DataFrames
    using ShiftedArrays: lag
    using Statistics
    using Impute
    using BenchmarkTools
    using Plots
    using Logging
    using GLM
    using CovarianceMatrices
    using LinearAlgebra
    

    """
        gen_vars_fig1!(df::DataFrame)

    Generates the necessary mean temperature and precipiation variables for the two graphs of `Figure 1`, given the climate panel data.
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

        result = CSV.read(joinpath(pwd(), fn), DataFrame)

        
        cd("..")
        return result

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
        gen_lag_vars(df::DataFrames.DataFrame)
    Generates all the variables necessary for figure 2 and others.
    """
    function gen_lag_vars(df::DataFrames.DataFrame)
        
        lag_df = df[:, [:year, :fips60_06, :wtem, :wpre, :wtem50, :wpre50]]

        for var in [ "wtem", "wpre" ]
            lag_df[!, "$(var)Xlnrgdpl_t0"] .= df[:, var] .* df[:, :lnrgdpl_t0]

            for bin_var in [ "initagshare95xtile1", "initagshare95xtile2", "initgdpxtile1", "initgdpxtile2", "initwtem50xtile1", "initwtem50xtile2"]
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
        temp_df = df[:, [Symbol(col) for col in names(df) if (col in region_vars) | (col in ["initgdpxtile1", "year", "fips60_06"]) | (col[1:2] == "yr")]]

        #dummies: 1 for each year
        transform!(groupby(temp_df, [:fips60_06, :year]), @. :year => ByRow(isequal(1949+unique_years)) .=> Symbol(:yr_, unique_years))
        
        for year in unique_years
            if year != 54
                for region in region_vars
                    temp_df[!, Symbol(:RY, year, "X", region)] .= temp_df[:, Symbol(:yr_,year)] .* temp_df[:, region]
                end
                temp_df[!, Symbol(:RY, "PX", year)] .= temp_df[:, Symbol(:yr_,year)] .* temp_df.initgdpxtile1
            end
        end

        println(temp_df[(temp_df[!, :fips60_06] .== "KS"), [:fips60_06, :year, :RYPX1, :RYPX7]])
        println(size(temp_df))
        return outerjoin(df, temp_df, on=[:fips60_06, :year], makeunique=true)

    end

    function HCE(df::DataFrame, y::String, x::String)
        # Extract the response vector y and the covariate(s) x from the dataframe
        Y_ = df[:, Symbol(y)]
        X_ = df[:, Symbol.(x)]
        formula = Term(Symbol(y)) ~ ConstantTerm(1) + Term(Symbol(x))

        # Create the design matrix X by concatenating a column of ones with the covariate(s)
        X = hcat(ones(length(Y_)), X_)
        # Fit the linear regression model
        
        ols1 = lm(formula, df)

        # Compute the predicted values
        y_hat = X * coef(ols1)

        # Compute the residuals
        residuals = vec(Y_ .- y_hat)

        # Compute the hat matrix (X * (X'X)^(-1)X')
        hat_matrix = X * inv(X' * X) * X'

        # Compute the squared residuals weighted by the hat matrix
        squared_residuals = residuals.^ 2
        weighted_residuals = squared_residuals ./ (1 .- diag(hat_matrix))

        # Compute the variance-covariance matrix of the coefficients
        robust_se = inv(X' * X) * X' * Diagonal(weighted_residuals) * X * inv(X' * X)

        # Extract the standard errors for the coefficients
        coefficient_se = sqrt.(diag(robust_se))
        
        # Return the standard errors of the fitted values
        #Here is the error
        se_fit = sqrt.(diag(X *robust_se* X'))

        return coefficient_se, y_hat, se_fit
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
        merged_1[!, :initgdpxtile1] .= ifelse.(merged_1.initgdpbin .== 1, 1, ifelse.(merged_1.initgdpbin .== 2, 0, missing))
        merged_1[!, :initgdpxtile2] .= ifelse.(merged_1.initgdpbin .== 2, 1, ifelse.(merged_1.initgdpbin .== 1, 0, missing))
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
        merged_2[!, :initwtem50xtile1] .= ifelse.(merged_2.initwtem50bin .== 1, 1, ifelse.(merged_2.initwtem50bin .== 2, 0, missing))
        merged_2[!, :initwtem50xtile2] .= ifelse.(merged_2.initwtem50bin .== 2, 1, ifelse.(merged_2.initwtem50bin .== 1, 0, missing))
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
        merged_3[!, :initagshare95xtile1] .= ifelse.(merged_3.initagshare1995 .== 1, 1, ifelse.(merged_3.initagshare1995 .== 2, 0, missing))
        merged_3[!, :initagshare95xtile2] .= ifelse.(merged_3.initagshare1995 .== 2, 1, ifelse.(merged_3.initagshare1995 .== 1, 0, missing))
         
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

        for var in [ :lnag, :lnind, :lngdpwdi, :lninvest ]
            #climate_panel[!, "g_$(var)"] .= ( climate_panel[:,"ln$var"] .- climate_panel[:,"ln$(var)_lag"] ) .* 100
            growth_var!(climate_panel, var)
        end

        # Drop if less than 20 years of GDP values
        climate_panel = keep_20yrs_gdp(climate_panel)
        climate_panel = gen_xtile_vars(climate_panel)
        climate_panel = gen_lag_vars(climate_panel)
        climate_panel = gen_year_vars(climate_panel)
        #a few duplicates are created here.

        #CODES: 999 IF MISSING BIN
        #gen mean temps reminder g = g_lngdpwdi
        
        temp_df = Dict()

        for (period, year) in Dict("50s" => [1951, 1960],
                             "60s" => [1961, 1970],
                             "70s" => [1971, 1980],
                             "80s" => [1981, 1990],
                             "90s" => [1991, 2000],
                             "00s" => [1994, 2003],
                             "84s" => [1984, 1993],
                             "64s" => [1964, 1973],
                             "7085" => [1970, 1985],
                             "8600" => [1986, 2000],
                             "7086" => [1970, 1986],
                             "8703" => [1987, 2003],
                             "7087" => [1970, 1987],
                             "8803" => [1988, 2003]
                            )

        temp_df[period] =   combine(groupby(subset(select(climate_panel, ["year", "fips60_06", "wtem", "wpre", "g_lngdpwdi", "g_lngdppwt", "g_lnag", "g_lnind", "g_lninvest"]), :year => ByRow(>=(year[1])), :year => ByRow(<=(year[2]))), :fips60_06),
                            [name for name in names(groupby(subset(select(climate_panel, ["year", "fips60_06", "wtem", "wpre", "g_lngdpwdi", "g_lngdppwt", "g_lnag", "g_lnind", "g_lninvest"]), :year => ByRow(>=(year[1])), :year => ByRow(<=(year[2]))), :fips60_06))
                            if name ∉ ["year", "fips60_06"]] .=> mean∘skipmissing .=> Symbol.(:temp, period,
                            [name for name in names(groupby(subset(select(climate_panel, ["year", "fips60_06", "wtem", "wpre", "g_lngdpwdi", "g_lngdppwt", "g_lnag", "g_lnind", "g_lninvest"]), :year => ByRow(>=(year[1])), :year => ByRow(<=(year[2]))), :fips60_06))
                            if name ∉ ["year", "fips60_06"]])) 

        # In the dofile, the second `mean` command is simply used to fill all missing values with the just-computed value.
        # Here we will perform a many to many merge, so values will naturally expand. Therefore we do not need to do anything else.
        
        end

        for (k,v) in temp_df
            climate_panel = outerjoin(climate_panel, v, on = :fips60_06)
        end
        
        #Non working version, although it looks cooler
        #@. climate_panel = outerjoin.(climate_panel, values(temp_df), on = :fips60_06)

            
            for var in ["wtem", "wpre", "g_lngdpwdi", "g_lngdppwt", "g_lnag", "g_lnind", "g_lninvest"]
            for (period, year) in Dict("00" => ["50s", "60s", "64s", "70s", "80s", "90s"],
                                    "90" => ["50s", "60s", "70s", "80s"],
                                    "84" => ["50s", "60s", "70s", "80s", "90s"]
                                    ) 

                for y in year
                    climate_panel[!, Symbol(:change, period , y, var)] .= climate_panel[:, Symbol(:temp, y, var)] .- climate_panel[:, Symbol(:temp, period, "s", var)]
                end

            end

            #for var wtem wpre g gpwt gag gind ginvest : g changeS1X = mean8600X - mean7085X 
             #   for var wtem wpre g gpwt gag gind ginvest : g changeS2X = mean8703X - mean7086X 	
              #  for var wtem wpre g gpwt gag gind ginvest : g changeS3X = mean8803X - mean7087X 
              climate_panel[!, Symbol(:changeS1, var)] .= climate_panel[:, Symbol(:temp8600, var)] .- climate_panel[:, Symbol(:temp7085, var)]
              climate_panel[!, Symbol(:changeS2, var)] .= climate_panel[:, Symbol(:temp8703, var)] .- climate_panel[:, Symbol(:temp7086, var)]
              climate_panel[!, Symbol(:changeS3, var)] .= climate_panel[:, Symbol(:temp8803, var)] .- climate_panel[:, Symbol(:temp7087, var)]

            end

            for var in [ name for name in names(climate_panel) if occursin("change", name) ]
            #println(var)
            end
            # Kepp only 2003 

            ols_temp_1 = filter(:year => ==(2003), climate_panel)
            # Keep if initxgdpxtile1 == 1
            ols_temp_1 = dropmissing(ols_temp_1, :initgdpxtile1)
            ols_temp_1 = filter(:initgdpxtile1 => ==(1),ols_temp_1)

            
            # Extract the standard errors for the coefficients
            coefficient_se_1 = HCE(ols_temp_1, "changeS1g_lngdpwdi", "changeS1wtem" )
            
            c_plus_1 = coefficient_se_1[2]+ 1.96 * coefficient_se_1[3]
            c_minus_1 = coefficient_se_1[2] - 1.96 * coefficient_se_1[3]
            
            
            
            p = scatter(ols_temp_1[:,:changeS1wtem], ols_temp_1[:,:changeS1g_lngdpwdi], legend=false)
            
            for i in 1:length(ols_temp_1[:,:changeS1wtem])
                annotate!(ols_temp_1[:,:changeS1wtem][i], ols_temp_1[:,:changeS1g_lngdpwdi][i], text(ols_temp_1[:,:country_code][i], :left, 8, :black))
            end
            # Add a line plot for the fitted values
            plot!(ols_temp_1[:,:changeS1wtem], coefficient_se_1[2], linewidth=2)
            # Add the confidence interval
            Minus = hcat(c_minus_1,ols_temp_1[:,:changeS1wtem])
            Plus = hcat(c_plus_1,ols_temp_1[:,:changeS1wtem])
            plot!(sort(ols_temp_1[:,:changeS1wtem]), Minus[sortperm(Minus[:,2]),:][:,1], color=:blue)
            plot!(sort(ols_temp_1[:,:changeS1wtem]), Plus[sortperm(Plus[:,2]),:][:,1], color=:blue)
            
            # Add a dashed line at y = 0
            hline!(p, [0], linestyle=:dash, color=:black)

            xlims!(-0.5, 1)
            ylims!(-10, 10)
            # Label the axes
            xlabel!("Change in temperature")
            ylabel!("Change in growth")
            # Set the plot title
            title!("A. Poor countries")
            

           

            ols_temp_2 = filter(:year => ==(2003), climate_panel)
            # Keep if initxgdpxtile1 == 1
            ols_temp_2 = dropmissing(ols_temp_2, :initgdpxtile1)
            ols_temp_2 = filter(:initgdpxtile1 => !=(1),ols_temp_2)

            # Compute the robust standard errors
            coefficient_se_2 = HCE(ols_temp_2, "changeS1g_lngdpwdi", "changeS1wtem" )
            #print("les std sont : $coefficient_se_2")
            c_plus_2 = coefficient_se_2[2]+ 1.96 * coefficient_se_2[3]
            c_minus_2 = coefficient_se_2[2] - 1.96 * coefficient_se_2[3]
            
            p2 = scatter(ols_temp_2[:,:changeS1wtem], ols_temp_2[:,:changeS1g_lngdpwdi], legend=false)
            
            for i in 1:length(ols_temp_2[:,:changeS1wtem])
                annotate!(ols_temp_2[:,:changeS1wtem][i], ols_temp_2[:,:changeS1g_lngdpwdi][i], text(ols_temp_2[:,:country_code][i], :left, 8, :black))
            end
            # Add a line plot for the fitted values
            plot!(ols_temp_2[:,:changeS1wtem], coefficient_se_2[2], linewidth=2)
            # Add the confidence interval
            Minus2 = hcat(c_minus_2,ols_temp_2[:,:changeS1wtem])
            Plus2 = hcat(c_plus_2,ols_temp_2[:,:changeS1wtem])
            plot!(sort(ols_temp_2[:,:changeS1wtem]), Minus2[sortperm(Minus2[:,2]),:][:,1], color=:blue)
            plot!(sort(ols_temp_2[:,:changeS1wtem]), Plus2[sortperm(Plus2[:,2]),:][:,1], color=:blue)
            
            # Add a dashed line at y = 0
            hline!(p2, [0], linestyle=:dash, color=:black)
            xlims!(-0.5, 1.5)
            ylims!(-10, 10)
            # Label the axes
            xlabel!("Change in temperature")
            ylabel!("Change in growth")
            # Set the plot title
            title!("B. Rich countries")
            
            fig2 = plot(p, p2, layout = (2, 1), size = (800, 600))
            display(fig2)
           

    #println(climate_panel[1:200, [:fips60_06, :year, :changeS1wtem, :changeS2wtem, :changeS3wtem]])
    #println(names(climate_panel))
    end

    #figure2_visualise("climate_panel_csv.csv")
    

    """
        make_table_1(raw_df_name::String)
    
    Create summary statistics of the Data.

    """
    function make_table1(raw_df_name::String)

        climate_panel = read_csv(raw_df_name)

        filter!(:year => <=(2003), climate_panel)

        transform!(climate_panel, :rgdpl => (x -> log.(x)) => :lgdp1)

        sort!(climate_panel, [:fips60_06, :year])

        climate_panel[!, :lngdpwdi] .= log.(climate_panel.gdpLCU)
        climate_panel[!, :lngdppwt] .= log.(climate_panel.rgdpl)
        transform!(groupby(climate_panel, :fips60_06), :lngdpwdi => lag => :temp_lag_gdp_WDI,
                                                          :lngdppwt => lag => :temp_lag_gdp_PWT)

        climate_panel[!, :g] .= ( climate_panel.lngdpwdi .- climate_panel.temp_lag_gdp_WDI ) .* 100
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
        climate_panel[!, :nonmissing] .= ifelse.(ismissing.(climate_panel.g), 0, 1)
        transform!(groupby(climate_panel, :fips60_06), :nonmissing => sum∘skipmissing)
        filter!(:nonmissing_sum_skipmissing => >=(20), climate_panel)

        #Make sure all subcomponents are non-missing in a given year
        climate_panel[!, :misdum] .= 0
        function filter_transform!(df, pred, args)
            fdf = filter(pred, df, view = true)
            fdf .= transform(copy(fdf), args)
        end
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,var => ismissing, :misdum => (b -> (b=1)) => :misdum)
        end
        for var in [:g_lnag, :g_lnind]
            filter_transform!(climate_panel,:misdum => ==(1), var => (b -> (b=missing)) => var)
        end
        
        temp1 = copy(climate_panel)
        temp1 = dropmissing(temp1, :lnrgdpl_t0)
        sort!(temp1, :fips60_06)
        temp1 = combine(first, groupby(temp1, :fips60_06))
        temp1[!, :initgdpbin] .= log.(temp1.lnrgdpl_t0) / size(temp1)[1]
        #CAREFUL ABOUT THE SORTING
        sort!(temp1, :initgdpbin)
        temp1[!, :initgdpbin] .= ifelse.(temp1.initgdpbin .< temp1[Int(round(size(temp1)[1] / 2)), :initgdpbin], 1 ,2)
        select!(temp1, [:fips60_06, :initgdpbin])
    end

        figure2_visualise("climate_panel_csv.csv")                     

end


