# collectionbuilder-sa_draft

draft of a stand alone style collection.
uses data from [Moscon](https://www.lib.uidaho.edu/digital/moscon/), but not really customized to the collection.
Objects are simply in a folder.
Every object has an image in "thumbs" and "small" named after `objectid`, and an original object item in the root folder named after `filename` column.

## Website generation and deployment steps

### 1. Create your metadata CSV file and organize your assets into a single directory.
For example, in the directory: `~/collection/objects`

### 2. Use the [generate-derivatives](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/generate-derivatives) script to generate a set of images for each of your assets files.

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

The following options are [defined in the script](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/generate-derivatives#L3-L6) along with their default values:
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

### 3. Use the [sync-objects](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/sync-objects) script to upload the assets and their derivatives to your Digital Ocean Space
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

### 4. Set your search configuration in `config-search.csv` and use `generate-es-index-settings` and `create-es-index` to create your search index.

[config-search.csv](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/_data/config-search.csv) defines the settings for the fields that you want indexed and displayed in search.

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

[generate-es-index-settings](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/generate-es-index-settings) is a script that creates an Elasticsearch index definition JSON file using the configuration values in `config-search.csv`.
Usage:
```
generate-es-index-settings <path-to-config-search.csv> <output-file-path>
```

[create-es-index](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/create-es-index) is a script that uses the index settings file to create the an index in the Elasticsearch instance.
Usage:
```
create-es-index <elasticsearch-url> <index-name> <path-to-index-settings-file>
```

### 5. Use `extract-pdf-text`, `generate-es-bulk-data`, and `load-es-bulk-data` to load your collection into Elasticsearch
[extract-pdf-text](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/extract-pdf-text)

[generate-es-bulk-data](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/generate-es-bulk-data)

[load-es-bulk-data](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/search/scripts/load-es-bulk-data)

TODO


### 6. - N. Do a bunch of other things


## Using Docker
Docker and Docker Compose provide a means of defining and executing an application from within an isolated and deterministic environment.

### Prerequisites

1. Install the corresponding version of Docker for your operating system
- Sever for Linux, e.g. [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- [Desktop for Mac](https://docs.docker.com/docker-for-mac/install/)
- [Desktop for Windows](https://docs.docker.com/docker-for-windows/install/)

2. If using Linux, also [install Docker Compose](https://docs.docker.com/compose/install/) (_Compose is included in Docker Desktop for Mac and Windows_)

### Concepts
Here's the [Official Docker Concepts guide](https://docs.docker.com/get-started/#docker-concepts)

My summary:

An **Image** can be thought of as a virtual hard drive that has some operating system and other programs installed on it.

A **Container** can be thought of as a virtual computer that uses a pre-built **Image** as the hard drive.

A `Dockerfile` allows you to define how a custom image should be built, starting with the specification of a base image (e.g. `FROM ubuntu:18.04`) and one or more `RUN` commands which, during the image build process, will be executed as shell commands withing a container running on the base image.

As an example, given the `Dockerfile`:

```
FROM ubuntu:18.04

RUN apt update && apt install -y curl

CMD ["/bin/bash"]
```

You can build this image, and tag it with the name "test-image", using the command:
```
docker build . -t test-image
```

During the build, it will:
1. Download the base `ubuntu:18.04` image from [dockerhub](https://hub.docker.com/)
2. Spawn a container running on the base image
3. Run the shell command `apt update && apt install -y curl` to update the system package list and install `curl`
4. Save the current container filesystem state (i.e. with `curl` installed) on top of the base image
5. Set `/bin/bash` as the default command to execute when you run this image

You can then run this image using the command:
```
docker run -it test-image
```
which will give you a Bash prompt within a running container that looks something like this:
```
root@884ff839efa9:/#
```
The `-it` flags in the `build` command indicate that you intend to interact with it.


### Create the Environment File
`docker-compose.yml` [specifies that a file called `.env`](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/docker-compose.yml#L5) will be used to configure environment variables within the running container.

Since we don't want to commit secret values to the repo, the environment variable keys with empty values have been specified in the file: [env-template](https://github.com/CollectionBuilder/collectionbuilder-sa_draft/blob/master/env-template)

To create the `.env` file:

1. `cp env-template .env`

2. Edit `.env` with a text editor and fill in all the missing values.


### Start the Local Web Server

In a terminal, navigate to the root directory of this repository where the `Dockerfile` and `docker-compose.yml` files are located.

The first time you execute one of the below `docker-compose ... up` commands, the `collectionbuilder` Docker image will be automatically built, which will take some time.

#### Development Mode
In this mode, Jekyll will build a non-production site that references collection assets in the local `<repoRoot>/objects/` directory.
```
docker-compose up
```
You should now be able to access the server at: http://localhost:4000/demo/moscon/

#### Production-preview Mode
In this mode, Jekyll will build a non-production site that references collection assets in a Digital Ocean Space.
```
docker-compose -f docker-compose.production_preview.yml up
```
You should now be able to access the server at: http://localhost:4000/demo/moscon/


### Generate the Production Site
```
docker-compose -f docker-compose.production.yml up
```
