using HTTP, Gumbo, Cascadia
using ZipFile

#######################################
# STEP 1
# Automatically find downloadable links 
#######################################
function parse_url(url_to_parse)
    # Make HTTP GET request to the URL and get the response content
    response = HTTP.get(url_to_parse)
    content = String(response.body)

    # Parse the HTML content using Gumbo
    parsed_html = parsehtml(content)

    # Select the body
    body = parsed_html.root[2];

    # Select all links from the body of the HTML page
    all_links = eachmatch(Cascadia.Selector("a"), body)

    # Filter only links that go to a download, results in HTMLElements
    downloadable_links = filter(link -> occursin(".zip", lowercase(link.attributes["href"])) || occursin(".tar", lowercase(link.attributes["href"])), all_links)

    # Get the actual links
    hrefs = [link.attributes["href"] for link in downloadable_links];

    return(hrefs)
end


#########################################
# STEP 2
# Use links to recursively download files 
#########################################
function download_from_links(hrefs, download_target_path)
    corelink = "https://www.data.jma.go.jp/svd/eqev/data/bulletin/"
    download_urls = corelink .* hrefs
    mkpath(download_target_path)
    HTTP.download.(download_urls, download_target_path)
end


#########################################
# STEP 3
# Unzip files 
#########################################
function unzip_files(folder_path::AbstractString, destination_path::AbstractString)
    # make destination path
    mkpath(destination_path)
    # Get a list of all the files in the folder
    file_list = readdir(folder_path)

    # Filter the list to only include .zip files
    zip_files = filter(x -> occursin(r"\.zip$", x), file_list)

    # Unzip each .zip file in the folder
    for file in zip_files
        # Construct the path to the .zip file
        zip_path = joinpath(folder_path, file)

        # Open the .zip file
        zf = ZipFile.Reader(zip_path)

        # Loop over each file in the .zip file
        for file_in_zip in zf.files
            # Get the name of the file in the .zip file
            file_name = basename(file_in_zip.name)

            # Construct the path to extract the file to
            extract_path = joinpath(destination_path, file_name)

            # Extract the file to the folder
            write(extract_path, read(file_in_zip, String))
        end

        # Close the .zip file
        close(zf)
    end
end


####################################################DEMO####################################################
#######################################
# STEP 1
# Automatically find downloadable links 
#######################################
url_to_parse = "https://www.data.jma.go.jp/svd/eqev/data/bulletin/hypo.html"
hrefs = parse_url(url_to_parse)


#########################################
# STEP 2
# Use links to recursively download files 
#########################################
download_target_path = "./downloads"
download_from_links(hrefs, download_target_path)


#########################################
# STEP 3
# Unzip files 
#########################################
download_target_path = "./downloads"
unzip_destination_path = "./japan_data"
unzip_files(download_target_path, unzip_destination_path)
####################################################DEMO####################################################


# Extra - rm downloads
# Remove downloaded and extracted data
rm("downloads", recursive=true)