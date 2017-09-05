#!/bin/bash
#
# Generate a file containing all geographical Wikidata items that do not have an image (P18 property).
# Useful for photographers traveling to places with no network.

GPX="out.gpx"
KML="out.kml"
cat gpx-header.txt > $GPX
cat kml-header.txt > $KML

for LONGITUDE in `seq -180 0.1 179.9`; # Whole world
#for LONGITUDE in `seq 120 0.1 146`; # Taiwan + Korea + Japan
#for LONGITUDE in `seq 102 0.1 110`; # Vietnam
do

  # Add missing zero to numbers like .7
  NEXT_LONGITUDE=`echo "x=0.1 + $LONGITUDE; if(x>0 && x<1) print 0; x" | bc`

  echo $LONGITUDE
  echo $NEXT_LONGITUDE

  echo "SELECT
    ?item
    (SAMPLE(COALESCE(?en_label, ?fr_label, ?vn_label, ?item_label)) as ?label)
    (SAMPLE(?location) as ?location)
    (GROUP_CONCAT(DISTINCT ?class_label ; separator=\",\") as ?class)
  WHERE {
    SERVICE wikibase:box {
      ?item wdt:P625 ?location .
      bd:serviceParam wikibase:cornerSouthWest \"Point($LONGITUDE -90)\"^^geo:wktLiteral .
      bd:serviceParam wikibase:cornerNorthEast \"Point($NEXT_LONGITUDE 90)\"^^geo:wktLiteral .
    }
    MINUS {?item wdt:P18 ?image}
    
    MINUS {?item wdt:P582 ?endtime.}
    MINUS {?item wdt:P582 ?dissolvedOrAbolished.}
    MINUS {?item p:P31 ?instanceStatement. ?instanceStatement pq:P582 ?endtimeQualifier.}
    
    OPTIONAL {?item rdfs:label ?en_label . FILTER(LANG(?en_label) = \"en\")}
    OPTIONAL {?item rdfs:label ?fr_label . FILTER(LANG(?fr_label) = \"fr\")}
    OPTIONAL {?item rdfs:label ?vn_label . FILTER(LANG(?vn_label) = \"vn\")}
    OPTIONAL {?item rdfs:label ?item_label}

    OPTIONAL {?item wdt:P31 ?class. ?class rdfs:label ?class_label. FILTER(LANG(?class_label) = \"en\")}
  }
  GROUP BY ?item" | ../database-of-embassies/tools/query-wikidata.sh \
    | grep -i "<literal\|<uri>" | tr "\n" " " | sed -e "s/<uri>/\n<uri>/g" | grep wikidata > /tmp/items.txt

  while read ITEM; do
    URL=`echo $ITEM | sed -e "s/^<uri>//" | sed -e "s/<.*//"`
    NAME=`echo $ITEM | sed -e "s/.*<\/uri>\s*<literal[^>]*>\([^<]*\).*/\\1/"`
    LONGITUDE=`echo $ITEM | sed -e "s/.*Point(\([-0-9E.]*\) [-0-9E.]*).*/\\1/"` # E: exponent is sometimes present
    LATITUDE=`echo $ITEM | sed -e "s/.*Point([-0-9E.]* \([-0-9E.]*\)).*/\\1/"`
    TYPE=`echo $ITEM | sed -e "s/.*<literal>\([^<]*\)<\/literal>$/\\1/"`

    #echo $ITEM
    #echo $URL
    #echo $NAME
    #echo $LATITUDE
    #echo $LONGITUDE
    #echo $TYPE
    #echo ""

    if [ ! -z "$TYPE" ]
    then
      NAME="$NAME ($TYPE)"
    fi
    
    echo "<wpt lat='$LATITUDE' lon='$LONGITUDE'><name>$NAME</name><url>$URL</url></wpt>" >> $GPX
    echo "        <Placemark>
            <name>$NAME</name>
            <description>$URL</description>
            <Point>
                <coordinates>$LONGITUDE,$LATITUDE</coordinates>
            </Point>
        </Placemark>" >> $KML
  done < /tmp/items.txt
done

cat gpx-footer.txt >> $GPX
cat kml-footer.txt >> $KML

# Transform KML to KMZ per https://developers.google.com/kml/documentation/kmzarchives
rm -rf out
mkdir out
cp out.kml out/doc.kml
zip -r out out
mv out.zip out.kmz
