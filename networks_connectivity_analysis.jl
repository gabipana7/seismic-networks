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


function connectivity_analysis(region)
    # Based on parameter dependency, extract which cell_size lengths are the best:
    if region == "romania"
        cell_sizes = [3, 4, 5];
        # minimum_magnitudes = [0,1,2,3];
    elseif region == "california"
        cell_sizes = [1, 1.5, 2];
        # minimum_magnitudes = [2,3];
    elseif region == "italy"
        cell_sizes = [5, 7.5, 10];
        # minimum_magnitudes = [2,3];
    elseif region == "japan"
        cell_sizes = [3, 4, 5];
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
    # All data, fit through partial
    p1 = Plots.plot(xlabel = "k", ylabel = "P(k)")
    # Partial data and fit, renormed
    p2 = Plots.plot(xlabel = "k", ylabel = "P(k)")

    for cell_size in cell_sizes
        df, df_cubes = region_cube_split(df,cell_size=cell_size)
        MG = create_network(df, df_cubes)
        degrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
        end

        # Powerlaw Fit
        fit = powlaw.Fit(degrees);
        alpha = round(fit.alpha, digits=4)
        xmin = round(fit.xmin, digits=4)
        KS = round(fit.power_law.KS(data=degrees), digits=4)


        # CCDF of truncated data (fitted), x and y values
        x_ccdf, y_ccdf = fit.ccdf()

        # The fit (from theoretical power_law)
        fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
        x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()


        ########################################### ALL
        # CCDF of all data scattered 
        x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
        Plots.scatter!(p1, x_ccdf_original_data, y_ccdf_original_data, xscale=:log10, yscale=:log10, 
                        label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
        # Fit through truncated data
        # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
        Plots.plot!(p1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, xscale=:log10, yscale=:log10, 
                        label="", color=:red, linestyle=:dash, linewidth=3) 


        ########################################### TRUNCATED
        # CCDF of truncated data (fitted), the plot, (re-normed)
        Plots.scatter!(p2, x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
        
        # Fit through truncated data (re-normed)
        Plots.plot!(p2, x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash) #label="power law, alpha=$(alpha)")


    end
    Plots.plot!(p1, size=(800,500), legend=:bottomleft)
    Plots.savefig(p1, "./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits_all_data.png")

    Plots.plot!(p2, size=(800,500), legend=:bottomleft)
    Plots.savefig(p2, "./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits.png")

end


function connectivity_analysis_and_histogram(region, cell_size)
    # # Based on parameter dependency, extract which cell_size lengths are the best:
    # if region == "romania"
    #     cell_sizes = [3, 4, 5];
    #     # minimum_magnitudes = [0,1,2,3];
    # elseif region == "california"
    #     cell_sizes = [1, 1.5, 2];
    #     # minimum_magnitudes = [2,3];
    # elseif region == "italy"
    #     cell_sizes = [5, 7.5, 10];
    #     # minimum_magnitudes = [2,3];
    # elseif region == "japan"
    #     cell_sizes = [3, 4, 5];
    #     # minimum_magnitudes = [2,3,4];
    # end;

    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);
    magnitude_threshold = 0.0

    # Make path for results
    mkpath("./results/$region")

    # Powerlaw CCDFS and FITS
    # All data, fit through partial
    p1 = Plots.plot(xlabel = "k", ylabel = "P(k)")
    # Partial data and fit, renormed
    p2 = Plots.plot(xlabel = "k", ylabel = "P(k)")
    # Histogram / density plot
    p3 = Plots.plot(xlabel = "k", ylabel = "P(k)")

    df, df_cubes = region_cube_split(df,cell_size=cell_size)
    MG = create_network(df, df_cubes)
    degrees=[]
    for i in 1:nv(MG)
        push!(degrees, get_prop(MG, i, :degree))
    end

    # Powerlaw Fit
    fit = powlaw.Fit(degrees);
    alpha = round(fit.alpha,digits=4)
    xmin = round(fit.xmin,digits=4)
    KS = round(fit.power_law.KS(data=degrees), digits=4)


    # CCDF of truncated data (fitted), x and y values
    x_ccdf, y_ccdf = fit.ccdf()

    # The fit (from theoretical power_law)
    fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
    x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()


    ########################################### ALL
    # CCDF of all data scattered 
    x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
    Plots.scatter!(p1, x_ccdf_original_data, y_ccdf_original_data, xscale=:log10, yscale=:log10, 
                    label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
    # Fit through truncated data
    # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
    Plots.plot!(p1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, xscale=:log10, yscale=:log10, 
                    label="", color=:red, linestyle=:dash, linewidth=3) 

    Plots.plot!(p1, size=(800,500), legend=:bottomleft)
    Plots.savefig(p1, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_all_data.png")


    ########################################### TRUNCATED
    # CCDF of truncated data (fitted), the plot, (re-normed)
    Plots.scatter!(p2, x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
    
    # Fit through truncated data (re-normed)
    Plots.plot!(p2, x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash) #label="power law, alpha=$(alpha)")

    Plots.plot!(p2, size=(800,500), legend=:bottomleft)
    Plots.savefig(p2, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold).png")


    ########################################### HISTOGRAM (density plot?)
    d = counter(degrees)
    Plots.scatter!(p3, collect(keys(d)),collect(values(d)),xscale=:log10,yscale=:log10)
    Plots.plot!(p3, size=(800,500), legend=:bottomleft)
    Plots.savefig(p3, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_histogram.png")

end


connectivity_analysis("california")

connectivity_analysis_and_histogram("california", 5)



# # Based on parameter dependency, extract which cell_size lengths are the best:
# if region == "romania"
#     cell_sizes = [3, 4, 5];
#     # minimum_magnitudes = [0,1,2,3];
# elseif region == "california"
#     cell_sizes = [1, 1.5, 2];
#     # minimum_magnitudes = [2,3];
# elseif region == "italy"
#     cell_sizes = [5, 7.5, 10];
#     # minimum_magnitudes = [2,3];
# elseif region == "japan"
#     cell_sizes = [3, 4, 5];
#     # minimum_magnitudes = [2,3,4];
# end;




