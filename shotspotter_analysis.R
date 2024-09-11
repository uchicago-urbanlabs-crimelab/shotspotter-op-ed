setwd(dirname(rstudioapi::getSourceEditorContext()$path))

library(data.table)
library(lubridate)
library(arrow)
library(sf)
library(rdrobust)
library(dplyr)
library(yaml)

# Load config
config = yaml.load_file('config.yaml')

### Victim-level information

# Load Victims of Homicides and Non-Fatal Shootings
victim_data = data.table(read_feather('data/homicides_nfs_vics_20240904.feather'))

# Limit years
victim_data = victim_data[year(date) %in% config$min_shooting_year:config$max_shooting_year, ]

# Drop missing location data
victim_data = victim_data[!is.na(latitude) & !is.na(longitude), ]

# Limit to shootings
shooting_victim_data = victim_data[gunshot_injury_i == 'YES', ]

# Identify location of shooting
shooting_victim_data[, outdoor_shooting := ifelse(location_description %in% config$outdoor_locations, 1, 0)]
shooting_victim_data[, indoor_outdoor_shooting := ifelse(location_description %in% config$indoor_outdoor_locations, 1, 0)]

# Limit based on location of shooting
shooting_victim_data = shooting_victim_data[eval(str2expression(config$location_logic)), ]

# Create fatal shooting indicator
shooting_victim_data[, fatal_shooting := ifelse(victimization_primary == 'HOMICIDE', 1, 0)]

# Add treatment district indicator
shooting_victim_data[, treat := ifelse(district %in% config$shotspotter_districts, 1, 0)]


### District-level information 

# Read in district shapefile
district_shapefile = st_read('data/Police Districts (current).geojson')
district_shapefile = district_shapefile[district_shapefile$dist_num != '31', ]
district_shapefile$treat = ifelse(district_shapefile$dist_num %in% config$shotspotter_districts, 1, 0)

### Convert shooting victim data to spatial data
shooting_victim_sf = st_as_sf(shooting_victim_data, coords = c("longitude", "latitude"), crs = 4326)

# Calculate distance from shootings to T/C boundary
# Separately for north + south study districts
shooting_victim_list = list()
for (d in list(config$north_srdd_study_districts, config$south_srdd_study_districts)) {
  
  # Limit shapefile to relevant study districts
  district_subset = district_shapefile %>% 
    filter(dist_num %in% d) %>% 
    group_by(treat) %>% 
    summarize(geometry = st_union(geometry))
  
  # Extract boundary between treatment and control districts
  treatment_control_boundary = st_intersection(st_boundary(district_subset)$geometry[1], st_boundary(district_subset)$geometry[2])
  
  # Limit shooting victim data to relevant study districts
  shooting_subset = shooting_victim_sf %>% 
    filter(district %in% d)
  
  # Calculate distance between shootings and T/C boundary
  shooting_subset$dist = st_distance(shooting_subset, treatment_control_boundary)
  
  # Store results
  shooting_victim_list[[paste0(d, collapse = ',')]] = data.table(shooting_subset)

}
full_shooting_victim = rbindlist(shooting_victim_list)

# Adjust distance in control group
full_shooting_victim[, distance := as.numeric(ifelse(treat == 0, -1*dist, dist))]


### Run regression

# Split sample into post- and pre-treatment data
post_reg_dt = full_shooting_victim[date >= date(config$last_shotspotter_implementation_date), ]
pre_reg_dt = full_shooting_victim[date < date(config$first_shotspotter_implementation_date)]

# Run RDD
rdd_output = rdrobust(y = post_reg_dt$fatal_shooting,
                      x = post_reg_dt$distance,
                      c = 0,
                      p = 1,
                      q = 2,
                      kernel = "triangular",
                      all = TRUE)
summary(rdd_output)

rdd_output = rdrobust(y = pre_reg_dt$fatal_shooting,
                      x = pre_reg_dt$distance,
                      c = 0,
                      p = 1,
                      q = 2,
                      kernel = "triangular",
                      all = TRUE)
summary(rdd_output)
