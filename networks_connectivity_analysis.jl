using CSV, DataFrames
using FileIO, Dates
using Graphs, MetaGraphs
using DataStructures
using PyCall
using CairoMakie
# using PyPlot; gr()
# using HypothesisTests

include("./src/cubes.jl")
include("./src/network.jl")

@pyimport powerlaw as powlaw


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


######################################################################################################################
function connectivity_analysis_cairo(region)
    # Select 3 of the best cell sizes from parameter dependency analysis
    if region == "romania"
        cell_sizes = [3.5,  4.5,  5.5];
        # minimum_magnitudes = [0,1,2,3];
    elseif region == "california"
        cell_sizes = [1.0, 1.5, 2.0];
        # minimum_magnitudes = [2,3];
    elseif region == "italy"
        cell_sizes = [4.0, 5.0, 6.0];
        # minimum_magnitudes = [2,3];
    elseif region == "japan"
        cell_sizes = [2.5, 3.5, 5.0];
        # minimum_magnitudes = [2,3,4,5];
    end;
    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);
    magnitude_threshold = 0.0

    # Make path for results
    mkpath("./results/$region")

    set_theme!(Theme(fonts=(; regular="CMU Serif Bold")))
    fig1 = Figure(resolution = (600, 500), font= "CMU Serif") 
    ax1 = Axis(fig1[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
        xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
        xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10, xtickformat="{:.1f}")
    
    fig2 = Figure(resolution = (600, 500), font= "CMU Serif") 
    ax2 = Axis(fig2[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
        xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
        xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10, xtickformat="{:.1f}")
    
    markers=[:utriangle, :diamond, :circle]
    colors=[:midnightblue, :green, :darkred]
    
    sc1 = Array{Any,1}(undef,3)
    sc2 = Array{Any,1}(undef,3)
    
    for i in eachindex(cell_sizes)
        df, df_cubes = region_cube_split(df,cell_size=cell_sizes[i])
        MG = create_network(df, df_cubes)
        degrees=[]
        for i in 1:nv(MG)
            push!(degrees, get_prop(MG, i, :degree))
        end
    
        # Powerlaw Fit
        fit = powlaw.Fit(degrees);
        alpha = round(fit.alpha, digits=2)
        xmin = Int(round(fit.xmin, digits=2))
        KS = round(fit.power_law.KS(data=degrees), digits=3)
    
        # CCDF of truncated data (fitted), x and y values
        x_ccdf, y_ccdf = fit.ccdf()
    
        # The fit (from theoretical power_law)
        fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
        x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()
    
        ########################################### ALL
        # CCDF of all data scattered 
        x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
    
    
        sc1[i] = scatter!(ax1, x_ccdf_original_data, y_ccdf_original_data,
            color=(colors[i], 0.22), strokewidth=0.2, marker=markers[i], markersize=13)
    
        # Fit through truncated data
        # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
        ln = lines!(ax1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, label= L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)",
            color=colors[i], linewidth=2.5) 
    
    
        ########################################### TRUNCATED
        # CCDF of truncated data (fitted), the plot, (re-normed)
        sc2[i] = scatter!(ax2, x_ccdf, y_ccdf,
            color=(colors[i], 0.22), strokewidth=0.2, marker=markers[i], markersize=13)
    
        # Fit through truncated data (re-normed)
        ln = lines!(ax2, x_powlaw, y_powlaw, label= L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)",
             color=colors[i], linewidth=2.5) 
    
    end
    
    # Top right, cell size legend
    axislegend(ax1, [sc1[i] for i in eachindex(cell_sizes)], [L"\text{cell\,size}=%$(cell_sizes[i])" for i in eachindex(cell_sizes)], position = :rt, bgcolor = (:grey90, 0.25));
    axislegend(ax2, [sc2[i] for i in eachindex(cell_sizes)],  [L"\text{cell\,size}=%$(cell_sizes[i])" for i in eachindex(cell_sizes)], position = :rt, bgcolor = (:grey90, 0.25));
    
    # Bottom left, results legend
    axislegend(ax1, position = :lb, bgcolor = (:grey90, 0.25));
    axislegend(ax2, position = :lb, bgcolor = (:grey90, 0.25));
    
    # Save both plots
    save( "./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits_all_data.png", fig1, px_per_unit=5)
    save("./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits.png", fig2, px_per_unit=5)

