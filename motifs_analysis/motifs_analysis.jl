#-------------------------MOTIFS FILE PROCESSING--------------------------------#

#-------------------------TOTAL / MEAN  ENERGY--------------------------------#

function total_mean_energy(motifs,df,df_cubes)
    #=
    motifs = Matrix{Int64}
    df = DataFrame
    df_cubes = DataFrame
    =#

    # STEP 1
    # Calculate total energy and mean energy only for cubes that are part of motifs
    # This is done to reduce calculations. I do not need to calculate these for each motif
    # (because, nodes are repeated in motifs.)
    # (I calculate separately, then I just add them up for each motif)

    # Get all the cubes, uniquely
    vec_motifs = unique!(vec(motifs));

    # Will apend to a dictionary: cubeIndex => [totalEnergy, meanEnergy]
    cube_energy = Dict()
    for value in vec_motifs
        # Get the cube from df_cubes
        respective_cube = df_cubes.cubeIndex[value]
        # Use the cube to get all the quakes in that cube from df
        quakesInNode = df[df.cubeIndex .== respective_cube,:];

        # Calculate total energy and mean energy
        totalEnergy = sum(quakesInNode.energyRelease)
        meanEnergy = totalEnergy / length(quakesInNode.energyRelease)

        # Push to dictionary
        cube_energy[value] = [totalEnergy, meanEnergy]
    end


    # STEP 2
    # Caclulate total energy and mean energy per each motif
    motif_energy = Dict()
    for i=1:length(motifs[:,1])
        # total energy is first in cube_energy dictionary
        total_energy_in_motif = cube_energy[motifs[i,1]][1] + 
                                cube_energy[motifs[i,2]][1] + 
                                cube_energy[motifs[i,3]][1]

        # mean energy is second in cube_energy dictionary
        mean_energy_in_motif = cube_energy[motifs[i,1]][2] + 
                                cube_energy[motifs[i,2]][2] + 
                                cube_energy[motifs[i,3]][2]

        motif_energy[i] = [total_energy_in_motif, mean_energy_in_motif]
    end


    return motif_energy

end




#-------------------------TRIANGLES--------------------------------#

# Calculate the areas per motif
function area_triangles()


end





#-------------------------TETRAHEDRONS--------------------------------#

# Calculate the volumes per motif
function volume_tetrahedrons()


end