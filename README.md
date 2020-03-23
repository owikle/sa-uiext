# collectionbuilder-sa_draft

draft of a stand alone style collection.
uses data from [Moscon](https://www.lib.uidaho.edu/digital/moscon/), but not really customized to the collection.
Objects are simply in a folder.
Every object has an image in "thumbs" and "small" named after `objectid`, and an original object item in the root folder named after `filename` column.

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
