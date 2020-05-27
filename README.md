# collectionbuilder-sa_draft

draft of a stand alone style collection.
uses data from [Moscon](https://www.lib.uidaho.edu/digital/moscon/), but not really customized to the collection.
Objects are simply in a folder.
Every object has an image in "thumbs" and "small" named after `objectid`, and an original object item in the root folder named after `filename` column.

## Website generation and deployment steps

### 1. Get Ready
- [create your metadata CSV file](https://collectionbuilder.github.io/docs/metadata.html)
- place your collection objects in the `<repository>/objects` directory


### 2. Set your search configuration in `config-search.csv`

[config-search.csv](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/_data/config-search.csv) defines the settings for the fields that you want indexed and displayed in search.

Example (as a table):

|field|index|display|facet|multi-valued|
|---|---|---|---|---|
title|true|true|false|false
date|true|true|false|false
description|true|false|false|false
creator|true|false|true|true
subject|true|false|true|true
location|true|false|true|true
full_text|true|false|false|false


### 3. Generate Derivatives
Use the `generate_derivatives` rake task to generate a set of images for each of your collection files.

Usage:
```
rake generate_derivatives
```

This task automatically creates `/small` and `/thumbs` subdirectories as necessary within the `objects/` directory, into which it will put the files that it generates.

The following configuration options are available:

| option | description |default value |
| --- | --- | --- |
| thumbs_size | the dimensions of the generated thumbnail images | 300x300 |
| small_size | the dimensions of the generated small images | 800x800 |
| density | the pixel density used to generate PDF thumbnails | 300 |
| missing | whether to only generate derivatives that don't already exist | true |


You can configure any or all of these options by specifying them in the rake command like so:
```
rake generate_derivatives[<thumb_size>,<small_size>,<density>,<missing>]
```
Here's an example of overriding all of the option values:
```
rake generate_derivatives[100x100,300x300,70,false]
```
It's also possible to specify individual options that you want to override, leaving the others at their defaults.
For example, if you only wanted to set `density` to `70`, you can do:
```
rake generate_derivatives[,,70]
```

### 4. Start Elasticsearch

Though this step is platform dependent, you might accomplish this by executing `elasticsearch` in a terminal.


### 5. Generate and load the Elasticsearch data

#### 5.1 Extract PDF Text
Use the `extract_pdf_text` rake task to extract the text from your collection PDFs so that we can perform full-text searches on these documents.

Usage:
```
rake extract_pdf_text 
```

#### 5.2 Generate the Search Index Data File
Use the `generate_es_bulk_data` rake task to generate a file, using the collection metadata and extracted PDF text, that can be used to populate the Elasticsearch index.

Usage:
```
rake generate_es_bulk_data
```

#### 5.3 Generate the Search Index Settings File
Use the `generate_es_index_settings` rake task to create an Elasticsearch index settings file from the configuration in `config-search.csv`.

Usage:
```
rake generate_es_index_settings
```

#### 5.4 Create the Search Index
Use the `create_es_index` rake task to create the Elasticsearch index from the index settings file.

Usage:
```
rake create_es_index
```

#### 5.5 Load Data into the Search Index
Use the `load_es_bulk_data` rake task to load the collection data into the Elasticsearch index.

Usage:
```
rake load_es_bulk_data
```

### 6. Maybe Upload Collection Objects to a Digital Ocean Space
Use the [sync-objects](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/sync-objects) script to upload the assets and their derivatives to your Digital Ocean Space
Usage:
```
sync-objects <path-to-your-assets-directory> [EXTRA "aws s3 sync" ARGS]
```
Here's a [summary of available `aws s3 sync` args](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html).

This script also requires a couple of configuration values relating to your DO Space, namely the Space name and endpoint host. These can either be specified as environment variables:
```
export DO_ENDPOINT=<endpoint-host>
export DO_SPACE=<space-name>
```
or as prefixes to the script:
```
DO_ENDPOINT=<endpoint-host> DO_SPACE=<space-name> sync-objects ...
```
