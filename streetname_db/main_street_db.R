# This script will generate a street name database, consisting of columns:
# street name, street type, street length, city, coordinates of the center of the street, etc.

# libraries
library(sf)
library(stringi)
library(stringr)
library(data.table)

# #import raw dbf file from shp.zip (https://download.geofabrik.de/)
# Documentation:
# https://download.geofabrik.de/osm-data-in-gis-formats-free.pdf
filename <- paste0(getwd(), "/unzipped_files/gis_osm_roads_free_1.dbf")
allroads_raw <- read_sf(filename)

#remove NAs
allroads_dt <- data.table(allroads_raw)
allroads_clean <- allroads_dt[!is.na(allroads_dt$name)]

# create road type column
roadtypes <-  c('utca', 'tér', 'út', 'híd', 'sétány', 'útja', 'telep', 'sor', "köz", 'körút', 'dűlő', "körtér")

allroads_clean$name <- gsub("-"," ",allroads_clean$name)
allroads_clean$suffix <- substr(allroads_clean$name, stri_locate_last(allroads_clean$name, regex = " ")[, 1] + 1,  nchar(allroads_clean$name)) %>%
  tolower()
allroads_clean <- allroads_clean[allroads_clean$suffix %in% roadtypes]

# create length and center columns
allroads_clean$length <- st_length(allroads_clean$geometry)
allroads_clean$center <- st_centroid(allroads_clean$geometry)
allroads_clean$center_long <- st_coordinates(allroads_clean$center)[,1]
allroads_clean$center_lat <- st_coordinates(allroads_clean$center)[,2]

# create city column
# WARNING! This may take a very long time (hours) and uses a lot of RAM!
source(paste0(getwd(),"/city_db/main_city_db.R"))
allroads_clean$city <- city_db[which.min(st_distance(allroads_clean$center, city_db$geometry))]$name

# merging the two parts together
load(paste0(getwd(), "/streetname_db/part1.RData"))
load(paste0(getwd(), "/streetname_db/part2.RData"))
part_1_dt <- data.table(part_1)
part_2_dt <- data.table(part_2)
merged <- rbind(part_1_dt, part_2_dt)
merged[, "summed_length (m)" := sum(length), by = c("name", "city")]

# remove duplicate streets in the same city
ind <- duplicated(merged[,c("name", "city")])
data <- data.table(merged[!ind])

# remove suffix from street name
data$name <- str_remove(data$name, paste0(" ", data$suffix))

# order columns
col_order <- c("osm_id", "name", "suffix", "city", "summed_length (m)", 
               "maxspeed", "oneway", "bridge", "tunnel", "fclass",
               "code", "center_long", "center_lat")
streetname_db <- data[,..col_order]

# export db
export <- paste0(getwd(), "/streetname_db/export/streetname_db.csv")
write.csv2(streetname_db, export, row.names = F)

#TODO
# budapesti utcákat fixelni



