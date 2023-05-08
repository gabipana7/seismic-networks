using CSV, DataFrames
using FileIO, Dates
using Graphs, MetaGraphs
using DataStructures
using PyCall
using Plots
using DelimitedFiles
using StatsBase
using LinearAlgebra

include("./src/cubes.jl")
include("./src/network.jl")
include("./src/motifs_analysis.jl")

@pyimport powerlaw as powlaw

# Triangles Analysis
function analize_motifs_triangle(region, weighted_by)
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);

    motif="Triangle"
    if weighted_by == "totalenergy"
        weight_key = 1
    else 
        weight_key = 2
    end

    # Make path for results
    mkpath("./motifs/$weighted_by/$region")

    # Based on parameter dependency, extract which side lengths are the best:
    if region == "romania"
        sides = [3, 4, 5];
        minimum_magnitudes = [0,1,2,3];
    elseif region == "california"
        sides = [1, 1.5, 2];
        minimum_magnitudes = [2,3];
    elseif region == "italy"
        sides = [5, 7.5, 10];
        minimum_magnitudes = [2,3];
    elseif region == "japan"
        sides = [3, 4, 5];
        minimum_magnitudes = [2,3,4];
    end;

    for side in sides
        for minimum_magnitude in minimum_magnitudes
            # Filter by magnitude
            df_filtered = df[df.Magnitude .> minimum_magnitude,:] 

            # Split into cubes
            df_filtered, df_filtered_cubes = region_cube_split(df_filtered,side=side,energyRelease=true);

            # Get the motif
            network_target_path = "./networks/$(region)/side_$(string(side))km/"
            motif_filename = "motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude)).csv"

            # motifs = CSV.read(network_target_path * motif_filename, DataFrame);
            motifs = readdlm(network_target_path * motif_filename, ',', Int64);
            
            # Energy and areas calculator
            motif_energy = total_mean_energy(motifs, df_filtered, df_filtered_cubes);
            areas = area_triangles(motifs, df_filtered_cubes);

            # Area weighted by total/mean energy
            area_weight = []
            for key in keys(motif_energy)
                # Used to filter out zeros and very small areas (triangles on the vertical for example)
                if areas[key] > 1
                    push!(area_weight, areas[key]/motif_energy[key][weight_key])
                end
            end

            # Powerlaw fit
            fit_area_weight = powlaw.Fit(area_weight);
            alpha = round(fit_area_weight.alpha,digits=4)

            # CCDF of data truncated
            x_ccdf, y_ccdf = fit_area_weight.ccdf()
            Plots.plot(x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="side=$side, alpha=$alpha", linewidth=2.5)

            # Theoretical power_law
            fit_area_weight_power_law = fit_area_weight.power_law.plot_ccdf()[:lines][1]
            x_powlaw, y_powlaw = fit_area_weight_power_law[:get_xdata](), fit_area_weight_power_law[:get_ydata]()
            Plots.plot!(x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash)
            Plots.savefig("./motifs/$weighted_by/$region/motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude))_area_weight_$weighted_by.png")

            # CCDF of all data 
            x_ccdf, y_ccdf = fit_area_weight.ccdf(original_data=true)
            Plots.plot(x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="side=$side", linewidth=2.5)
            Plots.savefig("./motifs/$weighted_by/$region/motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude))_area_weight_$(weighted_by)_ccdf.png")

        end
    end
end

# Tetrahedron Analysis
function analize_motifs_tetrahedron(region, weighted_by)
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);

    motif="Tetrahedron"
    if weighted_by == "totalenergy"
        weight_key = 1
    else 
        weight_key = 2
    end

    # Make path for results
    mkpath("./motifs/$weighted_by/$region")

    # Based on parameter dependency, extract which side lengths are the best:
    if region == "romania"
        sides = [3, 4, 5];
        minimum_magnitudes = [0,1,2,3];
    elseif region == "california"
        sides = [1, 1.5, 2];
        minimum_magnitudes = [2,3];
    elseif region == "italy"
        sides = [5, 7.5, 10];
        minimum_magnitudes = [2,3];
    elseif region == "japan"
        sides = [5];
        minimum_magnitudes = [2,3,4];
    end;

    for side in sides
        for minimum_magnitude in minimum_magnitudes

            df_filtered = df[df.Magnitude .> minimum_magnitude,:] 

            # Split into cubes
            df_filtered, df_filtered_cubes = region_cube_split(df_filtered,side=side,energyRelease=true);

            # Get the motif
            network_target_path = "./networks/$(region)/side_$(string(side))km/"
            motif_filename = "motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude)).csv"

            # motifs = CSV.read(network_target_path * motif_filename, DataFrame);
            motifs = readdlm(network_target_path * motif_filename, ',', Int64);

            # Energy and volumes calculator
            motif_energy = total_mean_energy(motifs, df_filtered, df_filtered_cubes);
            volumes = volume_tetrahedrons(motifs, df_filtered_cubes);

            # Volumes weighted by total/mean energy
            volume_weight = []
            for key in keys(motif_energy)
                # Used to filter out zeros and very small volumes (triangles on the vertical for example)
                if volumes[key] > 1
                    push!(volume_weight, volumes[key]/motif_energy[key][weight_key])
                end
            end

            # Powerlaw fit
            fit_volume_weight = powlaw.Fit(volume_weight);
            alpha = round(fit_volume_weight.alpha,digits=4)

            # CCDF of data truncated
            x_ccdf, y_ccdf = fit_volume_weight.ccdf()
            Plots.plot(x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="side=$side, alpha=$alpha", linewidth=2.5)

            # Theoretical power_law
            fit_volume_weight_power_law = fit_volume_weight.power_law.plot_ccdf()[:lines][1]
            x_powlaw, y_powlaw = fit_volume_weight_power_law[:get_xdata](), fit_volume_weight_power_law[:get_ydata]()
            Plots.plot!(x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash)
            Plots.savefig("./motifs/$weighted_by/$region/motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude))_volume_weight_$weighted_by.png")

            # CCDF of all data 
            x_ccdf, y_ccdf = fit_volume_weight.ccdf(original_data=true)
            Plots.plot(x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="side=$side", linewidth=2.5)
            Plots.savefig("./motifs/$weighted_by/$region/motif$(motif)_$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude))_volume_weight_$(weighted_by)_ccdf.png")

        end
    end
end


# analize_motifs_triangle("japan", "meanenergy")

# analize_motifs_tetrahedron("japan", "meanenergy")
