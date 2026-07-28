# Simple helper Makefile for managing the FrankenPHP + MariaDB stack

COMPOSE=docker compose -f docker-compose.yml

.PHONY: init-dev init-prod up start stop down restart logs build clean install-wp fix-perms fix-perms-host urls set-fs-direct help

init-dev:          ## Copy docker-compose.dev.yml to docker-compose.yml
	cp docker-compose.dev.yml docker-compose.yml
	@echo "docker-compose.yml initialized for development."

init-prod:         ## Copy docker-compose.prod.yml to docker-compose.yml
	cp docker-compose.prod.yml docker-compose.yml
	@echo "docker-compose.yml initialized for production."

up:                ## Build (if needed) and start the stack in detached mode
	$(COMPOSE) up -d
	@$(MAKE) urls

start:             ## Start existing containers
	$(COMPOSE) start
	@$(MAKE) urls

stop:              ## Stop running containers without removing them
	$(COMPOSE) stop

down:              ## Stop and remove containers, but keep volumes/images
	$(COMPOSE) down

restart:           ## Restart containers
	$(COMPOSE) restart
	@$(MAKE) urls

logs:              ## Follow container logs
	$(COMPOSE) logs -f

build:             ## Build/rebuild images
	$(COMPOSE) build

build-no-cache:             ## Build/rebuild images
	$(COMPOSE) build --no-cache

clean:             ## Remove containers, images, volumes and orphans – full reset
	$(COMPOSE) down --rmi all -v --remove-orphans

install-wp:        ## Download and extract latest WordPress into ./wordpress
	@echo "Downloading WordPress ..."
	@curl -L -o /tmp/wordpress.zip https://de.wordpress.org/latest-de_DE.zip
	@rm -rf wordpress
	@unzip -q /tmp/wordpress.zip
	@rm /tmp/wordpress.zip
	@echo "Ensuring ./wordpress is owned by $$(id -u):$$(id -g) ..."
	@chown -R "$$(id -u):$$(id -g)" wordpress 2>/dev/null || true
	@echo "WordPress installed in ./wordpress"

# Resolve target UID/GID: .env HOST_* if set, otherwise current user.
# Usage: $(call resolve_host_ids) sets shell vars TARGET_UID TARGET_GID
define resolve_host_ids
	TARGET_UID=$$(id -u); TARGET_GID=$$(id -g); \
	if [ -f .env ]; then \
		env_uid=$$(grep -E '^HOST_UID=' .env | tail -1 | cut -d= -f2-); \
		env_gid=$$(grep -E '^HOST_GID=' .env | tail -1 | cut -d= -f2-); \
		[ -n "$$env_uid" ] && TARGET_UID=$$env_uid; \
		[ -n "$$env_gid" ] && TARGET_GID=$$env_gid; \
	fi
endef

fix-perms:         ## Align ./wordpress ownership with HOST_UID/GID (.env or current user)
	@$(resolve_host_ids); \
	echo "Fixing WordPress ownership to $$TARGET_UID:$$TARGET_GID ..."; \
	if [ ! -d wordpress ]; then \
		echo "No ./wordpress directory – run make install-wp first."; \
		exit 0; \
	fi; \
	if $(COMPOSE) ps --status running --services 2>/dev/null | grep -qx frankenphp; then \
		echo "Using running container (root) to chown bind mount ..."; \
		$(COMPOSE) exec -T -u 0 frankenphp chown -R "$$TARGET_UID:$$TARGET_GID" /app/public; \
	elif [ "$$(id -u)" = "0" ]; then \
		chown -R "$$TARGET_UID:$$TARGET_GID" wordpress; \
	else \
		chown -R "$$TARGET_UID:$$TARGET_GID" wordpress 2>/dev/null \
			|| sudo chown -R "$$TARGET_UID:$$TARGET_GID" wordpress; \
	fi; \
	echo "Permissions updated."

fix-perms-host:    ## Write current user to HOST_UID/GID in .env, then fix-perms
	@HOST_UID_VAL=$$(id -u); HOST_GID_VAL=$$(id -g); \
	if [ -f .env ]; then \
		awk -v uid="$$HOST_UID_VAL" -v gid="$$HOST_GID_VAL" 'BEGIN{u=0;g=0} \
			/^HOST_UID=/ {print "HOST_UID="uid; u=1; next} \
			/^HOST_GID=/ {print "HOST_GID="gid; g=1; next} \
			{print} \
			END { if(!u) print "HOST_UID="uid; if(!g) print "HOST_GID="gid }' .env > .env.tmp && mv .env.tmp .env; \
	else \
		printf "HOST_UID=%s\nHOST_GID=%s\n" "$$HOST_UID_VAL" "$$HOST_GID_VAL" > .env; \
	fi; \
	echo "HOST_UID=$$HOST_UID_VAL HOST_GID=$$HOST_GID_VAL set in .env"; \
	$(MAKE) fix-perms

set-fs-direct:    ## Inject FS_METHOD 'direct' into wp-config.php (inside container)
	@echo "Setting FS_METHOD=direct in wp-config.php (container) ..."
	@$(COMPOSE) exec -T frankenphp bash -c "grep -q 'FS_METHOD.*direct' /app/public/wp-config.php || sed -i \"/\\* That's all, stop editing!/i define( 'FS_METHOD', 'direct' );\" /app/public/wp-config.php"
	@echo "FS_METHOD set."

urls:              ## Print URLs / endpoints of running services
	@echo ""
	@echo "Services available at:"
	@echo ""
	@WP_HTTP=$$($(COMPOSE) port frankenphp 80 2>/dev/null | head -1 | sed 's/.*://'); \
	WP_HTTPS=$$($(COMPOSE) port frankenphp 443 2>/dev/null | head -1 | sed 's/.*://'); \
	PMA=$$($(COMPOSE) port phpmyadmin 80 2>/dev/null | head -1 | sed 's/.*://'); \
	DB=$$($(COMPOSE) port db 3306 2>/dev/null | head -1 | sed 's/.*://'); \
	REDIS=$$($(COMPOSE) port dragonfly 6379 2>/dev/null | head -1 | sed 's/.*://'); \
	if [ -n "$$WP_HTTP" ]; then \
		echo "  WordPress:   http://localhost:$$WP_HTTP"; \
	fi; \
	if [ -n "$$WP_HTTPS" ]; then \
		echo "  WordPress:   https://localhost:$$WP_HTTPS"; \
	fi; \
	if [ -n "$$PMA" ]; then \
		echo "  phpMyAdmin:  http://localhost:$$PMA"; \
	fi; \
	if [ -n "$$DB" ]; then \
		echo "  MariaDB:     localhost:$$DB  (user/pass from .env; WP host: db)"; \
	fi; \
	if [ -n "$$REDIS" ]; then \
		echo "  Dragonfly:   localhost:$$REDIS  (Redis-compatible)"; \
	fi; \
	if [ -z "$$WP_HTTP$$WP_HTTPS$$PMA$$DB$$REDIS" ]; then \
		echo "  (no published ports found – is the stack running?)"; \
	fi; \
	echo ""

help:              ## Display this help
	@grep -E '^[a-zA-Z_-]+:.*##' Makefile | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