end
######################################################################################################################




######################################################################################################################
function connectivity_analysis_histogram_cairo(region, cell_size)
    # Select 3 of the best cell sizes from parameter dependency analysis

    # Read data
    path = "./data/"
    filepath = path * region * ".csv"
    df = CSV.read(filepath, DataFrame);
    magnitude_threshold = 0.0

    # Make path for results
    mkpath("./results/$region")

    df, df_cubes = region_cube_split(df,cell_size=cell_size)
    MG = create_network(df, df_cubes)
    degrees=[]
    for i in 1:nv(MG)
        push!(degrees, get_prop(MG, i, :degree))
    end

    # Powerlaw Fit
    fit = powlaw.Fit(degrees);
    alpha = round(fit.alpha, digits=2)
    xmin = Int(round(fit.xmin, digits=2))
    KS = round(fit.power_law.KS(data=degrees), digits=3)

    # CCDF of truncated data (fitted), x and y values
    x_ccdf, y_ccdf = fit.ccdf()

    # The fit (from theoretical power_law)
    fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
    x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()


    set_theme!(Theme(fonts=(; regular="CMU Serif Bold")))

    ########################################### ALL
    # CCDF of all data scattered 
    fig1 = Figure(resolution = (600, 500), font= "CMU Serif") 
    ax1 = Axis(fig1[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
        xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
        xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10, xtickformat="{:.1f}")

    x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)

    
    sc1 = scatter!(ax1, x_ccdf_original_data, y_ccdf_original_data,
        color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

    # Fit through truncated data
    # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
    ln1 = lines!(ax1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, label= L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)",
        color=:red, linewidth=2.5) 

    axislegend(ax1, [sc1], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
    axislegend(ax1, [ln1], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin)"], position = :lb, bgcolor = (:grey90, 0.25));


    ########################################### TRUNCATED
    # CCDF of truncated data (fitted), the plot, (re-normed)
    fig2 = Figure(resolution = (600, 500), font= "CMU Serif") 
    ax2 = Axis(fig2[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
        xlabelsize = 22, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
        xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10, xtickformat="{:.1f}")

    sc2 = scatter!(ax2, x_ccdf, y_ccdf,
        color=(:midnightblue, 0.2), strokewidth=0.2, marker=:circle, markersize=13)

    # Fit through truncated data (re-normed)
    ln2 = lines!(ax2, x_powlaw, y_powlaw, label= L"\alpha=%$(alpha),\, x_{min}=%$(xmin),\, KS=%$(KS)",
            color=:red, linewidth=2.5) 

    axislegend(ax2, [sc2], [L"\text{cell\,size}=%$(cell_size)"], position = :rt, bgcolor = (:grey90, 0.25));
    axislegend(ax2, [ln2], [L"\alpha=%$(alpha),\, x_{min}=%$(xmin)"], position = :lb, bgcolor = (:grey90, 0.25));    
    

    ########################################### HISTOGRAM
    # Histogram (density plot) of all data / no fit
    degrees = convert(Vector{Int}, degrees)
    d = counter(degrees)
    k = collect(keys(d))
    P_k = collect(values(d));

    fig3 = Figure(resolution = (600, 500)) ## probably you need to install this font in your system
    ax3 = Axis(fig3[1, 1], xlabel = L"k\,[\text{connectivity}]", ylabel = L"P_k", xscale=log10, yscale=log10, ylabelsize = 26,
        xlabelsize = 24, xgridstyle = :dash, ygridstyle = :dash, xtickalign = 1,
        xticksize = 5, ytickalign = 1, yticksize = 5 , xlabelpadding = 10, ylabelpadding = 10)

    sc3 = scatter!(k, P_k, label=L"\text{cell\,size}=%$(cell_size)",
        color=(:midnightblue, 0.5), strokewidth=0.5, marker=:circle, markersize=13)

    axislegend(ax3, position = :rt, bgcolor = (:grey90, 0.25));

    
    
    # Save both plots
    save("./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_all_data.png", fig1, px_per_unit=5)
    save("./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold).png", fig2, px_per_unit=5)
    save("./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_histogram.png", fig3, px_per_unit=5)

end
######################################################################################################################


######################################################################################################################
######################################################################################################################
regions = ["romania", "california", "italy", "japan" ]
for region in regions
    # connectivity_analysis_cairo(region)
    connectivity_analysis_histogram_cairo(region,5)
end
######################################################################################################################
######################################################################################################################






# function connectivity_analysis(region)
#     # Based on parameter dependency, extract which cell_size lengths are the best:
#     if region == "romania"
#         cell_sizes = [3, 4, 5];
#         # minimum_magnitudes = [0,1,2,3];
#     elseif region == "california"
#         cell_sizes = [1, 1.5, 2];
#         # minimum_magnitudes = [2,3];
#     elseif region == "italy"
#         cell_sizes = [5, 7.5, 10];
#         # minimum_magnitudes = [2,3];
#     elseif region == "japan"
#         cell_sizes = [3, 4, 5];
#         # minimum_magnitudes = [2,3,4];
#     end;

#     # Read data
#     path = "./data/"
#     filepath = path * region * ".csv"
#     df = CSV.read(filepath, DataFrame);
#     magnitude_threshold = 0.0

#     # Make path for results
#     mkpath("./results/$region")

#     # Powerlaw CCDFS and FITS
#     # All data, fit through partial
#     p1 = Plots.plot(xlabel = "k", ylabel = "P(k)")
#     # Partial data and fit, renormed
#     p2 = Plots.plot(xlabel = "k", ylabel = "P(k)")

#     for cell_size in cell_sizes
#         df, df_cubes = region_cube_split(df,cell_size=cell_size)
#         MG = create_network(df, df_cubes)
#         degrees=[]
#         for i in 1:nv(MG)
#             push!(degrees, get_prop(MG, i, :degree))
#         end

#         # Powerlaw Fit
#         fit = powlaw.Fit(degrees);
#         alpha = round(fit.alpha, digits=4)
#         xmin = round(fit.xmin, digits=4)
#         KS = round(fit.power_law.KS(data=degrees), digits=4)


#         # CCDF of truncated data (fitted), x and y values
#         x_ccdf, y_ccdf = fit.ccdf()

#         # The fit (from theoretical power_law)
#         fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
#         x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()


#         ########################################### ALL
#         # CCDF of all data scattered 
#         x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
#         Plots.scatter!(p1, x_ccdf_original_data, y_ccdf_original_data, xscale=:log10, yscale=:log10, 
#                         label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
#         # Fit through truncated data
#         # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
#         Plots.plot!(p1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, xscale=:log10, yscale=:log10, 
#                         label="", color=:red, linestyle=:dash, linewidth=3) 


#         ########################################### TRUNCATED
#         # CCDF of truncated data (fitted), the plot, (re-normed)
#         Plots.scatter!(p2, x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
        
#         # Fit through truncated data (re-normed)
#         Plots.plot!(p2, x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash) #label="power law, alpha=$(alpha)")


#     end
#     Plots.plot!(p1, size=(800,500), legend=:bottomleft)
#     Plots.savefig(p1, "./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits_all_data.png")

#     Plots.plot!(p2, size=(800,500), legend=:bottomleft)
#     Plots.savefig(p2, "./results/$region/$(region)_minmag_$(magnitude_threshold)_best_fits.png")

# end


# function connectivity_analysis_and_histogram(region, cell_size)
#     # # Based on parameter dependency, extract which cell_size lengths are the best:
#     # if region == "romania"
#     #     cell_sizes = [3, 4, 5];
#     #     # minimum_magnitudes = [0,1,2,3];
#     # elseif region == "california"
#     #     cell_sizes = [1, 1.5, 2];
#     #     # minimum_magnitudes = [2,3];
#     # elseif region == "italy"
#     #     cell_sizes = [5, 7.5, 10];
#     #     # minimum_magnitudes = [2,3];
#     # elseif region == "japan"
#     #     cell_sizes = [3, 4, 5];
#     #     # minimum_magnitudes = [2,3,4];
#     # end;

#     # Read data
#     path = "./data/"
#     filepath = path * region * ".csv"
#     df = CSV.read(filepath, DataFrame);
#     magnitude_threshold = 0.0

#     # Make path for results
#     mkpath("./results/$region")

#     # Powerlaw CCDFS and FITS
#     # All data, fit through partial
#     p1 = Plots.plot(xlabel = "k", ylabel = "P(k)")
#     # Partial data and fit, renormed
#     p2 = Plots.plot(xlabel = "k", ylabel = "P(k)")
#     # Histogram / density plot
#     p3 = Plots.plot(xlabel = "k", ylabel = "P(k)")

#     df, df_cubes = region_cube_split(df,cell_size=cell_size)
#     MG = create_network(df, df_cubes)
#     degrees=[]
#     for i in 1:nv(MG)
#         push!(degrees, get_prop(MG, i, :degree))
#     end

#     # Powerlaw Fit
#     fit = powlaw.Fit(degrees);
#     alpha = round(fit.alpha,digits=4)
#     xmin = round(fit.xmin,digits=4)
#     KS = round(fit.power_law.KS(data=degrees), digits=4)


#     # CCDF of truncated data (fitted), x and y values
#     x_ccdf, y_ccdf = fit.ccdf()

#     # The fit (from theoretical power_law)
#     fit_power_law = fit.power_law.plot_ccdf()[:lines][1]
#     x_powlaw, y_powlaw = fit_power_law[:get_xdata](), fit_power_law[:get_ydata]()


#     ########################################### ALL
#     # CCDF of all data scattered 
#     x_ccdf_original_data, y_ccdf_original_data = powlaw.ccdf(degrees)
#     Plots.scatter!(p1, x_ccdf_original_data, y_ccdf_original_data, xscale=:log10, yscale=:log10, 
#                     label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
#     # Fit through truncated data
#     # Must shift the y values from the theoretical powerlaw by the values of y of original data, but cut to the length of truncated data
#     Plots.plot!(p1, x_powlaw, y_ccdf_original_data[end-length(x_ccdf)] .* y_powlaw, xscale=:log10, yscale=:log10, 
#                     label="", color=:red, linestyle=:dash, linewidth=3) 

#     Plots.plot!(p1, size=(800,500), legend=:bottomleft)
#     Plots.savefig(p1, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_all_data.png")


#     ########################################### TRUNCATED
#     # CCDF of truncated data (fitted), the plot, (re-normed)
#     Plots.scatter!(p2, x_ccdf, y_ccdf, xscale=:log10, yscale=:log10, label="cell_size=$cell_size, alpha=$alpha, xmin=$xmin", markersize=3, alpha=0.8)
    
#     # Fit through truncated data (re-normed)
#     Plots.plot!(p2, x_powlaw, y_powlaw, xscale=:log10, yscale=:log10, label="", color=:red, linestyle=:dash) #label="power law, alpha=$(alpha)")

#     Plots.plot!(p2, size=(800,500), legend=:bottomleft)
#     Plots.savefig(p2, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold).png")


#     ########################################### HISTOGRAM (density plot?)
#     d = counter(degrees)
#     Plots.scatter!(p3, collect(keys(d)),collect(values(d)),xscale=:log10,yscale=:log10)
#     Plots.plot!(p3, size=(800,500), legend=:bottomleft)
#     Plots.savefig(p3, "./results/$region/$(region)_cell_size_$(cell_size)km_minmag_$(magnitude_threshold)_histogram.png")

# end





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




