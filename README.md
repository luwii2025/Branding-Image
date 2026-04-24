# GLPI Installer + Branding Script

Automated installer and branding script for GLPI on Debian/Ubuntu-based systems.

This project provides a single script, `glpi_installer.sh`, that:
- Installs Apache, MariaDB, PHP 8.3 dependencies, and GLPI
- Initializes the GLPI database from CLI (no web setup wizard)
- Installs and activates the `mod` plugin
- Downloads custom branding assets from this repository
- Applies login-page branding, organization title, and custom auth label

## Features

- Full GLPI installation and initial configuration
- Automatic Apache virtual host setup for GLPI
- Database provisioning (create DB + user + grants)
- Plugin install/activation flow (`glpi-modifications`)
- Custom logo/background asset download and application
- Custom CSS injection into GLPI root entity
- Login source label replacement (`GLPI internal database`)
- Cache clear at the end of execution

## Requirements

- Ubuntu/Debian server with `apt-get`
- Root access (`sudo`/`root`)
- Internet access to:
  - GLPI GitHub releases
  - Plugin release URL
  - Raw branding assets URL

## File in this Repository

- `glpi_installer.sh`: Main installation + branding automation script

## Quick Start

Option A: Direct one-line install/run:

```bash
sudo wget -O glpi_setup.sh https://raw.githubusercontent.com/luwii2025/Branding-Image/main/glpi_installer.sh && sudo chmod +x glpi_setup.sh && sudo ./glpi_setup.sh
```

Option B: Clone and run locally:

1. Clone this repository:

```bash
git clone https://github.com/luwii2025/Branding-Image.git
cd Branding-Image
```

2. Make the script executable:

```bash
chmod +x glpi_installer.sh
```

3. (Recommended) Review and edit configuration variables near the top of the script:
- GLPI version and install path
- Database credentials
- Branding image URLs
- Organization title and auth label

4. Run the script as root:

```bash
sudo ./glpi_installer.sh
```

## Important Configuration Variables

Update these in `glpi_installer.sh` before running:

- `GLPI_VER`: GLPI version to install
- `GLPI_DIR`: Installation path (default `/var/www/html/glpi`)
- `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_HOST`: Database settings
- `PLUGIN_URL`: Plugin archive URL
- `GITHUB_BG_URL`, `GITHUB_LOGO_*_URL`: Branding asset URLs
- `ORG_TITLE`: Organization name shown in GLPI
- `AUTH_LABEL`: Label replacing `GLPI internal database`

## What the Script Does (High Level)

1. Installs required OS packages
2. Sets up MariaDB database and user
3. Downloads and extracts GLPI
4. Configures Apache site and rewrite rules
5. Runs GLPI CLI DB install
6. Downloads plugin and branding images
7. Generates custom branding CSS
8. Activates plugin and applies branding resources
9. Enables GLPI custom CSS in database
10. Patches login source text label
11. Clears GLPI cache

## Security Notes

- The script currently contains hardcoded database credentials and default GLPI credentials output.
- Change `DB_PASS` and rotate all credentials before production use.
- Change default GLPI admin password immediately after first login.
- Review and harden Apache, MariaDB, and PHP settings for your environment.

## Troubleshooting

- If installation fails, rerun with shell tracing for debugging:

```bash
sudo bash -x ./glpi_installer.sh
```

- Check service and logs:
  - Apache: `systemctl status apache2`
  - MariaDB: `systemctl status mariadb`
  - GLPI Apache logs: `/var/log/apache2/glpi_error.log`

## Disclaimer

This script makes system-level changes (packages, services, database, web server, file permissions). Test in a staging environment before running in production.
