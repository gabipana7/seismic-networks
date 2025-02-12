using CSV, DataFrames
using FileIO, Dates
using PyCall
using DelimitedFiles
using CairoMakie

include("./src/cubes.jl")
include("./src/motifs_analysis.jl")

@pyimport powerlaw as powlaw

# ENV["GKSwstype"]="nul"

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

    # Based on parameter dependency, extract which cell_size lengths are the best:
    if region == "romania"
        cell_sizes = [3.0, 3.5, 4.0, 4.5, 5.0, 5.5];
        minimum_magnitudes = [3,2,1,0];
    elseif region == "california"
        cell_sizes = [2.0];
        minimum_magnitudes = [0];
    elseif region == "italy"
        # cell_sizes = [4.0, 4.5, 5.0, 5.5, 6.0, 7.5, 10.0];
        # minimum_magnitudes = [3,2,1,0];
        cell_sizes = [4.5, 5.0, 5.5, 6.0, 7.5, 10.0];
        minimum_magnitudes = [3,2,1];
    elseif region == "japan"
        cell_sizes = [2.5, 3.0, 3.5, 4.0, 5.0];
        minimum_magnitudes = [4,3,2];
    end

    for cell_size in cell_sizes
        for minimum_magnitude in minimum_magnitudes
            #############################################################################################################################################################
            # Filter by magnitude
            df_filtered = df[df.Magnitude .> minimum_magnitude,:] 
            # Split into cubes
            df_filtered, df_filtered_cubes = region_cube_split(df_filtered,cell_size=cell_size,energyRelease=true);

            # Get the motif
            network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
            motif_filename = "motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).csv"
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
            #############################################################################################################################################################
            # THE FIT
            # Powerlaw fit
            fit = powlaw.Fit(area_weight);
            alpha = fit.alpha
            xmin = fit.xmin
            KS = fit.power_law.KS(data=area_weight)

            # Create a results file (if it does not exist) and save it empty
            results_file = "results" * motif * ".csv"
            if isfile("./motifs/$weighted_by/$region/$results_file")
                println("file exists")
                # Open results file to temporary dataframe
                results = CSV.read("./motifs/$weighted_by/$region/$results_file", DataFrame)
                # Append results to temporary dataframe
                push!(results, [weighted_by, region, motif, cell_size, minimum_magnitude, alpha, xmin, KS])
                # Save the temporary dataframe as results file
                CSV.write("./motifs/$weighted_by/$region/$results_file", results, delim=",", header=true); 
                # Close results file
            else
                results = DataFrame([Any[], Any[], Any[], Any[], Any[], Any[], Any[], Any[]], ["weighted_by","region","motif","cell_size","minmag","alpha","xmin","KS"])
                push!(results, [weighted_by, region, motif, cell_size, minimum_magnitude, alpha, xmin, KS])
                CSV.write("./motifs/$weighted_by/$region/$results_file", results, delim=",", header=true); 
            end
            #############################################################################################################################################################

            #############################################################################################################################################################
            # THE PLOTS 
            # CCDF of truncated data (fitted), x and y values
            x_ccdf, y_ccdf = fit.ccdf()

            # The fit (from theoretical power_law)
            fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
            x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()

            # Round up the data
            alpha = round(alpha, digits=2)
            xmin = round(xmin, digits=5)
            KS = round(KS, digits=3)

            set_theme!(Theme(fonts=(; regular="CMU Serif Bold")))

            ########################################### ALL
            # CCDF of all data scattered 
            fig1 = Figure(resolution = (600, 500), font= "CMU Serif") 
            ax1 = Axis(fig1[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
                xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
                xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10)

            x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(area_weight)

            
            sc1 = scatter!(ax1, x_ccdf_original_data, y_ccdf_original_data,
                color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

            # Fit through truncated data
            # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
            ln1 = lines!(ax1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw,
                color=:red, linewidth=2.5) 

            axislegend(ax1, [sc1], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
            axislegend(ax1, [ln1], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)"], position = :lb, bgcolor = (:grey90, 0.25));


            ########################################### TRUNCATED
            # CCDF of truncated data (fitted), the plot, (re-normed)
            fig2 = Figure(resolution = (600, 500), font= "CMU Serif") 
            ax2 = Axis(fig2[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
                xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
                xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10)

            sc2 = scatter!(ax2, x_ccdf, y_ccdf,
                color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

            # Fit through truncated data (re-normed)
            ln2 = lines!(ax2, x_powlaw, y_powlaw,
                    color=:red, linewidth=2.5) 

            axislegend(ax2, [sc2], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
            axislegend(ax2, [ln2], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)"], position = :lb, bgcolor = (:grey90, 0.25));  
        

            save("./motifs/$weighted_by/$region/motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude))_area_$(weighted_by)_all_data.png", fig1, px_per_unit=5)
            save("./motifs/$weighted_by/$region/motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude))_area_$weighted_by.png", fig2, px_per_unit=5)
            #############################################################################################################################################################

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

    # Based on parameter dependency, extract which cell_size lengths are the best:
    if region == "romania"
        cell_sizes = [3.0, 3.5, 4.0, 4.5, 5.0, 5.5];
        minimum_magnitudes = [3,2,1,0];
    elseif region == "california"
        cell_sizes = [1.0, 1.5, 2.0];
        minimum_magnitudes = [3,2,1];
    elseif region == "italy"
        cell_sizes = [4.5, 5.0, 5.5, 6.0, 7.5, 10.0];
        minimum_magnitudes = [3,2];
    elseif region == "japan"
        cell_sizes = [2.5, 3.0, 3.5, 4.0, 5.0];
        minimum_magnitudes = [4,3,2];
    end

    for cell_size in cell_sizes
        for minimum_magnitude in minimum_magnitudes
            #############################################################################################################################################################
            # Filter by magnitude
            df_filtered = df[df.Magnitude .> minimum_magnitude,:] 
            # Split into cubes
            df_filtered, df_filtered_cubes = region_cube_split(df_filtered,cell_size=cell_size,energyRelease=true);

            # Get the motif
            network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
            motif_filename = "motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).csv"
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
            #############################################################################################################################################################
            # THE FIT
            # Powerlaw fit
            fit = powlaw.Fit(volume_weight);
            alpha = fit.alpha
            xmin = fit.xmin
            KS = fit.power_law.KS(data=volume_weight)

            # Create a results file (if it does not exist) and save it empty
            results_file = "results" * motif * ".csv"
            if isfile("./motifs/$weighted_by/$region/$results_file")
                println("file exists")
                # Open results file to temporary dataframe
                results = CSV.read("./motifs/$weighted_by/$region/$results_file", DataFrame)
                # Append results to temporary dataframe
                push!(results, [weighted_by, region, motif, cell_size, minimum_magnitude, alpha, xmin, KS])
                # Save the temporary dataframe as results file
                CSV.write("./motifs/$weighted_by/$region/$results_file", results, delim=",", header=true); 
                # Close results file
            else
                results = DataFrame([Any[], Any[], Any[], Any[], Any[], Any[], Any[], Any[]], ["weighted_by","region","motif","cell_size","minmag","alpha","xmin","KS"])
                push!(results, [weighted_by, region, motif, cell_size, minimum_magnitude, alpha, xmin, KS])
                CSV.write("./motifs/$weighted_by/$region/$results_file", results, delim=",", header=true); 
            end
            #############################################################################################################################################################

            #############################################################################################################################################################
            # THE PLOTS 
            # CCDF of truncated data (fitted), x and y values
            x_ccdf, y_ccdf = fit.ccdf()

            # The fit (from theoretical power_law)
            fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
            x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()

            # Round up the data
            alpha = round(alpha, digits=2)
            xmin = round(xmin, digits=5)
            KS = round(KS, digits=3)

            set_theme!(Theme(fonts=(; regular="CMU Serif Bold")))

            ########################################### ALL
            # CCDF of all data scattered 
            fig1 = Figure(resolution = (600, 500), font= "CMU Serif") 
            ax1 = Axis(fig1[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
                xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
                xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10)

            x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(volume_weight)

            
            sc1 = scatter!(ax1, x_ccdf_original_data, y_ccdf_original_data,
                color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

            # Fit through truncated data
            # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
            ln1 = lines!(ax1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw,
                color=:red, linewidth=2.5) 

            axislegend(ax1, [sc1], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
            axislegend(ax1, [ln1], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)"], position = :lb, bgcolor = (:grey90, 0.25));


            ########################################### TRUNCATED
            # CCDF of truncated data (fitted), the plot, (re-normed)
            fig2 = Figure(resolution = (600, 500), font= "CMU Serif") 
            ax2 = Axis(fig2[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
                xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
                xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10)

            sc2 = scatter!(ax2, x_ccdf, y_ccdf,
                color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

            # Fit through truncated data (re-normed)
            ln2 = lines!(ax2, x_powlaw, y_powlaw,
                    color=:red, linewidth=2.5) 

            axislegend(ax2, [sc2], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
            axislegend(ax2, [ln2], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)"], position = :lb, bgcolor = (:grey90, 0.25));  
        

            save("./motifs/$weighted_by/$region/motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude))_volume_$(weighted_by)_all_data.png", fig1, px_per_unit=5)
            save("./motifs/$weighted_by/$region/motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude))_volume_$weighted_by.png", fig2, px_per_unit=5)
            #############################################################################################################################################################
        end
    end
end



if ARGS[1] == "Triangle"
    analize_motifs_triangle(ARGS[2], ARGS[3])
elseif ARGS[1] == "Tetrahedron"
    analize_motifs_tetrahedron(ARGS[2], ARGS[3])
end