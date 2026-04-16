#!/bin/bash
# ==============================================================================
# GLPI Full Setup + Branding Script
# Installs GLPI, bypasses web setup, and applies full UI branding in one run
# ==============================================================================
set -eu

# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION — Edit everything here
# ──────────────────────────────────────────────────────────────────────────────
GLPI_VER="11.0.6"
GLPI_DIR="/var/www/html/glpi"
WEB_USER="www-data"
WEB_GROUP="www-data"

# Database
DB_NAME="glpidb"
DB_USER="sitadmin"
DB_PASS='S3rv1c31T+'
DB_HOST="localhost"

# Plugin
PLUGIN_URL="https://github.com/i-Vertix/glpi-modifications/releases/download/11.0.5/glpi-mod-11.0.5.tar.gz"
DOWNLOAD_DEST="/tmp/glpi-mod.tar.gz"
FINAL_PLUGIN_FOLDER="mod"

# Branding images (GitHub raw URLs)
GITHUB_BG_URL="https://raw.githubusercontent.com/luwii2025/Branding-Image/main/bg.jpg"
GITHUB_LOGO_SMALL_URL="https://raw.githubusercontent.com/luwii2025/Branding-Image/main/55x55px.png"
GITHUB_LOGO_MEDIUM_URL="https://raw.githubusercontent.com/luwii2025/Branding-Image/main/100x55px.png"
GITHUB_LOGO_LARGE_URL="https://raw.githubusercontent.com/luwii2025/Branding-Image/main/250x138px.png"

BG_FILENAME="custom_org_bg.png"
LOGO_SMALL_FILENAME="custom_org_logo_small.png"
LOGO_MEDIUM_FILENAME="custom_org_logo_medium.png"
LOGO_LARGE_FILENAME="custom_org_logo_large.png"
LOGO_FILENAME="$LOGO_LARGE_FILENAME"

# Organization
ORG_TITLE="Navy IT Portal"
AUTH_LABEL="Navy Internal Database"  # Text shown in login source dropdown

# CSS output path
CUSTOM_CSS_FILE="$GLPI_DIR/public/css/custom_branding.css"

# ──────────────────────────────────────────────────────────────────────────────
# ROOT CHECK
# ──────────────────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root. Use: sudo ./glpi_setup.sh"
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════════════
# PART 1 — GLPI INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1: Installing dependencies..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
apt-get update -q
apt-get install -y -q \
  apache2 mariadb-server libapache2-mod-php8.3 \
  php8.3-cli php8.3-curl php8.3-gd php8.3-intl php8.3-mbstring \
  php8.3-mysql php8.3-xml php8.3-zip php8.3-bz2 php8.3-ldap \
  php8.3-bcmath php8.3-opcache php8.3-gmp php8.3-apcu \
  wget tar python3 gettext
echo "✅ Dependencies installed."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  Step 2: Configuring MariaDB..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
systemctl enable --now mariadb
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';"
mysql -e "FLUSH PRIVILEGES;"
echo "✅ Database '${DB_NAME}' and user '${DB_USER}' created."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⬇️  Step 3: Downloading GLPI ${GLPI_VER}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
wget -q --show-progress -O /tmp/glpi.tgz \
  "https://github.com/glpi-project/glpi/releases/download/${GLPI_VER}/glpi-${GLPI_VER}.tgz"
rm -rf "$GLPI_DIR"
tar -xzf /tmp/glpi.tgz -C /var/www/html/
rm /tmp/glpi.tgz
echo "✅ GLPI extracted to $GLPI_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Step 4: Setting permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chown -R $WEB_USER:$WEB_GROUP "$GLPI_DIR"
chmod -R 755 "$GLPI_DIR"

cat > "$GLPI_DIR/public/.htaccess" << 'HTEOF'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.php [QSA,L]
HTEOF

cat > "$GLPI_DIR/.htaccess" << 'HTEOF'
RewriteEngine On
RewriteRule ^(.*)$ public/$1 [L]
HTEOF

chown $WEB_USER:$WEB_GROUP "$GLPI_DIR/public/.htaccess" "$GLPI_DIR/.htaccess"
echo "✅ Permissions set."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Step 5: Configuring Apache..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat > /etc/apache2/sites-available/glpi.conf << APACHEEOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot ${GLPI_DIR}/public
    ServerName localhost

    <Directory ${GLPI_DIR}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
