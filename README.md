# calserver-yii – Installer

Deployment-Repository für **calserver-yii V1**. Kunden klonen dieses Repo und nutzen die enthaltenen Scripts zur Installation.

## Voraussetzungen

- Ubuntu 22.04 / 24.04 LTS
- Docker Engine ≥ 24
- Docker Compose Plugin
- DNS A-Record auf die Server-IP gesetzt
- Docker Hub Pull-Token (vom Support)

## Installation

```bash
git clone https://github.com/calhelp/calserver-install.git
cd calserver-install
./install.sh
```

`install.sh` fragt interaktiv nach Domain, E-Mail und Docker-Zugangsdaten, passt `.env` an und startet automatisch `deploy.sh`.

## Manuelle Einrichtung

```bash
cp .env.example .env
nano .env

docker login -u "<benutzername>" -p "<token>"
./deploy.sh
```

## Scripts

| Script | Beschreibung |
|---|---|
| `install.sh` | Geführte Erstinstallation |
| `deploy.sh` | Stack deployen / neu starten |
| `update.sh` | Images aktualisieren (mit Rollback) |
| `restart.sh` | Alle Container neu starten |
| `check.sh` | Health Check (Container + HTTP + Disk) |
| `migration.sh` | Datenbank-Migrationen ausführen |

## V2 Stack aktivieren

In `.env` setzen:

```env
ENABLE_V2=true
```

Dann `./deploy.sh` ausführen. Der V2 Stack wird automatisch eingebunden:

- `/api/v2/` → calserver-api-v2
- `/v2/` → calserver-frontend

## Verzeichnisstruktur

```
.
├── docker-compose.yml              # Basis-Stack
├── docker-compose.https.yml        # Let's Encrypt Overlay
├── docker-compose.v2.yml           # V2 Stack Overlay
├── .env.example                    # Konfigurationsvorlage
├── nginx/
│   ├── conf.d/my_proxy.conf        # Proxy-Einstellungen
│   └── vhost.d/default_location    # V2 Routing
└── mysql/
    └── conf.d/mysqld_safe_syslog.cnf
```

## Support

Bei Problemen: support@calhelp.de
