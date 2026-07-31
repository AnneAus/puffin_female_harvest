# Fetches high-resolution Faroe Islands coastline from OpenStreetMap (via Overpass)
# and caches it locally. rnaturalearthhires (1:10m) over-simplifies small islands
# like the Faroes at map1's zoom level, so this replaces that source for map1.
# Re-run only if the cached file needs refreshing - not sourced by the manuscript.
library(osmdata)
library(sf)

bbox <- c(-8.2, 61.1, -5.3, 62.6)  # xmin, ymin, xmax, ymax, with a little padding

coast <- opq(bbox = bbox, timeout = 60) |>
  add_osm_feature(key = "natural", value = "coastline") |>
  osmdata_sf()

faroe_coastline <- coast$osm_lines

st_write(faroe_coastline, "../data/faroe_coastline.gpkg", delete_dsn = TRUE)
