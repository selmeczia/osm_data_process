#import raw dbf file from shp.zip (https://download.geofabrik.de/)
filename_city <- paste0(getwd(), "/unzipped_files/gis_osm_places_free_1.dbf")

allplaces_raw <- read_sf(filename_city)
allplaces_dt <- data.table(allplaces_raw)

city_types <- c("village", "town", "city")
city_db <- allplaces_dt[allplaces_dt$fclass %in% city_types]
