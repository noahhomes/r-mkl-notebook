# r-mkl-notebook
jupyter/r-notebook with mkl acceleration

## Quickstart:

__Method 1__: Using the Makefile

After cloning the repo, you can make use of the following directives:

* `make up` -- start the notebook
* `make down` -- stop the notebook
* `make pull` -- pull the latest version of the image (try this first if you're having any issues)
* `make bash` -- exec a bash shell inside an already running notebook container

__Method 2__: Using docker directly

Or run the image directly:

```
$ docker run -p 8888:8888 noahhomes/r-mkl-notebook
```
