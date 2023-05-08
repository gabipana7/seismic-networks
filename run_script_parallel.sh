echo `date`
julia --project motifs_triangle_analysis_all.jl california meanenergy &
julia --project motifs_triangle_analysis_all.jl japan meanenergy &
julia --project motifs_triangle_analysis_all.jl italy meanenergy &
julia --project motifs_triangle_analysis_all.jl romania meanenergy &
# julia --project motifs_tetrahedron_analysis_all.jl california &
# julia --project motifs_tetrahedron_analysis_all.jl japan &
# julia --project motifs_tetrahedron_analysis_all.jl italy &
# julia --project motifs_tetrahedron_analysis_all.jl romania &
wait # do not return before background tasks are complete
echo `date`