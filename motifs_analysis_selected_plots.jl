using CSV, DataFrames
using FileIO, Dates
using PyCall
using DelimitedFiles
using CairoMakie

include("./src/cubes.jl")
include("./src/motifs_analysis.jl")

@pyimport powerlaw as powlaw

regions=["romania", "california", "italy", "japan"]
motifs=["Triangle", "Tetrahedron"]

if motif == "Triangle"
    if region == "romania"
        cell_sizes = [3.0];
        minimum_magnitudes = [2];
    elseif region == "california"
        cell_sizes = [1.0, 2.0];
        minimum_magnitudes = [2];
    elseif region == "italy"
        cell_sizes = [4.5, 5.0,];
        minimum_magnitudes = [2];
    elseif region == "japan"
        cell_sizes = [2.5, 3.0];
        minimum_magnitudes = [2, 3];
    end
elseif motif == "Tetrahedron"
    if region == "romania"
        cell_sizes = [5.0];
        minimum_magnitudes = [3];
    elseif region == "california"
        cell_sizes = [1.0, 2.0];
        minimum_magnitudes = [2];
    elseif region == "italy"
        cell_sizes = [4.0];
        minimum_magnitudes = [2];
    elseif region == "japan"
        cell_sizes = [2.5];
        minimum_magnitudes = [3];
    end

end


function analize_motifs_triangle_selected_plots(region, weighted_by)
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
    # mkpath("./motifs/$weighted_by/$region")
    results = CSV.read("./motifs/$weighted_by/$region/$results_file", DataFrame)

    

    # Based on selected plots:
    if region == "romania"
        cell_sizes = [3.0];
        minimum_magnitudes = [2];
    elseif region == "california"
        cell_sizes = [1.0, 2.0];
        minimum_magnitudes = [2];
    elseif region == "italy"
        cell_sizes = [4.5, 5.0,];
        minimum_magnitudes = [2];
    elseif region == "japan"
        cell_sizes = [2.5, 3.0];
        minimum_magnitudes = [2, 3];
    end

    


    for cell_size in cell_sizes
        for minimum_magnitude in minimum_magnitudes
            #############################################################################################################################################################
            # Filter by magnitude
            df_filtered = df[df.Magnitude .> minimum_magnitude,:] 
            # Split into cubes
            df_filtered, df_filtered_cubes = region_cube_split(df_filtered,cell_size=cell_size, energyRelease=true);

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
            # Select xmin based on weighted_by, region, motif, cell_size and minmag


            # Powerlaw fit
            fit = powlaw.Fit(area_weight);
            alpha = fit.alpha
            xmin = fit.xmin
            KS = fit.power_law.KS(data=area_weight)

           
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