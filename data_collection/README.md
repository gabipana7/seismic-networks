## Data collection for different seismic regions around the globe
The interest is in the following features for each seismic event:
- datetime
- latitude
- longitude
- depth
- magnitude

### Romania

Romplus catalog available at: "http://www.infp.ro/data/romplus.txt"

- a fixed width file (.txt file) is downloaded
- file needs parsing: method - line, by line
- skip the header line and parse all the liens
- specify explicitly the columns to be selected for each data:
    - datetime [1:23]
    - latitude [38:45]
    - longitude [48:56]
    - depth [76:80]
    - magnitude [108:110]
- the resultant vectors are turned into a dataframe
- export the dataframe to csv for Data Cleaning and Exploratory Data Analysis


---
### California, USA


---
### Italy


---
### Japan


### Other?