APACHEEOF

a2dissite 000-default.conf 2>/dev/null || true
a2ensite glpi.conf
a2enmod rewrite
systemctl restart apache2
echo "✅ Apache configured."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Step 6: Installing GLPI database via CLI (bypassing web setup)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$GLPI_DIR"
sudo -u $WEB_USER php bin/console db:install \
  --db-host="$DB_HOST" \
  --db-name="$DB_NAME" \
  --db-user="$DB_USER" \
  --db-password="$DB_PASS" \
  --default-language=en_GB \
  --no-interaction \
  --force
echo "✅ GLPI database installed — web setup wizard bypassed."

rm -rf "$GLPI_DIR/install"
echo "✅ Install folder removed."

# ══════════════════════════════════════════════════════════════════════════════
# PART 2 — BRANDING & PERSONALIZATION
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Phase 1: Downloading and Extracting Plugin..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$GLPI_DIR/plugins/"
cd "$GLPI_DIR/plugins/"

wget -q --show-progress -O "$DOWNLOAD_DEST" "$PLUGIN_URL"
EXTRACTED_FOLDER=$(tar -tf "$DOWNLOAD_DEST" | head -1 | cut -f1 -d"/")
echo "   Extracted folder name: $EXTRACTED_FOLDER"
if [ "$EXTRACTED_FOLDER" != "$FINAL_PLUGIN_FOLDER" ]; then
  rm -rf "$FINAL_PLUGIN_FOLDER"
fi
tar -xzf "$DOWNLOAD_DEST"
if [ "$EXTRACTED_FOLDER" != "$FINAL_PLUGIN_FOLDER" ]; then
  echo "🔄 Renaming '$EXTRACTED_FOLDER' → '$FINAL_PLUGIN_FOLDER'..."
  mv "$EXTRACTED_FOLDER" "$FINAL_PLUGIN_FOLDER"
else
  echo "ℹ️  Extracted folder is already named '$FINAL_PLUGIN_FOLDER' — no rename needed."
fi
rm "$DOWNLOAD_DEST"
echo "✅ Plugin extracted."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 Phase 2: Fetching Branding Assets from GitHub..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$GLPI_DIR/public/pics"
wget -q -O "$BG_FILENAME"           "$GITHUB_BG_URL"
wget -q -O "$LOGO_SMALL_FILENAME"   "$GITHUB_LOGO_SMALL_URL"
wget -q -O "$LOGO_MEDIUM_FILENAME"  "$GITHUB_LOGO_MEDIUM_URL"
wget -q -O "$LOGO_LARGE_FILENAME"   "$GITHUB_LOGO_LARGE_URL"
echo "✅ Assets downloaded:"
echo "   Background    : $BG_FILENAME"
echo "   Logo Small    : $LOGO_SMALL_FILENAME (55x55)"
echo "   Logo Medium   : $LOGO_MEDIUM_FILENAME (100x55)"
echo "   Logo Large    : $LOGO_LARGE_FILENAME (250x138)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🖌️  Phase 3: Generating Custom CSS Branding File..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mkdir -p "$(dirname "$CUSTOM_CSS_FILE")"

cat > "$CUSTOM_CSS_FILE" << CSSEOF
/* ============================================================
   Custom GLPI Branding — Auto-generated by glpi_setup.sh
   Organization : ${ORG_TITLE}
   ============================================================ */

/* ── Global font & base ── */
body, .page, .main-container {
  font-family: 'Poppins', 'Segoe UI', sans-serif !important;
}

/* ── CSS Variables ── */
:root {
  --brand-primary   : #1a3a5c;
  --brand-accent    : #cfbf11;
  --brand-secondary : #2d6ca8;
  --brand-radius    : 8px;
}

/* ── Override Tabler UI surface variable on login page ── */
.welcome-anonymous,
.page-anonymous,
body.welcome-anonymous {
  --tblr-bg-surface: rgba(255, 255, 255, 0.12) !important;
}

.welcome-anonymous .card,
.welcome-anonymous .card-md,
.welcome-anonymous .main-content-card {
  --tblr-bg-surface: var(--tblr-bg-surface) !important;
  background-color: rgba(255, 255, 255, 0.12) !important;
  backdrop-filter: blur(16px) !important;
  -webkit-backdrop-filter: blur(16px) !important;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3) !important;
}

