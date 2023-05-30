
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


motif = "Triangle"
for cell_size in cell_sizes
    # select target path for networks
    network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"

    for minimum_magnitude in [4, 3, 2]
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


motif = "Tetrahedron"
for cell_size in cell_sizes
    # select target path for networks
    network_target_path = "./networks/$(region)/cell_size_$(string(cell_size))km/"

    for minimum_magnitude in [4, 3, 2]
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