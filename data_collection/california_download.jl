using CSV, DataFrames, Dates
using Tar, CodecZlib

# Connect to file and download
url = "https://service.scedc.caltech.edu/ftp/catalogs/SCEC_DC/SCEDC_catalogs.tar.gz"
download(url,"./california.tar.gz")

# Extract archive
open(GzipDecompressorStream, "./california.tar.gz") do io
    Tar.extract(io, "output")
end;


# Declare types of the needed columns
datetime = Vector{String}()
latitude, longitude, depth =  Vector{Float64}(), Vector{Float64}(), Vector{Float64}()
magnitude =  Vector{Float64}()
magnitude_type = Vector{String}()
event_type = Vector{String}();

for year=1932:2023
    filename="./output/SCEC_DC/" * string(year) *  ".catalog"
    open(filename) do io
        # Skip first 10 lines
        for i=1:10
            line = readline(io)
            # println(line)
        end
        # Parse all lines until you get an empty line (skip last 2 lines)
        while true
            line = readline(io)
            # detect the end of the line
            line == "" && break 
            # push to the vectors, the characters based on the position in the text file
            # push!(date,  strip(line[1:10]))
            push!(datetime,  strip(line[1:22]))
            push!(event_type,  strip(line[24:25]))
            push!(magnitude, parse(Float64, strip(line[30:33])))
            push!(magnitude_type,strip(line[35:37]))
            push!(latitude, parse(Float64,strip(line[40:45])))
            push!(longitude, parse(Float64, strip(line[47:54])))
            push!(depth, parse(Float64, strip(line[56:60])))
    
        end
    end
end

# Handling improper second formatting in original data
for i in eachindex(datetime)
    # try turning string into datetime
    try
        element_date = DateTime.(datetime[i],dateformat)
    # catch the element that gives error
    catch e
        # collect each character of the string
        as = collect(datetime[i])
        # we know that the second gives problem; second is in 18 position
        # seconds formated as "60", not possible. change to 50
        as[18] = '5'
        # join back the characters into string and modify in the original vector
        datetime[i] = join(as)
    end
end

# initialize dataframe
df = DataFrame(Datetime=datetime, 
        Latitude=latitude, Longitude=longitude, Depth=depth,
        Magnitude=magnitude, Event_Type=event_type, Magnitude_Type=magnitude_type);

# Turn into datetime
dateformat = dateformat"yyyy/mm/dd HH:MM:SS.ss"
df.Datetime = DateTime.(df.Datetime, dateformat);

# Filter event types to earthquake and magnitudes larger than 0
california = df[(df.Event_Type .== "eq") .& (df.Magnitude .> 0.0),:];


# Save CSV
CSV.write("./data/california.csv", california)

# Remove downloaded and extracted data
rm("output", recursive=true)
rm("california.tar.gz")