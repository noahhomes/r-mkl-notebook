# tools
SHELL := /bin/bash

# env vars
NB_UID := $(shell id -u)

# Default command and help messages
.PHONY: default help
default: help

bash:      ## Run a bash shell inside the app container
up:        ## Launch the dev environment

.PHONY: up
up:
				@NB_UID=${NB_UID} docker-compose -p ${USER} up

.PHONY: down
down:
				@NB_UID=${NB_UID} docker-compose -p ${USER} down

.PHONY: build
build:
				@NB_UID=${NB_UID} docker-compose build

.PHONY: pull
pull:
				docker-compose pull

.PHONY: bash
bash:
				@NB_UID=${NB_UID} docker-compose -p ${USER} exec notebook bash
