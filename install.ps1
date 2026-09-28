# ============================================================
# ⚡ ProfilIA — Installateur Windows (PowerShell)
# Usage : Right-click > "Exécuter avec PowerShell"
#         ou : powershell -ExecutionPolicy Bypass -File install.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ── Couleurs ─────────────────────────────────────────────
function ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function info($msg) { Write-Host "  → $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function err($msg)  { Write-Host "  ✗ ERREUR: $msg" -ForegroundColor Red; exit 1 }
function step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Magenta }
function ask($msg)  { Write-Host "  ? $msg" -ForegroundColor Cyan -NoNewline; return (Read-Host " ") }

# ── Bannière ──────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ███████╗██████╗  ██████╗ ███████╗██╗██╗     ██╗ █████╗ " -ForegroundColor Magenta
Write-Host "  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██║██╔══██╗" -ForegroundColor Magenta
Write-Host "  ███████║██████╔╝██║   ██║█████╗  ██║██║     ██║███████║" -ForegroundColor Magenta
Write-Host "  ██╔══██╗██╔══██╗██║   ██║██╔══╝  ██║██║     ██║██╔══██║" -ForegroundColor Magenta
Write-Host "  ██║  ██║██║  ██║╚██████╔╝██║     ██║███████╗██║██║  ██║" -ForegroundColor Magenta
Write-Host "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚═╝╚═╝  ╚═╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  L'IA qui s'adapte a votre profil professionnel" -ForegroundColor DarkGray
Write-Host "  Installateur v2.0 - Windows" -ForegroundColor DarkGray
Write-Host ""

# ══════════════════════════════════════════════════════════
#  ÉTAPE 0 — Vérifications
# ══════════════════════════════════════════════════════════
step "0/5" "Verification des prerequis"

try { $nodeVer = node --version } catch { err "Node.js non trouve. Installez-le depuis https://nodejs.org" }
$nodeNum = [int]($nodeVer -replace 'v(\d+)\..*', '$1')
if ($nodeNum -lt 18) { err "Node.js 18+ requis (vous avez $nodeVer)" }
ok "Node.js $nodeVer"

try { $npmVer = npm --version; ok "npm $npmVer" } catch { err "npm non trouve" }

# ══════════════════════════════════════════════════════════
#  ÉTAPE 1 — Dossier
# ══════════════════════════════════════════════════════════
step "1/5" "Dossier d'installation"

$projectName = ask "Nom du dossier projet [profilia]"
if ([string]::IsNullOrWhiteSpace($projectName)) { $projectName = "profilia" }

if (Test-Path $projectName) {
  $overwrite = ask "Le dossier '$projectName' existe deja. Ecraser ? (o/N)"
  if ($overwrite -ne "o" -and $overwrite -ne "O") { err "Installation annulee." }
  Remove-Item -Recurse -Force $projectName
}

New-Item -ItemType Directory -Path $projectName | Out-Null
ok "Dossier '$projectName' cree"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 2 — Clés API
# ══════════════════════════════════════════════════════════
step "2/5" "Configuration des cles API"

Write-Host ""
Write-Host "  Vous aurez besoin de :" -ForegroundColor DarkGray
Write-Host "    • Supabase  → https://supabase.com (gratuit)" -ForegroundColor DarkGray
Write-Host "    • Gemini → https://aistudio.google.com/app/apikey (quota selon le compte)" -ForegroundColor DarkGray
Write-Host ""

$supabaseUrl = ask "URL Supabase (ex: https://xxxx.supabase.co)"
if ([string]::IsNullOrWhiteSpace($supabaseUrl)) { err "URL Supabase requise" }

$supabaseKey = ask "Cle Supabase anon public"
if ([string]::IsNullOrWhiteSpace($supabaseKey)) { err "Cle Supabase requise" }

$geminiKey = ask "Cle API Gemini"
if ([string]::IsNullOrWhiteSpace($geminiKey)) { err "Cle Gemini requise" }

ok "Cles API configurees"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 3 — Génération des fichiers
# ══════════════════════════════════════════════════════════
step "3/5" "Generation du projet"

Set-Location $projectName

