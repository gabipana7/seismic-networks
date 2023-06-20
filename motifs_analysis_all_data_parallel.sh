echo `date`
# julia --project motifs_analysis_all_data.jl Triangle romania totalenergy &
# julia --project motifs_analysis_all_data.jl Triangle romania meanenergy &
# julia --project motifs_analysis_all_data.jl Triangle california totalenergy &
# julia --project motifs_analysis_all_data.jl Triangle california meanenergy &
# julia --project motifs_analysis_all_data.jl Triangle italy totalenergy &
# julia --project motifs_analysis_all_data.jl Triangle italy meanenergy &
# julia --project motifs_analysis_all_data.jl Triangle japan totalenergy &
# julia --project motifs_analysis_all_data.jl Triangle japan meanenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron romania totalenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron romania meanenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron california totalenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron california meanenergy &
julia --project motifs_analysis_all_data.jl Tetrahedron italy totalenergy &
julia --project motifs_analysis_all_data.jl Tetrahedron italy meanenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron japan totalenergy &
# julia --project motifs_analysis_all_data.jl Tetrahedron japan meanenergy &
wait # do not return before background tasks are complete
echo `date`