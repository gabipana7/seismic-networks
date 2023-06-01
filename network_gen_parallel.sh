echo `date`
julia --project networks_generator.jl california &
julia --project networks_generator.jl italy &
julia --project networks_generator.jl japan &
wait # do not return before background tasks are complete
echo `date`