/* ────────────────────────────────────────────────
   LOGIN PAGE
   ──────────────────────────────────────────────── */
#page.login-page,
.login-page,
body.login {
  background: url('/pics/${BG_FILENAME}') center center / cover no-repeat fixed !important;
}

.login-page::before {
  content: "";
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.45);
  z-index: 0;
}

.login-page .col-md-4,
.login-page .login-left,
.login-page .plugin-mod-brand {
  display: none !important;
}

.login-page .col-md-8 {
  max-width: 440px !important;
  margin: auto !important;
  flex: none !important;
}

.login-page .login-box,
.login-page .card {
  position: relative;
  z-index: 1;
  border-radius: var(--brand-radius) !important;
  backdrop-filter: blur(16px) !important;
  -webkit-backdrop-filter: blur(16px) !important;
  background: rgba(255, 255, 255, 0.12) !important;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.3) !important;
  border-top: 4px solid var(--brand-accent) !important;
}

/* Labels and text inside the login card — white for visibility */
.login-page .card label,
.login-page .card .form-label,
.login-page .card p,
.login-page .card span:not(.btn *) {
  color: #ffffff !important;
  text-shadow: 0 1px 3px rgba(0,0,0,0.4);
}

/* Input fields — semi-transparent */
.login-page .form-control,
.login-page input[type="text"],
.login-page input[type="password"],
.login-page select,
.login-page .form-select {
  background-color: rgba(255, 255, 255, 0) !important;
  color: #ffffff !important;
  border-radius: var(--brand-radius) !important;
}

.login-page .form-control::placeholder,
.login-page input::placeholder {
  color: rgba(255, 255, 255, 0.6) !important;
}

.login-page .form-control:focus,
.login-page input:focus {
  background-color: rgba(255, 255, 255, 0.3) !important;
  border-color: var(--brand-accent) !important;
  box-shadow: 0 0 0 3px rgba(207, 191, 17, 0.25) !important;
  color: #ffffff !important;
}

/* Select dropdown arrow fix */
.login-page .form-select option {
  background-color: var(--brand-primary) !important;
  color: #ffffff !important;
}

/* Remember me checkbox label */
.login-page .form-check-label {
  color: #ffffff !important;
}

/* Login to your account header */
.login-page .card-header,
.login-page .login-header {
  background: rgba(255, 255, 255, 0.08) !important;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15) !important;
  color: #ffffff !important;
}

.login-page .login-logo img,
.login-page img.logo,
.login-page .logo img {
  content: url('/pics/${LOGO_LARGE_FILENAME}');
  max-height: 100px;
  width: auto;
  display: block;
  margin: 0 auto 24px auto;
}

.login-page .btn-primary,
.login-page input[type="submit"],
.login-page button[type="submit"] {
  background-color: var(--brand-accent) !important;
  border-color: var(--brand-accent) !important;
  color: var(--brand-primary) !important;
  border-radius: var(--brand-radius) !important;
  font-weight: 700;
  letter-spacing: 0.5px;
  width: 100%;
  text-transform: uppercase;
  transition: all 0.2s ease-in-out;
}

.login-page .btn-primary:hover,
.login-page input[type="submit"]:hover {
  filter: brightness(1.1);
}
 
a.copyright {
  display: none;
}


CSSEOF
echo "✅ CSS file written to: $CUSTOM_CSS_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔒 Phase 4: Setting Permissions..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
chown -R $WEB_USER:$WEB_GROUP "$GLPI_DIR/plugins/$FINAL_PLUGIN_FOLDER"
chown -R $WEB_USER:$WEB_GROUP "$GLPI_DIR/public/pics"
chown     $WEB_USER:$WEB_GROUP "$CUSTOM_CSS_FILE"
find "$GLPI_DIR/plugins/$FINAL_PLUGIN_FOLDER" -type f -exec chmod 0644 {} \;
find "$GLPI_DIR/plugins/$FINAL_PLUGIN_FOLDER" -type d -exec chmod 0755 {} \;
chmod 0644 "$CUSTOM_CSS_FILE"
echo "✅ Permissions set."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Phase 5: Activating Plugin via GLPI Console..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$GLPI_DIR"
sudo -u $WEB_USER php bin/console glpi:plugin:install  "$FINAL_PLUGIN_FOLDER" --no-interaction || true
sudo -u $WEB_USER php bin/console glpi:plugin:activate "$FINAL_PLUGIN_FOLDER" --no-interaction || true
echo "✅ Plugin activated."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 Phase 6: Configuring plugin via PHP..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PLUGIN_DOC_DIR=""
for candidate in \
    "/var/lib/glpi/_plugins/mod" \
    "/var/www/html/glpi/files/_plugins/mod" \
    "/usr/share/glpi/files/_plugins/mod"; do
  if [ -d "$candidate" ]; then
    PLUGIN_DOC_DIR="$candidate"
    break
  fi
