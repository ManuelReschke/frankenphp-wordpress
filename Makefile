# Simple helper Makefile for managing the FrankenPHP + MariaDB stack

COMPOSE=docker compose -f docker-compose.yml

.PHONY: init-dev init-prod up start stop down restart logs build clean install-wp help

init-dev:          ## Copy docker-compose.dev.yml to docker-compose.yml
	cp docker-compose.dev.yml docker-compose.yml
	@echo "docker-compose.yml initialized for development."

init-prod:         ## Copy docker-compose.prod.yml to docker-compose.yml
	cp docker-compose.prod.yml docker-compose.yml
	@echo "docker-compose.yml initialized for production."

up:                ## Build (if needed) and start the stack in detached mode
	$(COMPOSE) up -d
	@$(MAKE) fix-perms

start:             ## Start existing containers
	$(COMPOSE) start
	@$(MAKE) fix-perms

stop:              ## Stop running containers without removing them
	$(COMPOSE) stop

down:              ## Stop and remove containers, but keep volumes/images
	$(COMPOSE) down

restart:           ## Restart containers
	$(COMPOSE) restart
	@$(MAKE) fix-perms

logs:              ## Follow container logs
	$(COMPOSE) logs -f

build:             ## Build/rebuild images
	$(COMPOSE) build

clean:             ## Remove containers, images, volumes and orphans – full reset
	$(COMPOSE) down --rmi all -v --remove-orphans

install-wp:        ## Download and extract latest WordPress into ./wordpress
	@echo "Downloading WordPress ..."
	@curl -L -o /tmp/wordpress.zip https://de.wordpress.org/latest-de_DE.zip
	@rm -rf wordpress
	@unzip -q /tmp/wordpress.zip
	@rm /tmp/wordpress.zip
	@echo "WordPress installed in ./wordpress"

fix-perms:         ## Fix WordPress file permissions (www-data)
	@echo "Fixing WordPress file permissions ..."
	@sudo chown -R 33:33 wordpress || true
	@echo "Permissions updated."

set-fs-direct:    ## Inject FS_METHOD 'direct' into wp-config.php (inside container)
	@echo "Setting FS_METHOD=direct in wp-config.php (container) ..."
		@$(COMPOSE) exec -T frankenphp bash -c "grep -q 'FS_METHOD.*direct' /app/public/wp-config.php || sed -i \"/\\* That's all, stop editing!/i define( 'FS_METHOD', 'direct' );\" /app/public/wp-config.php"
	@echo "FS_METHOD set."

help:              ## Display this help
	@grep -E '^[a-zA-Z_-]+:\s+##' Makefile | awk 'BEGIN {FS = ":"}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$3}'
