using CSV, DataFrames, Dates


startDate = ["-01-01", "-02-01", "-03-02", "-04-01", "-05-01", "-06-01", "-07-01", "-08-01", "-09-01", "-10-01", "-11-01", "-12-01"]
# account for february ! start from 02-01 to 03-01
endDate = ["-01-31", "-03-01", "-03-31", "-04-30", "-05-31", "-06-30", "-07-31", "-08-31", "-09-30", "-10-31", "-11-30", "-12-31"];

# Get an empty dataframe with the proper types to add to it
year = 1985
month = 1
url = "http://webservices.ingv.it/fdsnws/event/1/query?starttime=" * string(year) * startDate[month] * "T00%3A00%3A00&endtime=" * string(year) * endDate[month] * "T23%3A59%3A59&minversion=100&orderby=time-asc&timezone=UTC&format=text&limit=15000"
# put directly into dataframe. Note the delimiter:"|" and forcing the String to String
dataset = CSV.read(download(url), DataFrame, delim="|", stringtype=String, 
        select=[:Time, :Latitude, :Longitude, Symbol("Depth/Km"), :MagType, :Magnitude, :EventType], 
        types=Dict(:Time=>String))#, :Latitude=>Float64, :Longitude=>Float64, :MagType=>String, :Magnitude=>Float64, :EventType=>String)) 
# Initialize dataframe with proper columns and columns typt
italy = similar(dataset,0)


for year=1985:2023
    for month=1:12
        url = "http://webservices.ingv.it/fdsnws/event/1/query?starttime=" * string(year) * startDate[month] * "T00%3A00%3A00&endtime=" * string(year) * endDate[month] * "T23%3A59%3A59&minversion=100&orderby=time-asc&timezone=UTC&format=text&limit=15000"
        
        # download(url,filepath)
        df = CSV.read(download(url), DataFrame, delim="|", stringtype=String,
                select=[:Time, :Latitude, :Longitude, Symbol("Depth/Km"), :MagType, :Magnitude, :EventType], 
                types=Dict(:Time=>String), #, :Latitude=>Float64, :Longitude=>Float64, Symbol("Depth/Km")=>Float64, :MagType=>String, :Magnitude=>Float64, :EventType=>String)) 
                validate=false)
        append!(italy,df);
    end
end

# Turn Time into datetime
italy.Time = chop.(italy.Time, tail=3)
italy.Time = DateTime.(italy.Time)

# Select only earthquakes
italy = italy[italy.EventType .== "earthquake", :]

# Rename columns
rename!(italy,:Time => :Datetime, Symbol("Depth/Km") => :Depth, :MagType => :Magnitude_Type, :EventType => :Event_Type )

# Save to CSV
CSV.write("./data/italy.csv", italy)