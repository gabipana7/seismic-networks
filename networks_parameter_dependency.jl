using CSV, DataFrames
using FileIO, Dates
using Graphs, MetaGraphs
using DataStructures
using PyCall
using Plots
# using PyPlot; gr()
# using HypothesisTests

include("./src/cubes.jl")
include("./src/network.jl")

@pyimport powerlaw as powlaw


# Triangles Analysis
function networks_parameter_dependency(region, weighted_by)
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);

    # Make path for results
    mkpath("./results/$region")

    # # Magnitude Threshold if you need it
    # magnitude_threshold = 0.0
    # df = df[df.Magnitude .> magnitude_threshold,:];

    cube_sides= range(0.5, 20, step=0.5)

    degrees_alpha=[]
    degrees_xmin=[]
    marker_size=[]

    for side in cube_sides
        df, df_cubes = region_cube_split(df,side=side)
        MG = create_network(df, df_cubes)
        degrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
        end

        fit_degrees = powlaw.Fit(degrees);
        push!(degrees_alpha, fit_degrees.alpha)
        push!(degrees_xmin, fit_degrees.xmin)
        push!(marker_size, fit_degrees.power_law.KS(data=degrees))

    end

    marker_size_log = 10 .^ (30 .* marker_size)

    # collect(cube_sides)
    p1 = Plots.scatter(collect(cube_sides),degrees_alpha, xlabel="cube size", ylabel="alpha", markersize = marker_size_log);
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    # hspan!([2,3], linecolor = :red, fillcolor = :red, alpha=0.3, label="")
    # hspan!([1.5,2], linecolor = :red, fillcolor = :red, alpha=0.2, label="")
    p2 = Plots.scatter(collect(cube_sides),degrees_xmin, xlabel="cube size", ylabel="xmin", markersize = marker_size_log);
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    fig = Plots.plot(p1,p2, layout=(1,2), figsize=(12,17))
    plot!(size=(1000,400))
    Plots.savefig("./results/$region/$(region)_mag_$(magnitude_threshold)_alpha_xmin_dependency_side_goodness_fit.png")

end


function ccdfs_and_fits(region)
    # Based on parameter dependency, extract which side lengths are the best:
    if region == "romania"
        sides = [3, 4, 5];
        # minimum_magnitudes = [0,1,2,3];
    elseif region == "california"
        sides = [1, 1.5, 2];
        # minimum_magnitudes = [2,3];
    elseif region == "italy"
        sides = [5, 7.5, 10];
        # minimum_magnitudes = [2,3];
    elseif region == "japan"
        sides = [3, 4, 5];
        # minimum_magnitudes = [2,3,4];
    end;

    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);
    magnitude_threshold = 0.0

    # Make path for results
    mkpath("./results/$region")

    # Powerlaw CCDFS and FITS
    Plots.plot(xlabel = "k", ylabel = "P(k)")
    for side in sides
        df, df_cubes = region_cube_split(df,side=side)
        MG = create_network(df, df_cubes)
        degrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
        end

        # Powerlaw Fit
        fit = powlaw.Fit(degrees);
        alpha = round(fit.alpha,digits=4)

        # CCDF of data truncated
        x_ccdf, y_ccdf = fit.ccdf()
        Plots.plot!(x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="side=$side, alpha=$alpha", linewidth=2.5)
        
        # Theoretical power_law
        fit_degrees_power_law = fit.power_law.plot_ccdf()[:lines][1]
        x_powlaw, y_powlaw = fit_degrees_power_law[:get_xdata](), fit_degrees_power_law[:get_ydata]()
        Plots.plot!(x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash) #label="power law, alpha=$(alpha)")
        
        # # Theoretical lognormal
        # mu = round(fit.lognormal.mu, digits=4)
        # fit_degrees_lognormal = fit.lognormal.plot_ccdf()[:lines][1]
        # x_lognormal, y_lognormal = fit_degrees_lognormal[:get_xdata](), fit_degrees_lognormal[:get_ydata]()
        # Plots.plot!(x_lognormal, y_lognormal, xscale=:log10, yscale=:log10, label="") #label="lognormal, mu=$(mu)")

    end
    plot!(size=(800,500), legend=:bottomleft)
    Plots.savefig("./results/$region/$(region)_mag_$(magnitude_threshold)_best_fits.png")


    # Original data CCDFS and FITS
    Plots.plot(xlabel = "k", ylabel = "P(k)")
    for side in sides
        df, df_cubes = region_cube_split(df,side=side)
        MG = create_network(df, df_cubes)
        degrees=[]
        # indegrees=[]
        # outdegrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
            # push!(indegrees, get_prop(MG, i, :indegree))
            # push!(outdegrees, get_prop(MG, i, :outdegree))
        end
        
        fit = powlaw.Fit(degrees)
        x_ccdf, y_ccdf = fit.ccdf()
        Plots.plot(xlabel = "k", ylabel = "P(k)")

        x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
        Plots.scatter!(x_ccdf_original_data, y_ccdf_original_data, xscale=:log10, yscale=:log10, label="side=$side, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)

        # Theoretical power_law over all data
        fit_degrees_power_law = fit.power_law.plot_pdf()[:lines][1]
        x_powlaw, y_powlaw = fit_degrees_power_law[:get_xdata](), fit_degrees_power_law[:get_ydata]()
        Plots.plot!(x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, xscale=:log10, yscale=:log10, label="", color=:black, linestyle=:dash, linewidth=3) 
    end
    Plots.savefig("./results/$region/$(region)_mag_$(magnitude_threshold)_best_fits_original_data.png")

end


ccdfs_and_fits("romania")

ccdfs_and_fits("california")

ccdfs_and_fits("italy")

ccdfs_and_fits("japan")