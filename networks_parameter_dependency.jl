using CSV, DataFrames
using FileIO, Dates
using Graphs, MetaGraphs
using DataStructures
using PyCall
using Plots

include("./src/cubes.jl")
include("./src/network.jl")

@pyimport powerlaw as powlaw


###########################################################################################################################
###########################################################################################################################
# Parameter dependency connectivity on cell_size results function
function networks_parameter_dependency(region; magnitude_threshold=0.0)
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);

    # Make path for results
    mkpath("./results/$region")

    # # Magnitude Threshold if you need it
    # magnitude_threshold = 0.0
    # df = df[df.Magnitude .> magnitude_threshold,:];

    # Cell sizes ranges from 0.5 to 20 with a 0.5 increment
    cube_cell_sizes= range(0.5, 20, step=0.5)

    degrees_alpha=[]
    degrees_xmin=[]
    marker_size=[]

    for cell_size in cube_cell_sizes
        df, df_cubes = region_cube_split(df,cell_size=cell_size)
        MG = create_network(df, df_cubes)

        degrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
        end

        fit = powlaw.Fit(degrees);
        push!(degrees_alpha, fit.alpha)
        push!(degrees_xmin, fit.xmin)
        push!(marker_size, fit.power_law.KS(data=degrees))

    end

    results = DataFrame([cube_cell_sizes, degrees_alpha, degrees_xmin, marker_size], ["cube_cell_sizes", "degrees_alpha", "degrees_xmin", "marker_size"])
    CSV.write("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", results, delim=",", header=false);

end


# Parameter dependency connectivity on cell_size plot function
function networks_parameter_dependency_plot(region; magnitude_threshold=0.0, goodness_of_fit=true)
    
    results = CSV.read("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", DataFrame)

    # Goodness of fit based on KS as marker sizes (smaller is better)
    if goodness_of_fit==true
        # Multipliers based on plot, manually set to look good 
        if region == "romania"
            multiplier_for_goodness_of_fit = 15
        elseif region =="california"
            multiplier_for_goodness_of_fit = 15
        elseif region =="italy"
            multiplier_for_goodness_of_fit = 20
        elseif region =="japan"
            multiplier_for_goodness_of_fit = 25
        end
        marker_size_log = 10 .^ (multiplier_for_goodness_of_fit .* results.marker_size)

        p1 = Plots.scatter(collect(cube_cell_sizes),degrees_alpha, xlabel="cube size", ylabel="alpha", markersize = marker_size_log);
        # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
        # hspan!([2,3], linecolor = :red, fillcolor = :red, alpha=0.3, label="")
        # hspan!([1.5,2], linecolor = :red, fillcolor = :red, alpha=0.2, label="")
        p2 = Plots.scatter(collect(cube_cell_sizes),degrees_xmin, xlabel="cube size", ylabel="xmin", markersize = marker_size_log);
        # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
        fig = Plots.plot(p1,p2, layout=(1,2), figsize=(12,17))
        Plots.plot!(fig, size=(1000,400))
        Plots.savefig(fig, "./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size_goodness_fit.png")
    end


    # No goodness of fit based on KS
    p1 = Plots.scatter(collect(cube_cell_sizes),degrees_alpha, xlabel="cube size", ylabel="alpha");
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    # hspan!([2,3], linecolor = :red, fillcolor = :red, alpha=0.3, label="")
    # hspan!([1.5,2], linecolor = :red, fillcolor = :red, alpha=0.2, label="")
    p2 = Plots.scatter(collect(cube_cell_sizes),degrees_xmin, xlabel="cube size", ylabel="xmin");
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    fig = Plots.plot(p1,p2, layout=(1,2), figsize=(12,17))
    Plots.plot!(fig, size=(1000,400))
    Plots.savefig(fig, "./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.png")

end
###########################################################################################################################
###########################################################################################################################


# Analysis of parameter dependency. Based on minimum KS, proper alpha and minimum xmin
function parameter_dependency_analysis(region; magnitude_threshold=0.0)
    results = CSV.read("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", DataFrame);

    # Eliminate records if alpha is not in range [1.5,3.5]

    results_filter_alpha = results[(results.alpha .> 1.7) .& (results.alpha .< 3.2), :];

    # Sort by KS and keep first 10 only
    results_sorted_KS = sort!(results_filter_alpha, [:KS])
    results_filter_alpha_sorted_KS = first(results_sorted_KS, 10)

    # Sort by xmin and keep first 7 only
    results_filter_alpha_sorted_KS_sorted_xmin = sort!(results_filter_alpha_sorted_KS, [:xmin])
    best_fits_region = first(results_filter_alpha_sorted_KS_sorted_xmin, 7) 
    return(best_fits_region)
end


###########################################################################################################################

magnitude_threshold = 0.0
df = DataFrame([[0,0,0,0,0,0,0]],["par_dep"])
for region in ["romania","california","italy","japan"]
    par_dep_best_fits = DataFrame([[0,0,0,0,0,0,0]],[region])
    best_fits = parameter_dependency_analysis(region; magnitude_threshold)
    par_dep_best_fits = hcat(par_dep_best_fits, best_fits)
    df = hcat(df, par_dep_best_fits, makeunique=true)
end

CSV.write("./results/best_fits_all_regions_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", df, delim=",", header=true);

###########################################################################################################################


# if region == "romania"
#     cell_sizes = [3.5, 4.0, 4.5, 5.0, 5.5];
#     # minimum_magnitudes = [0,1,2,3];
# elseif region == "california"
#     cell_sizes = [1.0, 1.5, 2.0];
#     # minimum_magnitudes = [2,3];
# elseif region == "italy"
#     cell_sizes = [4.0, 4.5, 5.0, 5.5, 6.0];
#     # minimum_magnitudes = [2,3];
# elseif region == "japan"
#     cell_sizes = [2.5, 3.0, 3.5, 4.0, 5.0];
#     # minimum_magnitudes = [2,3,4,5];
# end;