# Simple helper Makefile for managing the FrankenPHP + MariaDB stack

COMPOSE=docker compose -f docker-compose.yml

.PHONY: up start stop down restart logs build clean install-wp help

up:                ## Build (if needed) and start the stack in detached mode
	$(COMPOSE) up -d

start:             ## Start existing containers
	$(COMPOSE) start

stop:              ## Stop running containers without removing them
	$(COMPOSE) stop

down:              ## Stop and remove containers, but keep volumes/images
	$(COMPOSE) down

restart:           ## Restart containers
	$(COMPOSE) restart

logs:              ## Follow container logs
	$(COMPOSE) logs -f

build:             ## Build/rebuild images
	$(COMPOSE) build

clean:             ## Remove containers, images, volumes and orphans – full reset
	$(COMPOSE) down --rmi all -v --remove-orphans

install-wp:        ## Download and extract latest WordPress into ./wordpress
	@echo "Downloading WordPress ..."
	@curl -L -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	@rm -rf wordpress
	@mkdir -p wordpress
	@tar --strip-components=1 -xzf /tmp/wordpress.tar.gz -C wordpress
	@rm /tmp/wordpress.tar.gz
	@echo "WordPress installed in ./wordpress"

help:              ## Display this help
	@grep -E '^[a-zA-Z_-]+:\s+##' Makefile | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$3}'