done
if [ -z "$PLUGIN_DOC_DIR" ]; then
  PLUGIN_DOC_DIR="/var/lib/glpi/_plugins/mod"
fi

PLUGIN_IMAGES_DIR="$PLUGIN_DOC_DIR/images"
mkdir -p "$PLUGIN_IMAGES_DIR" "$PLUGIN_DOC_DIR/backups"
echo "   Plugin doc dir : $PLUGIN_DOC_DIR"

cp "$GLPI_DIR/public/pics/$BG_FILENAME"           "$PLUGIN_IMAGES_DIR/background.jpg"
cp "$GLPI_DIR/public/pics/$LOGO_SMALL_FILENAME"   "$PLUGIN_IMAGES_DIR/logo-G-100.png"
cp "$GLPI_DIR/public/pics/$LOGO_MEDIUM_FILENAME"  "$PLUGIN_IMAGES_DIR/logo-GLPI-100.png"
cp "$GLPI_DIR/public/pics/$LOGO_LARGE_FILENAME"   "$PLUGIN_IMAGES_DIR/logo-GLPI-250.png"
echo "✅ Images copied to plugin current dir"

PHP_SCRIPT=$(mktemp /tmp/.glpi_apply.XXXXXX.php)
cat > "$PHP_SCRIPT" << 'ENDPHP'
<?php
define('GLPI_ROOT', '/var/www/html/glpi');
chdir(GLPI_ROOT);
require_once GLPI_ROOT . '/vendor/autoload.php';
require_once GLPI_ROOT . '/plugins/mod/vendor/autoload.php';
if (!defined('GLPI_PLUGIN_DOC_DIR')) {
    foreach (['/var/lib/glpi/_plugins', '/var/www/html/glpi/files/_plugins'] as $c) {
        if (is_dir($c)) { define('GLPI_PLUGIN_DOC_DIR', $c); break; }
    }
    if (!defined('GLPI_PLUGIN_DOC_DIR')) define('GLPI_PLUGIN_DOC_DIR', '/var/lib/glpi/_plugins');
}
$bm = new GlpiPlugin\Mod\BrandManager();
$bm->applyResource('background');  echo "✅ Applied background\n";
$bm->applyResource('logo_s');      echo "✅ Applied logo_s\n";
$bm->applyResource('logo_m');      echo "✅ Applied logo_m\n";
$bm->applyResource('logo_l');      echo "✅ Applied logo_l\n";
$bm->applyResource('favicon');     echo "✅ Applied favicon\n";
$bm->changeTitle($argv[1]);        echo "✅ Title set to: " . $argv[1] . "\n";
$bm->applyLoginPageModifier();     echo "✅ Login page modifier enabled\n";
ENDPHP

sudo -u $WEB_USER php "$PHP_SCRIPT" "$ORG_TITLE" 2>&1 || {
  echo "⚠️  PHP apply failed — falling back to direct file copy..."
  LOGOS_DIR="$GLPI_DIR/public/pics/logos"
  mkdir -p "$LOGOS_DIR"
  for variant in black grey white; do
    cp "$GLPI_DIR/public/pics/$LOGO_SMALL_FILENAME"  "$LOGOS_DIR/logo-G-100-${variant}.png"
    cp "$GLPI_DIR/public/pics/$LOGO_MEDIUM_FILENAME" "$LOGOS_DIR/logo-GLPI-100-${variant}.png"
    cp "$GLPI_DIR/public/pics/$LOGO_LARGE_FILENAME"  "$LOGOS_DIR/logo-GLPI-250-${variant}.png"
  done
  chown -R $WEB_USER:$WEB_GROUP "$LOGOS_DIR"
  echo "✅ Fallback: logos copied directly to active paths"
}
rm -f "$PHP_SCRIPT"

