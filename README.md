# Wikidata Missing Pictures (offline)

1. [Download the KMZ file](https://drive.google.com/drive/folders/0B-SI__O0UX9oeHBQQ0JNVkJaQU0?usp=sharing)
2. Load it into your GPS app
  - OsmAnd: Tap the GPX in a file explorer app such as "Amaze", select OsmAnd, choose, "Import as Favorites"
  - Maps.me: TODO
3. Go take pictures of marked places
4. Upload the pictures to Wikimedia Commons (there is [an Android app](https://commons-app.github.io) for this)

# ... or generate your own KMZ

This `generate.sh` script can generate a KMZ file containing all Wikidata items missing a picture (P18).

Before running the script, you must clone [database-of-embassies](https://github.com/nicolas-raoul/database-of-embassies) at the same level as wikidata-missing-pictures-offline, as the script uses a tool found in that project. Tested on Ubuntu, it might also work on other bash environment such as Linux and MacOS.

The source code is not complicated, so you can probably figure out how to restrict the data between two longitudes, or set language preferences, if you need to.

Loading the whole world is very slow so better restrict to the area useful to you.

# Importing into OsmAnd

1. Transfer the KMZ (or GPX) file to your file
2. Open the file
3. Choose to open it with OsmAnd
4. Accept to import as favorites
5. Better choose a different color for your normal favorites, so that you can distinguish them
