using PyCall

### Julia wrapper on nemomap Python 
function motifs_discovery(inputName,queryName)

    # Define workind directory and path to nemopmap
    scriptdir = @__DIR__ 
    nemomapdir = scriptdir * "\\src\\nemomap"
    pushfirst!(PyVector(pyimport("sys")."path"), nemomapdir)

    # Include motifsdiscovery python code
    @pyinclude("./src/nemomap/motifsdiscovery.py")
    
    return py"getMotif"(inputName,queryName)
end