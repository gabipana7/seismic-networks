using CSV, DataFrames
using FileIO, Dates
using Graphs, MetaGraphs
using DataStructures
using PyCall
using Plots

include("./src/cubes.jl")
include("./src/network.jl")

@pyimport powerlaw as powlaw


# Parameter dependency connectivity on cell_size
function networks_parameter_dependency(region)
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);

    # Make path for results
    mkpath("./results/$region")

    # # Magnitude Threshold if you need it
    magnitude_threshold = 0.0
    # df = df[df.Magnitude .> magnitude_threshold,:];

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

    # Goodness of fit based on KS as marker sizes (smaller is better)

    if region == "romania"
        multiplier_for_goodness_of_fit = 15
    elseif region =="california"
        multiplier_for_goodness_of_fit = 15
    elseif region =="italy"
        multiplier_for_goodness_of_fit = 20
    elseif region =="japan"
        multiplier_for_goodness_of_fit = 25
    end
    
    marker_size_log = 10 .^ (multiplier_for_goodness_of_fit .* marker_size)

    p1 = Plots.scatter(collect(cube_cell_sizes),degrees_alpha, xlabel="cube size", ylabel="alpha", markersize = marker_size_log);
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    # hspan!([2,3], linecolor = :red, fillcolor = :red, alpha=0.3, label="")
    # hspan!([1.5,2], linecolor = :red, fillcolor = :red, alpha=0.2, label="")
    p2 = Plots.scatter(collect(cube_cell_sizes),degrees_xmin, xlabel="cube size", ylabel="xmin", markersize = marker_size_log);
    # vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
    fig = Plots.plot(p1,p2, layout=(1,2), figsize=(12,17))
    Plots.plot!(fig, size=(1000,400))
    Plots.savefig(fig, "./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size_goodness_fit.png")


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


    results = DataFrame([cube_cell_sizes, degrees_alpha, degrees_xmin, marker_size], ["cube_cell_sizes", "degrees_alpha", "degrees_xmin", "marker_size"])
    CSV.write("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", results, delim=",", header=false);

end

networks_parameter_dependency("romania")

region = "japan"
magnitude_threshold = 0.0

# Read data
path = "./data/"
filepath = path * region * ".csv"
df = CSV.read(filepath, DataFrame);

# Make path for results
mkpath("./results/$region")

# # Magnitude Threshold if you need it
magnitude_threshold = 0.0
# df = df[df.Magnitude .> magnitude_threshold,:];

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

# Goodness of fit based on KS as marker sizes (smaller is better)

if region == "romania"
    multiplier_for_goodness_of_fit = 15
elseif region =="california"
    multiplier_for_goodness_of_fit = 15
elseif region =="italy"
    multiplier_for_goodness_of_fit = 20
elseif region =="japan"
    multiplier_for_goodness_of_fit = 25
end

marker_size_log = 10 .^ (multiplier_for_goodness_of_fit .* marker_size)

p1 = Plots.scatter(collect(cube_cell_sizes),degrees_alpha, xlabel="cube size", ylabel="alpha", markersize = marker_size_log);
# vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
# hspan!([2,3], linecolor = :red, fillcolor = :red, alpha=0.3, label="")
# hspan!([1.5,2], linecolor = :red, fillcolor = :red, alpha=0.2, label="")
p2 = Plots.scatter(collect(cube_cell_sizes),degrees_xmin, xlabel="cube size", ylabel="xmin", markersize = marker_size_log);
# vspan!([2,13], linecolor = :grey, fillcolor = :grey, alpha=0.3, label="")
fig = Plots.plot(p1,p2, layout=(1,2), figsize=(12,17))
Plots.plot!(fig, size=(1000,400))
Plots.savefig(fig, "./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size_goodness_fit.png")


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


results = DataFrame([cube_cell_sizes, degrees_alpha, degrees_xmin, marker_size], ["cell_size", "alpha", "xmin", "KS"])
CSV.write("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", results, delim=",", header=true);



# Study the cell_size 


results = CSV.read("./results/$region/$(region)_minmag_$(magnitude_threshold)_alpha_xmin_dependency_cell_size.csv", DataFrame)

results_sorted_KS = sort!(results, [:KS])

first(results_sorted_KS, 9) 

results_sorted_KS_xmin = sort!(first(results_sorted_KS,5), [:xmin])

results_sorted_KS_xmin_alpha = sort!(results_sorted_KS_xmin, [:alpha])


first(results_sorted_KS_xmin_alpha, 8) 