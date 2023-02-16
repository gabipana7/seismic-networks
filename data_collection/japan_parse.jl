using CSV, DataFrames, Dates

#######################################
# STEP 1
# Read each file, line by line 
#######################################
function parse_data_files(filepaths)
    identifier = []
    datetime = []
    latitude_deg, latitude_min=  [],[]
    longitude_deg, longitude_min =  [],[]
    depth = []
    magnitude1 = []
    magnitude1_type = []

    # 5:end -> 1983 - 2020
    for path in filepaths[5:end]
        open(path) do io
            # skip the first line
            # line = readline(io)
            while true
                # start reading the lines
                line = readline(io)
                # detect the end of the line
                line == "" && break
                # push to the vectors, the characters based on the position in the text file
                # push!(date,  strip(line[1:10]))
                push!(identifier,  strip(line[1:1]))

                # DATETIME PROCESSING 
                year = strip(line[2:5])
                month = strip(line[6:7])
                day = strip(line[8:9])
                hour = strip(line[10:11])
                minute = strip(line[12:13])
                second = strip(line[14:17])
                push!(datetime,  year * "/" * month * "/" * day * " " * hour * ":" * minute * ":" * string(parse(Float64,second)/100))

                # Latitude
                push!(latitude_deg,strip(line[22:24]) )
                push!(latitude_min, strip(line[25:28]))
                
                # Longitude
                push!(longitude_deg, strip(line[33:36]))
                push!(longitude_min, strip(line[37:40]))

                # Depth
                push!(depth, strip(line[45:49]))

                # Magnitude
                push!(magnitude1, strip(line[53:54]))
                push!(magnitude1_type, strip(line[55:55]))
                # push!(magnitude2, parse(Float64, strip(line[56:57])))
                # push!(magnitude2_type, strip(line[57:58]))
            end
        end
    end

    df = DataFrame(Identifier=identifier,
                    Datetime=datetime, 
                    Latitude_degree=latitude_deg, Latitude_minute=latitude_min, 
                    Longitude_degree=longitude_deg, Longitude_minute=longitude_min,
                    Depth=depth,
                    Magnitude=magnitude1, Magnitude_type=magnitude1_type)



    ####################################################
    # STEP 1.2
    # Some preprocessing -> keep Japan, eliminate emptys 
    ####################################################

    # Get Only Japan data 
    df = df[df.Identifier .== "J",:]

    # Eliminate empty strings data
    df = df[all.(!=(""), eachrow(df)), :]

    return(df)
end


####################################################
# STEP 2
# Processing -> manage long, lat, dep and mag
####################################################

# Parser for strings to turn into float and process
function parse_float(value)
    try
        float_value = parse(Float64, value)
        return(float_value)
    catch e
        return(missing)
    end
end


function process_df(japan)
    latitude = []
    longitude = []
    depth = []
    magnitude =[]

    for i in eachindex(japan.Identifier)
        # Latitude processing
        lat_deg = parse_float(japan.Latitude_degree[i])
        # Minutes are in the form XXXX, but represent actually XX.XX
        # Divide XXXX by 100
        lat_min = parse_float(japan.Latitude_minute[i]) / 6000

        push!(latitude, round((lat_deg + lat_min), digits=4))

        # Longitude processing
        lon_deg = parse_float(japan.Longitude_degree[i])
        lon_min = parse_float(japan.Longitude_minute[i]) / 6000

        push!(longitude, round((lon_deg + lon_min), digits=4))

        # Depth processing
        dep = parse_float(japan.Depth[i]) / 100
        push!(depth, dep )

        # Magnitude
        mag = parse_float(japan.Magnitude[i]) / 10
        push!(magnitude, mag)
    end

    # do not forget about datetime
    datetime = []
    dateformat = dateformat"yyyy/mm/dd HH:MM:SS.ss"
    datetime = DateTime.(japan.Datetime, dateformat);

    df_new = DataFrame(Datetime=datetime, 
                    Latitude=latitude, Longitude=longitude, Depth=depth,
                    Magnitude=magnitude, Magnitude_type=japan.Magnitude_type)


    # Drop missing in new, processed dataframe
    dropmissing!(df_new)

    # Positive magnitude
    df_new = df_new[df_new.Magnitude .> 0.0,:]

    return(df_new)
end


####################################################DEMO####################################################
#######################################
# STEP 1
# Read each file, line by line 
#######################################
unzip_destination_path = "./japan_data"
filepaths = readdir(unzip_destination_path,join=true)
japan_preprocessed = parse_data_files(filepaths)


####################################################
# STEP 2
# Processing -> manage long, lat, dep and mag
####################################################
japan = process_df(japan_preprocessed)


# Write CSV with data
CSV.write("./data/japan.csv", japan)


# Extra
# remove unzipped files after loading and processing
rm("japan_data", recursive=true)
