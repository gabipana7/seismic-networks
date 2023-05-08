using CSV, DataFrames, Dates
using PyCall

include("./src/cubes.jl")
include("./src/network.jl")

# Read data
path = "./data/"
region = "japan"
filepath = path * region * ".csv"

df = CSV.read(filepath, DataFrame);


# Based on parameter dependency, extract which side lengths are the best:
if region == "romania"
    sides = [3, 4, 5];
elseif region == "california"
    sides = [1.5, 2];
elseif region == "italy"
    sides = [5, 7.5, 10];
elseif region == "japan"
    sides = [3, 4, 5];
end



#######################################################################################################
### NETWORKS
#######################################################################################################

for side in sides
    # Make target path for results
    network_target_path = "./networks/$(region)/side_$(string(side))km/"
    mkpath(network_target_path)

    for minimum_magnitude in [0, 1, 2, 3, 4]
        # filter database based on minimum Magnitude
        df_filtered = df[df.Magnitude .> minimum_magnitude,:] 

        # Split into cubes
        df_filtered, df_filtered_cubes = region_cube_split(df_filtered,side=side,energyRelease=true);

        # Create network
        MG = create_network(df_filtered, df_filtered_cubes)
        # connectivity = degree(MG);

        # Collect edge list for nemomap
        df_filtered_edge_list = collect(edges(MG)) |> DataFrame;
        
        # Choose filename
        network_filename = "$(region)_side_$(string(side))km_minmag_$(string(minimum_magnitude)).txt"

        # Save to path (defined earlier) with proper filename
        CSV.write(network_target_path * network_filename, df_filtered_edge_list, delim=" ", header=false);
    end
end



