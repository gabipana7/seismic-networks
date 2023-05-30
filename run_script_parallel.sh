echo `date`
# julia --project motifs_analysis_all_data.jl romania totalenergy &
# julia --project motifs_analysis_all_data.jl romania meanenergy &
# julia --project motifs_analysis_all_data.jl california meanenergy &
julia --project motifs_analysis_all_data.jl japan meanenergy &
julia --project motifs_analysis_all_data.jl italy meanenergy &
# julia --project motifs_analysis_all_data.jl california totalenergy &
julia --project motifs_analysis_all_data.jl japan totalenergy &
julia --project motifs_analysis_all_data.jl italy totalenergy &
wait # do not return before background tasks are complete
echo `date`