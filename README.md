# FrankenPHP + WordPress 🚀

Willkommen in diesem **FrankenPHP-WordPress-Boilerplate**!  
Mit nur wenigen Befehlen bekommst du eine lauffähige WordPress-Instanz auf Basis von [FrankenPHP](https://frankenphp.dev/), MariaDB, Dragonfly (Redis-kompatibel) und phpMyAdmin – komplett in Docker 🛳️.

---

## 📋 Voraussetzungen

* [Docker](https://docs.docker.com/get-docker/) ≥ 20.10  
* [Docker Compose](https://docs.docker.com/compose/) (ab Docker v20.10 ist `docker compose` bereits integriert)  
* `make` – unter macOS & Linux vorinstalliert, unter Windows z. B. über [Git for Windows](https://gitforwindows.org/) oder WSL.

---

## 🏗️ Installation

```bash
# 1) Repository klonen (falls noch nicht geschehen)
git clone <repo-url> frankenphp-wordpress
cd frankenphp-wordpress

# 2) Eigene Umgebungs­variablen festlegen
cmp .env.example .env  # Werte im Editor anpassen

# 3) WordPress herunterladen (legt ./wordpress an)
make install-wp

# 4) docker-compose für die gewünschte Umgebung generieren
make init-dev   # Development
#   oder
make init-prod  # Production

# 5) Stack builden
make build

# 6) Stack starten (FrankenPHP, MariaDB, Dragonfly, phpMyAdmin)
make up
```

Wenige Sekunden später erreichst du:

* 🔗 **WordPress**: [`http://localhost:8080`](http://localhost:8080)  
* 🔗 **phpMyAdmin**: [`http://localhost:8081`](http://localhost:8081)  
  * Anmeldedaten: die Werte aus `.env` (`MYSQL_USER` & `MYSQL_PASSWORD`)

> 💡 Der Standard-Admin-Benutzer von WordPress wird wie gewohnt beim Einrichtungs­assistenten angelegt.
> 💡 Beim WordPress-Installationsassistenten ist der **Datenbank-Host** `db` (nicht `localhost`).

---

## ⚙️ Makefile-Befehle

| Befehl                | Beschreibung |
|-----------------------|--------------|
| `make init-dev`       | Kopiert `docker-compose.dev.yml` → `docker-compose.yml` |
| `make init-prod`      | Kopiert `docker-compose.prod.yml` → `docker-compose.yml` |
| `make up`             | Container bauen (falls nötig) & im Hintergrund starten; gibt danach die Service-URLs aus |
| `make start`          | Gestoppte Container starten; gibt danach die Service-URLs aus |
| `make urls`           | Zeigt URLs/Endpunkte der laufenden Dienste |
| `make stop`           | Container anhalten, **ohne** sie zu löschen |
| `make down`           | Container anhalten & löschen (Volumes bleiben) |
| `make restart`        | Container neu starten |
| `make logs`           | Live-Logs aller Container folgen |
| `make build`          | Images neu bauen |
| `make clean`          | Voller Reset: Container, Images, Volumes & Orphans löschen |
| `make install-wp`     | Aktuelle WordPress-Quelle laden & nach `./wordpress` entpacken (Owner = dein User) |
| `make fix-perms`      | Recovery: setzt Owner von `./wordpress` auf `HOST_UID`/`HOST_GID` |
| `make fix-perms-host` | Schreibt aktuellen User nach `.env` (`HOST_*`) und ruft `fix-perms` auf |
| `make set-fs-direct`  | Fügt `define('FS_METHOD','direct')` in `wp-config.php` ein |
| `make help`           | Übersicht aller Targets |

### Dateirechte (Dev)

FrankenPHP/PHP läuft im Container als **`HOST_UID`/`HOST_GID`** (in `.env`, ideal = `id -u` / `id -g`).  
Damit gehören Uploads, Plugin-Installationen und Host-Edits demselben User – **kein** rekursives `chown` bei jedem `make up`.

Nach einem Wechsel vom alten Setup einmalig:

```bash
make fix-perms-host   # HOST_* in .env + chown
make build            # neues Image (gosu + setcap)
make up
```

---

## 🧩 Docker-Services

| Service      | Zweck | Port |
|--------------|-------|------|
| **frankenphp** | PHP 8.5 Runtime + Webserver (Basis: `dunglas/frankenphp:php8.5`) | Prod: 80 → 80, 443 → 443, Dev: 8080 → 80, 8443 → 443 |
| **db**         | MariaDB 12 mit persistenter Volume-Ablage (`db_data`) | 3306 |
| **dragonfly**  | Dragonfly Redis-kompatibel für WordPress Object Caching | Dev: 6379 → 6379 |
| **phpmyadmin** | GUI-Verwaltung für MariaDB | 8081 → 80 |

---

## 🌐 Eigene Domain & Caddyfile

1. **Site-Datei anlegen**  
   `caddy/site.caddyfile` (Endung `.caddyfile` ist wichtig)
   ```caddyfile
   {$SERVER_NAME} {
       root * /app/public    # WordPress Root im Container
       encode zstd br gzip
       php_server            # FrankenPHP Shortcut
       file_server
   }
   ```
   `{$SERVER_NAME}` wird automatisch durch den Wert aus `.env` ersetzt.

2. **Compose-Mount aktivieren**  
   In `docker-compose.yml` beim Service `frankenphp`:
   ```yaml
   volumes:
      - ./wordpress:/app/public
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy/wordpress.caddyfile:/etc/caddy/Caddyfile.d/wordpress.caddyfile:ro
      - ./caddy/opcache.ini:/usr/local/etc/php/conf.d/docker-php-ext-opcache.ini:ro
      - caddy_data:/data
      - caddy_config:/config
   ```

3. **Stack neu bauen & starten**
   ```bash
   make build
   make up
   ```

Caddy holt sich bei öffentlicher Domain automatisch TLS-Zertifikate. Für lokale Hosts bleibt es bei HTTP.

---

## 🔑 Umgebungsvariablen

Alle Variablen werden in `.env` gepflegt und im `docker-compose.yml` genutzt:

| Variable            | Default            | Beschreibung                                                 |
|---------------------|--------------------|--------------------------------------------------------------|
| `SERVER_NAME`       | `http://localhost` | Site-Adresse für Caddy. Lokal: `http://localhost` (HTTP). Prod: Domain wie `example.com` (Auto-TLS) |
| `MYSQL_DATABASE`    | `franken`          | Name der Datenbank                                           |
| `MYSQL_USER`        | `frankenuser`      | DB-User                                                      |
| `MYSQL_PASSWORD`    | `frankenpass`      | DB-Passwort                                                  |
| `MYSQL_ROOT_PASSWORD` | `rootpass`       | Root-Passwort (nur intern)                                   |
| `REDIS_HOST`        | `dragonfly`        | Redis-Server Hostname                                        |
| `REDIS_PORT`        | `6379`             | Redis-Server Port                                            |
| `DRAGONFLY_MAX_MEMORY` | `512mb`             | Redis/Dragonfly max memory                                   |
| `HOST_UID`          | `1000`             | UID, unter der FrankenPHP/PHP läuft (an Host anpassen: `id -u`) |
| `HOST_GID`          | `1000`             | GID analog (`id -g`)                                         |

> 🔒 **Sicherheit:** `.env` ist in `.gitignore` gelistet. Teile echte Zugangsdaten nie in öffentlichen Repos!

---

## 🚀 Redis Object Caching

Das Setup inkludiert einen **Dragonfly** Container, der Redis-kompatibel ist und perfekt für WordPress Object Caching funktioniert.

### Empfohlene WordPress-Plugins:
- **[Redis Object Cache](https://wordpress.org/plugins/redis-cache/)** von Till Krüss (empfohlen)
- **[W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/)** mit Redis-Backend
- **[WP Redis](https://wordpress.org/plugins/wp-redis/)**

### Installation:
1. WordPress-Plugin über Admin-Backend installieren
2. Plugin aktivieren
3. Bei Redis Object Cache: auf "Enable Object Cache" klicken
4. Die Verbindung zu `dragonfly:6379` wird automatisch erkannt

> 💡 **Tipp:** Dragonfly ist bis zu 25x schneller als Redis bei gleichem Speicherverbrauch!

---

## 🧹 Aufräumen

```bash
make clean   # entfernt ALLES (Container, Images, Volumes)
```

---

## 🤝 Lizenz

Siehe [`LICENSE`](LICENSE).

Viel Spaß 🎉
