# collectionbuilder-sa_draft

draft of a stand alone style collection.
uses data from [Moscon](https://www.lib.uidaho.edu/digital/moscon/), but not really customized to the collection.
Objects are simply in a folder.
Every object has an image in "thumbs" and "small" named after `objectid`, and an original object item in the root folder named after `filename` column.


## Website generation and deployment steps

### 0. Prerequisites

All of the files in `scripts/` that we use to complete the following steps are executed as a bash shell or ruby script, with some additional software or service dependencies as detailed below:

| name | type | software dependencies | service dependencies |
| --- | --- | --- | --- |
| <pre>generate-derivatives</pre> | bash | ImageMagick 7 (or compatible), Ghostscript 9.52 (or compatible) | |
| <pre>sync-objects</pre> | bash | AWS Command Line Interface | Digital Ocean Space or AWS S3 Bucket |
| <pre>generate-es-index-settings.rb</pre> | ruby | | |
| <pre>create-es-index</pre> | bash | | Elasticsearch |
| <pre>extract-pdf-text</pre> | bash | xpdf | |
| <pre>generate-es-bulk-data.rb</pre> | ruby | |
| <pre>load-es-bulk-data</pre> | bash | Elasticsearch |


#### Install the Required Software Dependencies

##### ImageMagick 7
ImageMagick is used by `generate-derivatives` to create small and thumbnail images from `.jpg` and `.pdf` (with Ghostscript) collection object files.

Download the appropriate executable for your operating system here: https://imagemagick.org/script/download.php

The scripts expect this to be executable via the command `magick`.

Here's an example of installation under Ubuntu:
```
curl https://imagemagick.org/download/binaries/magick -O
chmod +x magick
sudo mv magick /usr/local/bin/
```


##### Ghostscript 9.52
Ghostscript is used behind the scenes by ImageMagick in `generate-derivatives` to create small and thumbnail images from `.pdf` collection object files.

Download the appropriate executable for your operating system here: https://www.ghostscript.com/download/gsdnld.html

The scripts expect this to be executable via the command `gs`.

Here's an example of installation under Ubuntu:
```
curl -L https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs952/ghostscript-9.52-linux-x86_64.tgz -O
tar xf ghostscript-9.52-linux-x86_64.tgz
sudo mv gs-952-linux-x86_64 /usr/local/bin/gs
rm -rf ghostscript-9.52-linux-x86_64*
```


##### Xpdf 4.02
The `pdftotext` utility in the Xpdf package is used by `extract-pdf-text` to extract text from `.pdf` collection object files.

Download the appropriate executable for your operating system under the "... command line tools" section here: http://www.xpdfreader.com/download.html

The scripts expect this to be executable via the command `pdftotext`.

Here's an example of installation under Ubuntu:
```
curl https://xpdfreader-dl.s3.amazonaws.com/xpdf-tools-linux-4.02.tar.gz -O
sudo mv xpdf-tools-linux-4.02/bin64/pdftotext /usr/local/bin/
rm -rf xpdf-tools-linux-4.02*
```


##### AWS Command Line Interface
The AWS CLI is used by `sync-objects` to upload objects to a cloud-hosted Digital Ocean Space or AWS S3 Bucket.

Download the appropriate executable for your operating system here: https://aws.amazon.com/cli/

The scripts expect this to be executable via the command `aws`.

Here's an example of installation under Ubuntu:
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```


### 1. Create your metadata CSV file and organize your assets into a single directory.

For example, in the directory: `~/collection/objects`


### 2. Use the [generate-derivatives](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/generate-derivatives) script to generate a set of images for each of your assets files.

Usage:
```
generate-derivatives <path-to-your-assets-directory>
```
Example:
```
generate-derivatives ~/collection/objects
```

This script automatically creates `/small` and `/thumbs` subdirectories as necessary within the assets directory, into which it will put the files that it generates.

You can specify several options by prepending them to the command like so:
```
<option>=<value> [<option>=<value>] generate-derivatives <path-to-your-assets-directory>
```

The following options are [defined in the script](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/generate-derivatives#L3-L6) along with their default values:
```
THUMBS_SIZE=${THUMBS_SIZE:-"300x300"}
SMALL_SIZE=${SMALL_SIZE:-"800x800"}
DENSITY=${DENSITY:-"300"}
MISSING=${MISSING:-"true"}
```

For example, to override `DENSITY` and force regeneration of all derivatives, not just those that are `MISSING` (i.e. haven't been generated yet):
```
DENSITY=72 MISSING=false generate-derivatives ~/collection/objects
```


### 3. If using a Digital Ocean Space or AWS S3 Bucket to serve your collection assets, use the [sync-objects](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/sync-objects) script to upload the assets and their derivatives.

Usage:
```
sync-objects <path-to-your-assets-directory> <space-or-bucket-name> [EXTRA "aws s3 sync" ARGS]
```
Here's a [summary of available `aws s3 sync` args](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html).

If using a Digital Ocean Space, you also need to specify your Space's ENDPOINT value as a prefix to the script command:

```
ENDPOINT=<endpoint-url> sync-objects ...
```
You can get your endpoint URL by going to https://cloud.digitalocean.com/spaces/, selecting your space, hovering over the `Endpoints` text and clicking on "Copy URL" next to the "Origin" URL that appears:
  
![Screenshot from 2020-05-13 15-28-55](https://user-images.githubusercontent.com/585182/81856866-63e25400-952f-11ea-8aa5-30b01b87a3d3.png)


### 4. Set your search configuration in `config-search.csv` and use `generate-es-index-settings` and `create-es-index` to create your search index.

[config-search.csv](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/_data/config-search.csv) defines the settings for the fields that you want indexed and displayed in search.

Example (as a table):

|field|index|display|facet|multi-valued|
|---|---|---|---|---|
title|true|true|false|false
date|true|true|false|false
guest_author|true|false|true|true
guest_artist|true|true|true|true
program_artists|true|true|false|false
description|true|false|false|false
creator|true|false|true|true
subject|true|false|true|true
location|true|false|true|true
type|true|false|true|true
full_text|true|false|false|false

[generate-es-index-settings](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/generate-es-index-settings) is a script that creates an Elasticsearch index definition JSON file using the configuration values in `config-search.csv`.
Usage:
```
generate-es-index-settings <path-to-config-search.csv> <output-file-path>
```

[create-es-index](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/create-es-index) is a script that uses the index settings file to create the an index in the Elasticsearch instance.
Usage:
```
create-es-index <elasticsearch-url> <index-name> <path-to-index-settings-file>
```

### 5. Use `extract-pdf-text`, `generate-es-bulk-data`, and `load-es-bulk-data` to load your collection into Elasticsearch

[extract-pdf-text](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/extract-pdf-text) is a script that uses [pdftotext](https://en.wikipedia.org/wiki/Pdftotext) to extract the text from all of the PDFs in the assets directory, writing each to a file with a name in the format: `<original-file-name>.text`

Usage:
```
extract-pdf-text <path-to-your-assets-directory> <text-files-output-path>
```

Example:
```
extract-pdf-text ~/collection/objects /tmp/extracted_pdf_text
```

[generate-es-bulk-data](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/generate-es-bulk-data) is a script that takes the collection metadata file and extracted PDF text files as input and generates a file that can be used to populate an Elasticsearch index via the [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html).

Usage:
```
generate-es-bulk-data <metadata-file-path> <extracted-pdf-text-files-path> <output-file-path>
```

Example:
```
generate-es-bulk-data ~/collection/_data/metadata.csv /tmp/extracted_pdf_text /tmp/bulk_data.csv
```

[load-es-bulk-data](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/scripts/load-es-bulk-data) is a script that loads the bulk data CSV into the Elasticsearch index via its Bulk API.

Usage:
```
load-es-bulk-data <elasticsearch-url> <bulk-data-file-path>
```

Example:
```
load-es-bulk-data http://localhost:9200 /tmp/bulk_data.csv
```

### 6. - N. Do a bunch of other things


### 7. Start the Development Web Server

#### Development Mode
```
jekyll s -H 0.0.0.0 -P 4000 --config=_config.yml
```

#### Production-Preview Mode
```
jekyll s -H 0.0.0.0 -P 4000 --config=_config.yml,_config.production_preview.yml
```