# ── .env.local ────────────────────────────────────────────
@"
NEXT_PUBLIC_SUPABASE_URL=$supabaseUrl
NEXT_PUBLIC_SUPABASE_ANON_KEY=$supabaseKey
GEMINI_API_KEY=$geminiKey
GEMINI_MODEL=gemini-2.5-flash
"@ | Set-Content ".env.local" -Encoding UTF8

# ── package.json ──────────────────────────────────────────
@'
{
  "name": "profilia",
  "version": "2.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.0",
    "react": "^18",
    "react-dom": "^18",
    "@supabase/supabase-js": "^2.39.0",
    "@supabase/ssr": "^0.1.0",
    "@google/genai": "^2.24.0"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18"
  }
}
'@ | Set-Content "package.json" -Encoding UTF8

# ── Fichiers de config ─────────────────────────────────────
@'
/** @type {import('next').NextConfig} */
const nextConfig = {}
module.exports = nextConfig
'@ | Set-Content "next.config.js" -Encoding UTF8

@'
node_modules/
.next/
.env.local
*.tsbuildinfo
'@ | Set-Content ".gitignore" -Encoding UTF8

# ── Créer la structure ─────────────────────────────────────
$dirs = @(
  "app/auth", "app/chat", "app/settings",
  "app/api/chat", "app/api/conversations",
  "components", "lib", "public"
)
foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

info "Structure de dossiers creee"

# ── Copier les fichiers source depuis l'archive ────────────
# (Dans le setup complet, les fichiers .tsx/.ts/.css sont embarqués ici)
# Pour cette version, ils sont dans le dossier /src/ de l'archive

$srcDir = Join-Path $PSScriptRoot "src"
if (Test-Path $srcDir) {
  Copy-Item -Path "$srcDir/*" -Destination "." -Recurse -Force
  info "Fichiers source copies"
} else {
  warn "Dossier src/ non trouve - copiez les fichiers manuellement"
}

ok "Projet genere"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 4 — npm install
# ══════════════════════════════════════════════════════════
step "4/5" "Installation des dependances"

info "npm install en cours..."
npm install --silent
ok "Dependances installees"

# ══════════════════════════════════════════════════════════
#  ÉTAPE 5 — Déploiement
# ══════════════════════════════════════════════════════════
step "5/5" "Deploiement"

Write-Host ""
Write-Host "  Comment souhaitez-vous deployer ?" -ForegroundColor White
Write-Host ""
Write-Host "  1) Lancer en local (developpement)" -ForegroundColor Cyan
Write-Host "  2) Deployer sur Vercel (production)" -ForegroundColor Cyan
Write-Host "  3) Je le ferai moi-meme plus tard" -ForegroundColor Cyan
Write-Host ""

$choice = ask "Votre choix [1/2/3]"

switch ($choice) {
  "1" {
    Write-Host ""
    ok "Demarrage du serveur..."
    Write-Host ""
    Write-Host "  ⚡ ProfilIA est pret !" -ForegroundColor Green
    Write-Host "  Ouvrez http://localhost:3000 dans votre navigateur" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  N'oubliez pas d'executer supabase-schema.sql dans Supabase !" -ForegroundColor Yellow
    Write-Host ""
    npm run dev
  }
  "2" {
    try { vercel --version | Out-Null } catch {
      info "Installation de Vercel CLI..."
      npm install -g vercel
    }
    vercel --prod
  }
  default {
    Write-Host ""
    info "Projet pret dans ./$projectName/"
  }
}

# ── Résumé ────────────────────────────────────────────────
Write-Host ""
Write-Host "  ══════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  ⚡ Installation terminee !" -ForegroundColor Green
Write-Host "  ══════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Projet : ./$projectName/" -ForegroundColor White
Write-Host ""
Write-Host "  Prochaines etapes :" -ForegroundColor White
Write-Host "  1. Executer supabase-schema.sql dans Supabase Dashboard" -ForegroundColor DarkGray
Write-Host "  2. cd $projectName && npm run dev" -ForegroundColor Cyan
Write-Host "  3. vercel --prod (pour la production)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Documentation → README.md" -ForegroundColor DarkGray
Write-Host ""
