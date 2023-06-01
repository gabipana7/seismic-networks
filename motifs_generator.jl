using CSV, DataFrames, Dates
using PyCall

# include("./src/cubes.jl")
# include("./src/network.jl")
# include("./src/motifs_discovery.jl")
# include("./src/motifs_analysis.jl")


#######################################################################################################
### MOTIFS
#######################################################################################################

# Define workind directory and path to nemopmap
scriptdir = @__DIR__ 
# for windows
# nemomapdir = scriptdir * "\\src\\nemomap"
nemomapdir = scriptdir * "/src/nemomap"
pushfirst!(PyVector(pyimport("sys")."path"), nemomapdir)

# Include motifsdiscovery python code
@pyinclude("./src/nemomap/motifsdiscovery.py")

region = "california"

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
    minimum_magnitudes = [4,3,2,1,0]; #[4,3,2,1,0];
elseif region == "california"
    cell_sizes = [1.0, 1.5, 2.0];
    minimum_magnitudes = [1,0]; #[4,3,2,1,0];
elseif region == "italy"
    cell_sizes = [4.0, 4.5, 5.5, 6.0];
    minimum_magnitudes = [1,0]; # [4,3,2,1,0];
elseif region == "japan"
    cell_sizes = [3.0, 4.0, 5.0]; 
    minimum_magnitudes = [5]; #[5,4,3,2];
end



motif = "Triangle"
for cell_size in cell_sizes
    # select target path for networks
    network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"

    for minimum_magnitude in minimum_magnitudes
        network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
        network_filename = "$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).txt"
        inputName = network_target_path * network_filename
        queryName = "query$(motif).txt"

        stats = py"getMotif"(inputName,queryName)

        py"""
        import ast, os, csv

        fileMotif=open("./output.txt")
        linesMotif = fileMotif.readlines()

        fileMotif.close()
        os.remove('output.txt')

        # Properly evaluate the Lines to get the Lists
        motifNodes=[]
        for item in linesMotif:
            motifNodes.append(ast.literal_eval(item))

        newmotifs=[]
        for motifs in motifNodes:
            res = [eval(i) for i in motifs]
            newmotifs.append(res)

        with open("output.csv", "w", newline='') as f:
            wr = csv.writer(f)
            wr.writerows(newmotifs)   
        """
        # stats =  motifs_discovery(inputName,queryName)

        # Move csv and rename
        motif_filename = "motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).csv"
        mv("output.csv", network_target_path * motif_filename)

    end
end



# motif = "Tetrahedron"
# for cell_size in cell_sizes
#     # select target path for networks
#     network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"

#     for minimum_magnitude in minimum_magnitudes
#         network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
#         network_filename = "$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).txt"
#         inputName = network_target_path * network_filename
#         queryName = "query$(motif).txt"

#         stats = py"getMotif"(inputName,queryName)

#         py"""
#         import ast, os, csv

#         fileMotif=open("./output.txt")
#         linesMotif = fileMotif.readlines()

#         fileMotif.close()
#         os.remove('output.txt')

#         # Properly evaluate the Lines to get the Lists
#         motifNodes=[]
#         for item in linesMotif:
#             motifNodes.append(ast.literal_eval(item))

#         newmotifs=[]
#         for motifs in motifNodes:
#             res = [eval(i) for i in motifs]
#             newmotifs.append(res)

#         with open("output.csv", "w", newline='') as f:
#             wr = csv.writer(f)
#             wr.writerows(newmotifs)   
#         """
#         # stats =  motifs_discovery(inputName,queryName)

#         # Move csv and rename
#         motif_filename = "motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).csv"
#         mv("output.csv", network_target_path * motif_filename)

#     end
# end










# #######################################################################################################
# # TESTS #

# motif = "Triangle"
# cell_size = 5
# minimum_magnitude = 3

# network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"
# network_filename = "$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).txt"
# inputName = network_target_path * network_filename
# queryName = "query$(motif).txt"


# # Define workind directory and path to nemopmap
# scriptdir = @__DIR__ 
# nemomapdir = scriptdir * "\\src\\nemomap"
# pushfirst!(PyVector(pyimport("sys")."path"), nemomapdir)

# stats =  motifs_discovery(inputName,queryName)

# # Move csv and rename
# motif_filename = "motif$(motif)_$(region)_cell_size_$(string(cell_size))km_minmag_$(string(minimum_magnitude)).csv"
# mv("output.csv", network_target_path * motif_filename)

# # TESTS #
# #######################################################################################################