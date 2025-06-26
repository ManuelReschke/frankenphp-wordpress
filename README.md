# FrankenPHP + WordPress 🚀

Willkommen in diesem **FrankenPHP-WordPress-Boilerplate**!  
Mit nur wenigen Befehlen bekommst du eine lauffähige WordPress-Instanz auf Basis von [FrankenPHP](https://frankenphp.dev/), MariaDB und phpMyAdmin – komplett in Docker 🛳️.

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

# 5) Stack starten (FrankenPHP, MariaDB, phpMyAdmin)
make up
```

Wenige Sekunden später erreichst du:

* 🔗 **WordPress**: [`http://localhost:8080`](http://localhost:8080)  
* 🔗 **phpMyAdmin**: [`http://localhost:8081`](http://localhost:8081)  
  * Anmeldedaten: die Werte aus `.env` (`MYSQL_USER` & `MYSQL_PASSWORD`)

> 💡 Der Standard-Admin-Benutzer von WordPress wird wie gewohnt beim Einrichtungs­assistenten angelegt.

---

## ⚙️ Makefile-Befehle

| Befehl                | Beschreibung |
|-----------------------|--------------|
| `make init-dev`       | Kopiert `docker-compose.dev.yml` → `docker-compose.yml` |
| `make init-prod`      | Kopiert `docker-compose.prod.yml` → `docker-compose.yml` |
| `make up`             | Container bauen (falls nötig) & im Hintergrund starten |
| `make start`          | Gestoppte Container starten |
| `make stop`           | Container anhalten, **ohne** sie zu löschen |
| `make down`           | Container anhalten & löschen (Volumes bleiben) |
| `make restart`        | Container neu starten |
| `make logs`           | Live-Logs aller Container folgen |
| `make build`          | Images neu bauen |
| `make clean`          | Voller Reset: Container, Images, Volumes & Orphans löschen |
| `make install-wp`     | Aktuelle WordPress-Quelle laden & nach `./wordpress` entpacken |
| `make fix-perms`      | Setzt Besitzer von `./wordpress` auf UID 33 (www-data) |
| `make set-fs-direct`  | Fügt `define('FS_METHOD','direct')` in `wp-config.php` ein |
| `make help`           | Übersicht aller Targets |

---

## 🧩 Docker-Services

| Service      | Zweck | Port |
|--------------|-------|------|
| **frankenphp** | PHP 8.4 Runtime + Webserver (Basis: `dunglas/frankenphp:php8.4`) | 8080 → 80 |
| **db**         | MariaDB 11 mit persistenter Volume-Ablage (`db_data`) | 3306 |
| **phpmyadmin** | GUI-Verwaltung für MariaDB | 8081 → 80 |

---

## 🌐 Eigene Domain & Caddyfile

1. **Site-Datei anlegen**  
   `caddy/site.caddyfile` (Endung `.caddyfile` ist wichtig)
   ```caddyfile
   {$DOMAIN} {
       root * /app/public    # WordPress Root im Container
       encode zstd br gzip
       php_server            # FrankenPHP Shortcut
       file_server
   }
   ```
   `{$DOMAIN}` wird automatisch durch den Wert aus `.env` ersetzt.

2. **Compose-Mount aktivieren**  
   In `docker-compose.yml` beim Service `frankenphp`:
   ```yaml
   volumes:
      - ./wordpress:/app/public
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy/wordpress.caddyfile:/etc/caddy/Caddyfile.d/wordpress.caddyfile:ro
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

| Variable            | Default            | Beschreibung |
|---------------------|--------------------|--------------|
| `DOMAIN`            | `localhost`        | Öffentliche Domain/Host deiner WP-Site (FrankenPHP-Variable) |
| `MYSQL_DATABASE`    | `franken`          | Name der Datenbank |
| `MYSQL_USER`        | `frankenuser`      | DB-User |
| `MYSQL_PASSWORD`    | `frankenpass`      | DB-Passwort |
| `MYSQL_ROOT_PASSWORD` | `rootpass`       | Root-Passwort (nur intern) |

> 🔒 **Sicherheit:** `.env` ist in `.gitignore` gelistet. Teile echte Zugangsdaten nie in öffentlichen Repos!

---

## 🧹 Aufräumen

```bash
make clean   # entfernt ALLES (Container, Images, Volumes)
```

---

## 🤝 Lizenz

Siehe [`LICENSE`](LICENSE).

Viel Spaß 🎉
