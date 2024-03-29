#!/bin/bash
#
# Generate a file containing all geographical Wikidata items that do not have an image (P18 property).
# Useful for photographers traveling to places with no network.

#FILENAME=world
#MIN_LONGITUDE=-180
#MAX_LONGITUDE=179
#MIN_LATITUDE=-90
#MAX_LATITUDE=89

#FILENAME=java-bali
#MIN_LONGITUDE=105.1
#MAX_LONGITUDE=115.7
#MIN_LATITUDE=-8.9
#MAX_LATITUDE=-5.8

#FILENAME=vladivostok
#MIN_LONGITUDE=130.4
#MAX_LONGITUDE=136.2
#MIN_LATITUDE=42.2
#MAX_LATITUDE=46.1

#FILENAME=maldives
#MIN_LONGITUDE=71.9
#MAX_LONGITUDE=74
#MIN_LATITUDE=-1
#MAX_LATITUDE=7.4

#FILENAME=takayama
#MIN_LONGITUDE=136.8
#MAX_LONGITUDE=137.4
#MIN_LATITUDE=36.0
#MAX_LATITUDE=36.4

#FILENAME=mokpo
#MIN_LONGITUDE=125
#MAX_LONGITUDE=127
#MIN_LATITUDE=32.8
#MAX_LATITUDE=35.2

#FILENAME=bangkok
#MIN_LONGITUDE=100.4
#MAX_LONGITUDE=100.8
#MIN_LATITUDE=13.6
#MAX_LATITUDE=13.9

FILENAME=khaoyai
MIN_LONGITUDE=100.8
MAX_LONGITUDE=102
MIN_LATITUDE=14
MAX_LATITUDE=14.9

###########################################################
GPX="$FILENAME.gpx"
KML="$FILENAME.kml"
CLASSES="/tmp/classes.txt"
CLASSES_STATISTICS="classes-statistics.txt"
cat gpx-header.txt > $GPX
cat kml-header.txt > $KML
> $CLASSES
> $CLASSES_STATISTICS

INCREMENT=1
for LONGITUDE in `seq $MIN_LONGITUDE $INCREMENT $MAX_LONGITUDE`;
do
  #echo "long loop $LONGITUDE"
  # Add missing zero to numbers like .7
  NEXT_LONGITUDE=`echo "x=$INCREMENT + $LONGITUDE; if(x>0 && x<1) print 0; x" | bc`

  for LATITUDE in `seq $MIN_LATITUDE $INCREMENT $MAX_LATITUDE`;
  do
    #echo "lat loop $LATITUDE"
    # Add missing zero to numbers like .7
    NEXT_LATITUDE=`echo "x=$INCREMENT + $LATITUDE; if(x>0 && x<1) print 0; x" | bc`

    echo "Longitudes: $LONGITUDE -> $NEXT_LONGITUDE Latitudes: $LATITUDE -> $NEXT_LATITUDE"

    echo "SELECT
      ?item
      (SAMPLE(COALESCE(?en_label, ?fr_label, ?id_label, ?item_label)) as ?label)
      (SAMPLE(?location) as ?location)
      (GROUP_CONCAT(DISTINCT ?class_label ; separator=\",\") as ?class)
    WHERE {
      SERVICE wikibase:box {
        ?item wdt:P625 ?location .
        bd:serviceParam wikibase:cornerSouthWest \"Point($LONGITUDE $LATITUDE)\"^^geo:wktLiteral .
        bd:serviceParam wikibase:cornerNorthEast \"Point($NEXT_LONGITUDE $NEXT_LATITUDE)\"^^geo:wktLiteral .
      }
      MINUS {?item wdt:P18 ?image}
    
      MINUS {?item wdt:P582 ?endtime.}
      MINUS {?item wdt:P582 ?dissolvedOrAbolished.}
      MINUS {?item p:P31 ?instanceStatement. ?instanceStatement pq:P582 ?endtimeQualifier.}
    
      OPTIONAL {?item rdfs:label ?en_label . FILTER(LANG(?en_label) = \"en\")}
      OPTIONAL {?item rdfs:label ?fr_label . FILTER(LANG(?fr_label) = \"fr\")}
      OPTIONAL {?item rdfs:label ?vn_label . FILTER(LANG(?id_label) = \"id\")}
      OPTIONAL {?item rdfs:label ?item_label}

      OPTIONAL {?item wdt:P31 ?class. ?class rdfs:label ?class_label. FILTER(LANG(?class_label) = \"en\")}
    }
    GROUP BY ?item" | ./query-wikidata.sh \
      | grep -i "<literal\|<uri>" | tr "\n" " " | sed -e "s/<uri>/\n<uri>/g" | grep wikidata > /tmp/items.txt

    while read ITEM; do
      ITEM_URL=`echo $ITEM | sed -e "s/^<uri>//" | sed -e "s/<.*//"`
      ITEM_NAME=`echo $ITEM | sed -e "s/.*<\/uri>\s*<literal[^>]*>\([^<]*\).*/\\1/"`
      ITEM_LONGITUDE=`echo $ITEM | sed -e "s/.*Point(\([-0-9E.]*\) [-0-9E.]*).*/\\1/"` # E: exponent is sometimes present
      ITEM_LATITUDE=`echo $ITEM | sed -e "s/.*Point([-0-9E.]* \([-0-9E.]*\)).*/\\1/"`
      ITEM_CLASS=`echo $ITEM | sed -e "s/.*<literal>\([^<]*\)<\/literal>$/\\1/"`

      #echo $ITEM
      #echo $ITEM_URL
      #echo $ITEM_NAME
      #echo $ITEM_LATITUDE
      #echo $ITEM_LONGITUDE
      #echo $ITEM_CLASS
      #echo ""

      if [ ! -z "$ITEM_CLASS" ]
      then
        ITEM_NAME="$ITEM_NAME ($ITEM_CLASS)"
        echo $ITEM_CLASS >> $CLASSES
      fi
      
      echo "<wpt lat='$ITEM_LATITUDE' lon='$ITEM_LONGITUDE'><name>$ITEM_NAME</name><url>$ITEM_URL</url></wpt>" >> $GPX
      echo "<Placemark><name>$ITEM_NAME</name><description>$ITEM_URL</description><Point><coordinates>$ITEM_LONGITUDE,$ITEM_LATITUDE</coordinates></Point></Placemark>" >> $KML
    done < /tmp/items.txt
  done
done

echo "Removing duplicate lines"
#TODO le probleme avec ca c'est que ca trie aussi le header, donc il faudrait d'abord creer les listes de points, les trier, et ensuite concatener avec header/footer
sort -u $GPX -o $GPX
sort -u $KML -o $KML

cat gpx-footer.txt >> $GPX
cat kml-footer.txt >> $KML

# Transform KML to KMZ per https://developers.google.com/kml/documentation/kmzarchives
DIRECTORY=wmpo # Any name is OK
rm -rf $DIRECTORY
mkdir $DIRECTORY
cp $FILENAME.kml $DIRECTORY/doc.kml
zip -r $DIRECTORY $DIRECTORY
mv $DIRECTORY.zip $FILENAME.kmz
rm -rf $DIRECTORY

xmllint --noout $KML
xmllint --noout $GPX

# Compute class statistics.
cat $CLASSES | tr "," "\n" | sort | uniq -c | sort -nr > $CLASSES_STATISTICS
