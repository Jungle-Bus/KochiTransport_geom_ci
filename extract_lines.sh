#!/bin/bash

set -ev

wget "https://app.interline.io/osm_extracts/download_latest?string_id=kochi_india&data_format=pbf&api_token=$INTERLINE_EXTRACTS_API_KEY" --no-verbose --output-document=data.osm.pbf 2>&1

osm_transit_extractor -i data.osm.pbf

mkdir output

cat osm-transit-extractor_lines.csv |xsv search -s mode 'ferry|bus' |xsv search -s shape '^$' -v > lines_with_shapes.csv
ogr2ogr output/lines.geojson -dialect sqlite -sql "SELECT *, GeomFromText(shape) FROM lines_with_shapes" lines_with_shapes.csv -a_srs "WGS84"

cat lines_with_shapes.csv |xsv select '!shape' > output/lines.csv

cp osm-transit-extractor_stop_points.csv output/stops.csv

ogr2ogr output/stops.geojson -dialect sqlite -sql "SELECT *, GeomFromText('POINT(' || lon || ' ' || lat || ')') FROM stops" output/stops.csv -a_srs "WGS84"
