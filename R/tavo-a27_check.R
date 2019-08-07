# tavo-a27_check.R
# Functions for checking integrity of TAVO A27 data

library("tidyverse")
library("sf")
library("rnaturalearth")
library("crayon")

# Checks whether coordinates fall within the borders of the country the site is
# supposed to be in.
check_country <- function(tavo_file = "tavo-a27.csv") {
  read_csv(tavo_file, col_types = cols()) %>% 
    rename(expected_country = country) %>% 
    drop_na(latitude, longitude) %>% 
    st_as_sf(crs = 4326, coords = c("longitude", "latitude"), remove = FALSE,
             agr = "constant") %>% 
    st_transform(crs = 3395) ->
    tavo
  
  ne_countries(continent = "asia", returnclass = "sf") %>% 
    st_transform(crs = 3395) %>% 
    select(name) %>% 
    mutate(name = recode(name, 
                         Armenia = "Soviet Union",
                         Azerbaijan = "Soviet Union",
                         Georgia = "Soviet Union",
                         Kazakhstan = "Soviet Union",
                         Kyrgyzstan = "Soviet Union",
                         Russia = "Soviet Union",
                         Tajikistan = "Soviet Union",
                         Turkmenistan = "Soviet Union",
                         Uzbekistan = "Soviet Union",
                         Palestine = "Israel", # :/
                         `United Arab Emirates` = "UAE")) %>% 
    group_by(name) %>% 
    summarise() ->
    countries
  st_agr(countries) <- "constant"
  
  st_intersection(tavo, countries) %>% 
    select(id, site, expected_country, coord_country = name, latitude, longitude, coord_source) %>% 
    filter(expected_country != coord_country) ->
    mismatches
  
  if (nrow(mismatches) == 0) {
    cat(green("All coordinates match reported countries."))
    return(NULL)
  } else {
    cat(red(nrow(mismatches), "coordinates do not match reported countries.\n"))
    return(as_tibble(mismatches))
  }
}
