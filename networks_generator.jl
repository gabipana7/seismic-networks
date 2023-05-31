using CSV, DataFrames, Dates
using PyCall

include("./src/cubes.jl")
include("./src/network.jl")

# Read data
path = "./data/"
region = "japan"
filepath = path * region * ".csv"

df = CSV.read(filepath, DataFrame);


# Based on parameter dependency, extract which cell_size lengths are the best:

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

if region == "romania"
    cell_sizes = [3.5, 4.5, 5.5];
    minimum_magnitudes = [0,1,2,3];
elseif region == "italy"
    cell_sizes = [4.0, 4.5, 5.5, 6.0];
    minimum_magnitudes = [2,3];
elseif region == "japan"
    cell_sizes = [2.5, 3.5];
    minimum_magnitudes = [2,3,4,5];
end


#######################################################################################################
### NETWORKS
#######################################################################################################

for cell_size in cell_sizes
    # Make target path for results
    network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
    mkpath(network_target_path)

    for minimum_magnitude in [0, 1, 2, 3, 4]
        # filter database based on minimum Magnitude
        df_filtered = df[df.Magnitude .> minimum_magnitude,:] 

        # Split into cubes
        df_filtered, df_filtered_cubes = region_cube_split(df_filtered,cell_size=cell_size,energyRelease=true);

        # Create network
        MG = create_network(df_filtered, df_filtered_cubes)
        # connectivity = degree(MG);

        # Collect edge list for nemomap
        df_filtered_edge_list = collect(edges(MG)) |> DataFrame;
        
        # Choose filename
        network_filename = "$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).txt"

        # Save to path (defined earlier) with proper filename
        CSV.write(network_target_path * network_filename, df_filtered_edge_list, delim=" ", header=false);
    end
end