cat > "$PLUGIN_DOC_DIR/modifiers.ini" << INIEOF
title=${ORG_TITLE}
login=1
INIEOF

chown -R $WEB_USER:$WEB_GROUP "$PLUGIN_DOC_DIR"
echo "✅ Plugin configuration complete."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 Phase 7: Enabling native CSS customization in GLPI..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MYCNF=$(mktemp /tmp/.myconf.XXXXXX)
chmod 600 "$MYCNF"
printf '[client]\nhost=localhost\nuser=%s\npassword=%s\n' "$DB_USER" "$DB_PASS" > "$MYCNF"

mysql --defaults-extra-file="$MYCNF" "$DB_NAME" \
  -e "SELECT id, name, enable_custom_css FROM glpi_entities WHERE id=0;" 2>&1

PY_SCRIPT=$(mktemp /tmp/.glpi_py.XXXXXX.py)
SQL_FILE=$(mktemp /tmp/.glpi_css.XXXXXX.sql)
chmod 600 "$PY_SCRIPT" "$SQL_FILE"

cat > "$PY_SCRIPT" << 'ENDPY'
import sys
with open(sys.argv[1]) as f:
    css = f.read()
css = css.replace("'", "''")
sql = "UPDATE glpi_entities SET enable_custom_css = 1, custom_css_code = '" + css + "' WHERE id = 0;"
with open(sys.argv[2], 'w') as f:
    f.write(sql)
ENDPY

python3 "$PY_SCRIPT" "$CUSTOM_CSS_FILE" "$SQL_FILE"
mysql --defaults-extra-file="$MYCNF" "$DB_NAME" < "$SQL_FILE"
CSS_EXIT=$?
rm -f "$MYCNF" "$SQL_FILE" "$PY_SCRIPT"

if [ $CSS_EXIT -ne 0 ]; then
  echo "❌ Failed to inject CSS into glpi_entities (exit $CSS_EXIT)"
else
  echo "✅ CSS customization enabled on Root Entity (id=0)"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Phase 8 — Override "GLPI internal database" label
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Phase 8: Renaming login source label..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for LOCALE_FILE in \
  "$GLPI_DIR/locales/en_GB.php" \
  "$GLPI_DIR/locales/en_US.php" \
  "$GLPI_DIR/locales/en_GB.po" \
  "$GLPI_DIR/locales/en_US.po"; do
  if [ -f "$LOCALE_FILE" ]; then
    sed -i "s/GLPI internal database/${AUTH_LABEL}/g" "$LOCALE_FILE"
    echo "✅ Patched: $LOCALE_FILE"
  fi
done

for PO_FILE in \
  "$GLPI_DIR/locales/en_GB.po" \
  "$GLPI_DIR/locales/en_US.po"; do
  if [ -f "$PO_FILE" ] && command -v msgfmt &>/dev/null; then
    MO_FILE="${PO_FILE%.po}.mo"
    msgfmt -o "$MO_FILE" "$PO_FILE" 2>/dev/null && echo "✅ Recompiled: $MO_FILE"
  fi
done

AUTH_PHP="$GLPI_DIR/src/Auth.php"
if [ -f "$AUTH_PHP" ]; then
  sed -i "s/GLPI internal database/${AUTH_LABEL}/g" "$AUTH_PHP"
  echo "✅ Patched: $AUTH_PHP"
fi

for PHP_FILE in \
  "$GLPI_DIR/src/AuthDB.php" \
  "$GLPI_DIR/inc/auth.class.php"; do
  if [ -f "$PHP_FILE" ]; then
    sed -i "s/GLPI internal database/${AUTH_LABEL}/g" "$PHP_FILE"
    echo "✅ Patched: $PHP_FILE"
  fi
done

echo "✅ Login source label updated to: ${AUTH_LABEL}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Phase 9: Clearing GLPI Cache..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$GLPI_DIR"
sudo -u $WEB_USER php bin/console glpi:cache:clear --no-interaction

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL DONE!"
echo ""
echo "   GLPI URL  : http://$(hostname -I | awk '{print $1}')/"
echo "   Username  : glpi"
echo "   Password  : glpi   ← CHANGE THIS IMMEDIATELY"
echo ""
echo "   DB Name   : $DB_NAME"
echo "   DB User   : $DB_USER"
echo "   Org Title : $ORG_TITLE"
echo "   Auth Label: $AUTH_LABEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"